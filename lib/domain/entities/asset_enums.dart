import '../../core/errors.dart';

/// 资产类型，与 doc/data-definitions.md §1 对齐。
enum AssetType {
  stock('STOCK'),
  equity('EQUITY'),
  fund('FUND'),
  bond('BOND'),
  cd('CD'),
  option('OPTION'),
  future('FUTURE'),
  warrant('WARRANT'),
  policy('POLICY'),
  crypto('CRYPTO'),
  perpetual('PERPETUAL'),
  contract('CONTRACT'),
  preciousMetal('PRECIOUS_METAL'),
  fxAsset('FX_ASSET');

  const AssetType(this.code);
  final String code;

  static AssetType fromCode(String code) =>
      AssetType.values.firstWhere(
        (e) => e.code == code,
        orElse: () => throw StorageError('unknown asset type: $code'),
      );
}

/// 资产生命周期状态。
enum AssetStatus {
  holding('HOLDING'),
  frozen('FROZEN'),
  redeemed('REDEEMED'),
  closed('CLOSED');

  const AssetStatus(this.code);
  final String code;

  static AssetStatus fromCode(String code) =>
      AssetStatus.values.firstWhere(
        (e) => e.code == code,
        orElse: () => throw StorageError('unknown asset status: $code'),
      );
}
