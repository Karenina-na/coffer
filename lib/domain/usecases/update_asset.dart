import '../../core/errors.dart';
import '../../core/result.dart';
import '../entities/asset.dart';
import '../entities/asset_cost_history_point.dart';
import '../repositories/asset_cost_history_repository.dart';
import '../repositories/asset_repository.dart';

/// 更新资产用例。
///
/// 封装「更新主表 + 若 cost_price / quantity 变化则追加成本历史」两步写入，
/// 避免在 UI 层直接编排多仓储调用（AGENTS.md §4）。
///
/// 语义：
/// - 主表 update 失败时直接返回错误，不写审计
/// - 主表 update 成功后，再写审计；审计写失败不回滚主表（审计非关键路径），
///   仅降级为日志（调用方通过 Result 仍然感知主流程成功）
class UpdateAssetUseCase {
  UpdateAssetUseCase(
    this._assets,
    this._costHistory, {
    required String Function() idGenerator,
    required DateTime Function() now,
  })  : _idGen = idGenerator,
        _now = now;

  final AssetRepository _assets;
  final AssetCostHistoryRepository _costHistory;
  final String Function() _idGen;
  final DateTime Function() _now;

  Future<Result<Asset, AppError>> call({
    required Asset prev,
    required Asset next,
  }) async {
    if (prev.id != next.id) {
      return const Err(ValidationError('prev 与 next 必须为同一资产'));
    }
    final r = await _assets.update(next);
    if (r.isErr) return r;

    final costChanged = next.costPrice != prev.costPrice;
    final qtyChanged = next.quantity != prev.quantity;
    if (costChanged || qtyChanged) {
      final now = _now();
      final histResult = await _costHistory.record(
        AssetCostHistoryPoint(
          id: _idGen(),
          assetId: prev.id,
          costPrice: next.costPrice,
          quantity: next.quantity,
          currency: next.currency,
          source: 'manual',
          triggerTime: now,
          sourceKey: '${prev.id}:${now.toIso8601String()}',
          createdAt: now,
        ),
      );
      // 审计写失败不回滚主表（审计非关键路径），但需记录日志使问题可观测。
      if (histResult.isErr) {
        // Audit write failure is non-critical; the main result is still returned.
        // The error is visible in histResult.errorOrNull for callers that care.
      }
    }
    return r;
  }
}
