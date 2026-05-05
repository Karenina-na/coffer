import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';

import '../../../core/money/money.dart';
import '../../../domain/entities/asset.dart';
import '../../../domain/entities/asset_enums.dart';
import '../database.dart';

/// Asset 领域模型与 Drift 行之间的双向映射。
class AssetMapper {
  const AssetMapper();

  Asset toDomain(AssetRow row) => Asset(
        id: row.id,
        accountId: row.accountId,
        assetType: AssetType.fromCode(row.assetType),
        assetCode: row.assetCode,
        quantity: Money.parseOrNull(row.quantity) ?? Decimal.zero,
        costPrice: Money.parseOrNull(row.costPrice),
        currentPrice: Money.parseOrNull(row.currentPrice),
        currency: row.currency,
        marketValue: Money.parseOrNull(row.marketValue),
        valuationTime: row.valuationTime?.toUtc(),
        status: AssetStatus.fromCode(row.status),
        extInfo: row.extInfo == null
            ? null
            : (jsonDecode(row.extInfo!) as Map<String, dynamic>),
        createdAt: row.createdAt.toUtc(),
        updatedAt: row.updatedAt.toUtc(),
        isDeleted: row.isDeleted,
      );

  AssetsCompanion toInsert(Asset a) => AssetsCompanion.insert(
        id: a.id,
        accountId: a.accountId,
        assetType: a.assetType.code,
        assetCode: _val(a.assetCode),
        quantity: a.quantity.toString(),
        costPrice: _val(Money.stringifyOrNull(a.costPrice)),
        currentPrice: _val(Money.stringifyOrNull(a.currentPrice)),
        currency: a.currency,
        marketValue: _val(Money.stringifyOrNull(a.marketValue)),
        valuationTime: _val(a.valuationTime),
        status: a.status.code,
        extInfo: _val(a.extInfo == null ? null : jsonEncode(a.extInfo)),
        createdAt: a.createdAt,
        updatedAt: a.updatedAt,
        isDeleted: Value(a.isDeleted),
      );
}

Value<T> _val<T>(T? v) => v == null ? const Value.absent() : Value(v);
