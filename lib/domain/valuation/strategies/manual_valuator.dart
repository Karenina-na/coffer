import '../../../core/errors.dart';
import '../../../core/result.dart';
import '../../entities/asset.dart';
import '../asset_valuator.dart';

/// 手动录入估值策略。作为兜底方案：
/// - 保单 (POLICY) 等无外部行情的资产
/// - 其它策略都不支持时的最后一环
///
/// 直接读取 [Asset.currentPrice]（缺省回落 [Asset.costPrice]，再缺省按 0）。
/// 不提供历史序列。
class ManualValuator implements AssetValuator {
  ManualValuator({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  static const String source = 'manual';

  @override
  bool supports(Asset asset) => true; // 兜底：任何资产都可以

  @override
  Future<Result<AssetQuote, AppError>> valueNow(
    Asset asset, {
    bool forceRefresh = false,
  }) async {
    if (asset.currentPrice == null && asset.costPrice == null) {
      return const Err(ValidationError('资产未设置 currentPrice 或 costPrice，无法手动估值'));
    }
    final price = asset.currentPrice ?? asset.costPrice!;
    return Ok(
      AssetQuote(
        symbol: asset.assetCode ?? asset.id,
        price: price,
        currency: asset.currency,
        asOfTime: asset.valuationTime ?? _clock(),
        source: source,
      ),
    );
  }

  @override
  Future<Result<AssetPriceSeries, AppError>> valueHistory(
    Asset asset, {
    required DateTime from,
    required DateTime to,
    bool forceRefresh = false,
  }) async {
    return const Err(UnknownError('manual valuator has no history'));
  }

}
