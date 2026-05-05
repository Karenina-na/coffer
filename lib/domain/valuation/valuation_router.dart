import '../../core/errors.dart';
import '../../core/result.dart';
import '../entities/asset.dart';
import 'asset_valuator.dart';

/// 组合多个 [AssetValuator]，按注册顺序找第一个 `supports(asset)` 的策略。
///
/// 注册顺序决定优先级：特化策略（固收 / 手动）应靠前，
/// 市场行情作为默认回落策略靠后。
class AssetValuationRouter implements AssetValuator {
  AssetValuationRouter(List<AssetValuator> valuators)
      : assert(valuators.isNotEmpty, 'at least one valuator required'),
        _valuators = List.unmodifiable(valuators);

  final List<AssetValuator> _valuators;

  AssetValuator? _pick(Asset asset) {
    for (final v in _valuators) {
      if (v.supports(asset)) return v;
    }
    return null;
  }

  @override
  bool supports(Asset asset) => _pick(asset) != null;

  @override
  Future<Result<AssetQuote, AppError>> valueNow(
    Asset asset, {
    bool forceRefresh = false,
  }) async {
    final v = _pick(asset);
    if (v == null) {
      return Err(
        NotFoundError('no valuator for ${asset.assetType.code} (${asset.id})'),
      );
    }
    return v.valueNow(asset, forceRefresh: forceRefresh);
  }

  @override
  Future<Result<AssetPriceSeries, AppError>> valueHistory(
    Asset asset, {
    required DateTime from,
    required DateTime to,
    bool forceRefresh = false,
  }) async {
    final v = _pick(asset);
    if (v == null) {
      return Err(
        NotFoundError('no valuator for ${asset.assetType.code} (${asset.id})'),
      );
    }
    return v.valueHistory(asset, from: from, to: to, forceRefresh: forceRefresh);
  }
}
