import '../../core/errors.dart';
import '../../core/result.dart';
import '../entities/asset.dart';
import '../providers/asset_price_provider.dart';

// 方便同一文件的消费者（如 dashboard_providers）直接拿到报价类型。
export '../providers/asset_price_provider.dart'
    show AssetQuote, AssetPricePoint, AssetPriceSeries;

/// 拉取同步模式。
enum SyncMode {
  /// 仅拉取最新快照（增量）。
  incremental,

  /// 拉取完整时间序列（全量）。
  full,
}

enum SyncWindow {
  days8('8日', 8),
  month1('1个月', 30),
  year1('1年', 365),
  years5('5年', 365 * 5);

  const SyncWindow(this.label, this.days);

  final String label;
  final int days;

  ({DateTime from, DateTime to}) rangeFrom(DateTime now) {
    final to = now.isUtc
        ? DateTime.utc(now.year, now.month, now.day)
        : DateTime(now.year, now.month, now.day);
    final from = to.subtract(Duration(days: days));
    return (from: from, to: to);
  }
}

/// 单一资产的估值策略。
///
/// 不同资产类别走不同策略：
/// - 股票 / 基金 / 加密 / 贵金属 / 期货 → 外部行情 API + 缓存
/// - 定存 / 债券 → 按本金 + 利率自行推算
/// - 保单 / 其他 → 以用户手动录入为准
///
/// 由 [AssetValuationRouter] 根据 [supports] 把请求分发给合适的实现。
abstract interface class AssetValuator {
  /// 当前策略是否适合给 [asset] 估值。
  bool supports(Asset asset);

  /// 取最新估值。结果的 `currency` 可能与 `asset.currency` 不同，
  /// 上层 (`ValuateAssetUseCase`) 负责做 FX 换算。
  ///
  /// [forceRefresh] 为 `true` 时跳过进程内缓存，直接请求远端，确保 API 数据为准。
  Future<Result<AssetQuote, AppError>> valueNow(
    Asset asset, {
    bool forceRefresh = false,
  });

  /// 取 [from, to] 区间内的估值序列，用于图表展示 / 历史补录。
  /// 若当前策略无法提供历史（例如保单手动录入），返回
  /// `Err(UnknownError('history not supported'))`。
  ///
  /// [forceRefresh] 为 `true` 时跳过进程内缓存，直接请求远端，确保 API 数据为准。
  Future<Result<AssetPriceSeries, AppError>> valueHistory(
    Asset asset, {
    required DateTime from,
    required DateTime to,
    bool forceRefresh = false,
  });
}
