import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/notification_service.dart';
import '../../../domain/valuation/asset_valuator.dart';
import '../../asset/presentation/asset_providers.dart';
import '../../exchange_rate/presentation/exchange_rate_providers.dart';

/// 同步范围：顶栏菜单的三种偏好。
enum SyncScope { all, ratesOnly, assetsOnly }

/// 全局「远端数据同步」状态，驱动顶部同步药丸。
///
/// 由 [GlobalRefresh] 统一维护；单功能页的局部刷新也建议通过 [GlobalRefresh]
/// 走统一出口，以维持顶部药丸与用户认知一致。
class SyncState {
  const SyncState({
    this.isSyncing = false,
    this.lastSyncAt,
    this.lastError,
  });

  final bool isSyncing;
  final DateTime? lastSyncAt;
  final String? lastError;

  SyncState copyWith({
    bool? isSyncing,
    DateTime? lastSyncAt,
    String? lastError,
    bool clearError = false,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

class SyncStatusNotifier extends Notifier<SyncState> {
  @override
  SyncState build() => const SyncState();

  void markStart() => state = state.copyWith(isSyncing: true, clearError: true);

  void markSuccess(DateTime at) =>
      state = state.copyWith(isSyncing: false, lastSyncAt: at, clearError: true);

  void markError(String message) =>
      state = state.copyWith(isSyncing: false, lastError: message);
}

final syncStatusProvider =
    NotifierProvider<SyncStatusNotifier, SyncState>(SyncStatusNotifier.new);

/// 全局同步协调器：统一行情 + 汇率 + 预警扫描 + 系统通知。
///
/// 通过 [scope] 过滤只刷某一侧；[rateMode] 决定 Frankfurter 拉取粒度
/// （增量只取最新一点，全量补 8 日序列）。
class GlobalRefresh {
  GlobalRefresh(this._ref);
  final Ref _ref;

  Future<void> run({
    SyncScope scope = SyncScope.all,
    SyncMode rateMode = SyncMode.full,
    SyncWindow? window,
  }) async {
    final notifier = _ref.read(syncStatusProvider.notifier);
    if (_ref.read(syncStatusProvider).isSyncing) return;
    notifier.markStart();
    final errors = <String>[];

    if (scope != SyncScope.assetsOnly) {
      try {
        final fxResult =
            await _ref.read(refreshWatchedRatesUseCaseProvider).call(
                  mode: rateMode,
                  window: window,
                );
        await fxResult.when(
          ok: (_) async {
            final checkR =
                await _ref.read(checkRateAlertsUseCaseProvider).call();
            final fired = checkR.valueOrNull ?? const [];
            for (final rec in fired) {
              final label = switch (rec.kind.code) {
                'high' =>
                  '触及上沿 ${rec.threshold?.toStringAsFixed(4) ?? ''}',
                'low' =>
                  '跌破下沿 ${rec.threshold?.toStringAsFixed(4) ?? ''}',
                'change' =>
                  '波动 ${rec.changePct == null ? '' : rec.changePct!.toStringAsFixed(2)}%',
                _ => '阈值触发',
              };
              await NotificationService.instance.showRateAlert(
                sourceKey: 'RATE_ALERT:${rec.pairKey}:${rec.kind.code}:'
                    '${DateTime.now().toUtc().toIso8601String().substring(0, 10)}',
                pairKey: rec.pairKey,
                summary: '$label · 当前 ${rec.rate.toStringAsFixed(4)}',
              );
            }
          },
          err: (e) async => errors.add('汇率：${e.message}'),
        );
      } catch (e) {
        errors.add('汇率：$e');
      }
    }

    if (scope != SyncScope.ratesOnly) {
      try {
        final priceResult =
            await _ref.read(refreshAssetPriceUseCaseProvider).refreshAll(
                  window: window,
                );
        priceResult.when(
          ok: (_) {},
          err: (e) => errors.add('行情：${e.message}'),
        );
      } catch (e) {
        errors.add('行情：$e');
      }
    }

    if (errors.isEmpty) {
      notifier.markSuccess(DateTime.now());
    } else {
      notifier.markError(errors.join('；'));
    }
  }
}

final globalRefreshProvider = Provider<GlobalRefresh>((ref) {
  return GlobalRefresh(ref);
});
