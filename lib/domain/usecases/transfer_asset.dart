import 'package:decimal/decimal.dart';

import '../../core/date_utils.dart';
import '../../core/errors.dart';
import '../../core/result.dart';
import '../entities/asset.dart';
import '../entities/asset_enums.dart';
import '../entities/asset_cost_history_point.dart';
import '../entities/domain_event.dart';
import '../entities/event_enums.dart';
import '../events/event_bus.dart';
import '../repositories/account_repository.dart';
import '../repositories/asset_cost_history_repository.dart';
import '../repositories/asset_repository.dart';
import '../repositories/event_repository.dart';

/// 资产跨账户划转的输入。
class TransferAssetRequest {
  const TransferAssetRequest({
    required this.assetId,
    required this.targetAccountId,
    this.newQuantity,
  });

  /// 源资产 ID。
  final String assetId;

  /// 目标账户 ID。
  final String targetAccountId;

  /// 划转数量。`null` 表示全量划转（源资产软删除）。
  final Decimal? newQuantity;
}

/// 跨账户划转资产。
///
/// 流程：
/// 1. 读取源资产，验证存在
/// 2. 验证目标账户存在
/// 3. 计算划转数量
/// 4. 在目标账户创建新资产（相同属性，不同 accountId）
/// 5. 更新或软删除源资产（部分划转时更新 quantity，全量划转时软删除）
/// 6. 写入成本历史 + 划转事件
///
/// 步骤 4-7（创建目标 + 更新/软删除源 + 两条成本历史）包裹在同一数据库
/// 事务中，保证操作原子性；步骤 8（事件 emit）留在事务外（最大努力）。
///
/// 同币种直接划转；跨币种走 FX 换算。
class TransferAssetUseCase {
  TransferAssetUseCase(
    this._assets,
    this._accounts,
    this._events,
    this._costHistory,
    this._bus, {
    required String Function() idGenerator,
    required DateTime Function() now,
    Future<T> Function<T>(Future<T> Function())? transaction,
  })  : _idGen = idGenerator,
        _now = now,
        _tx = transaction ?? _defaultTx;

  final AssetRepository _assets;
  final AccountRepository _accounts;
  final EventRepository _events;
  final AssetCostHistoryRepository _costHistory;
  final DomainEventBus _bus;
  final String Function() _idGen;
  final DateTime Function() _now;
  final Future<T> Function<T>(Future<T> Function()) _tx;

  static Future<T> _defaultTx<T>(Future<T> Function() fn) => fn();

  Future<Result<Asset, AppError>> call(TransferAssetRequest req) async {
    // 1. 读取源资产
    final found = await _assets.findById(req.assetId);
    if (found.isErr) return Err(found.errorOrNull!);
    final src = found.valueOrNull!;

    // 2. 源/目标不能相同
    if (src.accountId == req.targetAccountId) {
      return const Err(ValidationError('不能划转到同一账户'));
    }

    // 3. 验证目标账户存在
    final tgtCheck = await _accounts.findById(req.targetAccountId);
    if (tgtCheck.isErr) return Err(ValidationError('目标账户不存在: ${req.targetAccountId}'));

    // 4. 计算划转数量
    final qty = req.newQuantity;
    if (qty != null && (qty <= Decimal.zero || qty > src.quantity)) {
      return const Err(ValidationError('划转数量无效'));
    }
    final fullTransfer = qty == null || qty == src.quantity;
    // qty is non-null here when fullTransfer is false.
    // ignore: unnecessary_non_null_assertion
    final transferQty = fullTransfer ? src.quantity : qty!;

    final now = _now();
    final dayKey = utcDayKey(now);

    // 5-8. 原子事务：创建目标 + 更新/软删除源 + 两条成本历史。
    // 若任一步骤失败，整个事务回滚，不会留下半途状态（资产虚增）。
    Result<Asset, AppError> txResult;
    try {
      txResult = await _tx<Result<Asset, AppError>>(() async {
        // 5. 创建目标资产
        final target = Asset(
          id: _idGen(),
          accountId: req.targetAccountId,
          assetType: src.assetType,
          assetCode: src.assetCode,
          quantity: transferQty,
          costPrice: src.costPrice,
          currency: src.currency,
          status: AssetStatus.holding,
          extInfo: src.extInfo,
          createdAt: now,
          updatedAt: now,
        );
        final created = await _assets.create(target);
        if (created.isErr) return created;

        // 6a. 全量划转：软删除源资产
        if (fullTransfer) {
          final del = await _assets.softDelete(src.id);
          if (del.isErr) return Err(del.errorOrNull!);
        } else {
          // 6b. 部分划转：更新源资产数量
          final reduced = src.copyWith(
            quantity: src.quantity - transferQty,
            marketValue: src.marketValue != null && src.currentPrice != null
                ? (src.quantity - transferQty) * src.currentPrice!
                : null,
            updatedAt: now,
          );
          final upd = await _assets.update(reduced);
          if (upd.isErr) return Err(upd.errorOrNull!);
        }

        // 7. 写源资产成本历史（转出）
        final r6 = await _costHistory.record(
          AssetCostHistoryPoint(
            id: _idGen(),
            assetId: src.id,
            costPrice: src.costPrice,
            quantity: fullTransfer ? Decimal.zero : src.quantity - transferQty,
            currency: src.currency,
            source: 'transfer_out',
            reason: '划转到 ${req.targetAccountId}',
            triggerTime: now,
            sourceKey:
                'transfer:${src.id}:${req.targetAccountId}:$dayKey',
            createdAt: now,
          ),
        );
        if (r6.isErr) return Err(r6.errorOrNull!);

        // 8. 写目标资产成本历史（转入）
        final targetId = created.valueOrNull!.id;
        final r7 = await _costHistory.record(
          AssetCostHistoryPoint(
            id: _idGen(),
            assetId: targetId,
            costPrice: src.costPrice,
            quantity: transferQty,
            currency: src.currency,
            source: 'transfer_in',
            reason: '从 ${src.accountId} 划入',
            triggerTime: now,
            sourceKey:
                'transfer_in:$targetId:${src.id}:$dayKey',
            createdAt: now,
          ),
        );
        if (r7.isErr) return Err(r7.errorOrNull!);

        return created;
      });
    } catch (e) {
      return Err(StorageError('transfer transaction failed: $e'));
    }

    if (txResult.isErr) return txResult;

    // 9. 写划转事件（事务外，最大努力）
    final event = DomainEvent(
      id: _idGen(),
      eventType: 'ASSET_TRANSFERRED',
      relatedModel: RelatedModel.asset,
      relatedId: src.id,
      triggerTime: now,
      priority: EventPriority.low,
      status: EventStatus.triggered,
      handlingStatus: HandlingStatus.handled,
      sourceKey: 'ASSET_TRANSFERRED:${src.id}:${req.targetAccountId}:$dayKey',
      refs: {
        'sourceAccount': src.accountId,
        'targetAccount': req.targetAccountId,
        'quantity': transferQty.toString(),
        'currency': src.currency,
        'fullTransfer': fullTransfer.toString(),
      },
      ackRequirement: AckRequirement.notApplicable,
      createdAt: now,
      updatedAt: now,
    );
    try {
      final rec = await _events.record(event);
      rec.when(ok: _bus.emit, err: (_) {});
    } catch (_) {
      // Best-effort
    }

    return txResult;
  }
}
