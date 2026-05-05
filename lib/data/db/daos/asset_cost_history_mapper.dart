import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';

import '../../../domain/entities/asset_cost_history_point.dart';
import '../database.dart';

class AssetCostHistoryMapper {
  const AssetCostHistoryMapper();

  AssetCostHistoryPoint toDomain(AssetCostHistoryRow r) => AssetCostHistoryPoint(
        id: r.id,
        assetId: r.assetId,
        costPrice: r.costPrice == null
            ? null
            : Decimal.tryParse(r.costPrice!),
        quantity: Decimal.tryParse(r.quantity) ?? Decimal.zero,
        currency: r.currency,
        source: r.source,
        reason: r.reason,
        triggerTime: r.triggerTime,
        sourceKey: r.sourceKey,
        createdAt: r.createdAt,
      );

  AssetCostHistoryCompanion toInsert(AssetCostHistoryPoint p) =>
      AssetCostHistoryCompanion.insert(
        id: p.id,
        assetId: p.assetId,
        costPrice: _val(p.costPrice?.toString()),
        quantity: p.quantity.toString(),
        currency: p.currency,
        source: p.source,
        reason: _val(p.reason),
        triggerTime: p.triggerTime,
        sourceKey: _val(p.sourceKey),
        createdAt: p.createdAt,
      );
}

Value<T> _val<T>(T? v) => v == null ? const Value.absent() : Value(v);
