import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';

import '../../../domain/entities/asset_price_history_point.dart';
import '../database.dart';

class AssetPriceHistoryMapper {
  const AssetPriceHistoryMapper();

  AssetPriceHistoryPoint toDomain(AssetPriceHistoryRow r) => AssetPriceHistoryPoint(
        id: r.id,
        assetId: r.assetId,
        price: Decimal.tryParse(r.price) ?? Decimal.zero,
        marketValue: r.marketValue == null
            ? null
            : Decimal.tryParse(r.marketValue!),
        currency: r.currency,
        source: r.source,
        batchId: r.batchId,
        triggerTime: r.triggerTime,
        sourceKey: r.sourceKey,
        rawPayload: r.rawPayload,
        createdAt: r.createdAt,
      );

  AssetPriceHistoryCompanion toInsert(AssetPriceHistoryPoint p) =>
      AssetPriceHistoryCompanion.insert(
        id: p.id,
        assetId: p.assetId,
        price: p.price.toString(),
        marketValue: _val(p.marketValue?.toString()),
        currency: p.currency,
        source: p.source,
        batchId: _val(p.batchId),
        triggerTime: p.triggerTime,
        sourceKey: _val(p.sourceKey),
        rawPayload: _val(p.rawPayload),
        createdAt: p.createdAt,
      );
}

Value<T> _val<T>(T? v) => v == null ? const Value.absent() : Value(v);
