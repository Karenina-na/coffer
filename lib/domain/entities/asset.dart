import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'asset_enums.dart';
import 'asset_type_info.dart';

part 'asset.freezed.dart';

/// 资产领域模型。
///
/// 金额类字段统一使用 [Decimal]，禁止在领域层使用 double。
/// 字段对齐 doc/data-definitions.md §3。
@freezed
abstract class Asset with _$Asset {
  const factory Asset({
    required String id,
    required String accountId,
    required AssetType assetType,
    String? assetCode,
    required Decimal quantity,
    Decimal? costPrice,
    Decimal? currentPrice,
    required String currency,
    Decimal? marketValue,
    DateTime? valuationTime,
    required AssetStatus status,
    Map<String, dynamic>? extInfo,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(false) bool isDeleted,
  }) = _Asset;

  const Asset._();

  /// 类型安全的扩展信息，按 [assetType] 解析 [extInfo]。
  AssetTypeInfo get typeInfo => AssetTypeInfo.fromJson(extInfo, assetType);

  /// 返回更新了 [extInfo] 的副本。
  Asset copyWithTypeInfo(AssetTypeInfo info) =>
      copyWith(extInfo: info.toJson());
}
