import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'asset_enums.dart';

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
}
