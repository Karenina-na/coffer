import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'exchange_rate_enums.dart';

part 'exchange_rate.freezed.dart';

/// 汇率快照，字段对齐 doc/data-definitions.md §6。
@freezed
abstract class ExchangeRate with _$ExchangeRate {
  const factory ExchangeRate({
    required String id,
    required String pairKey,
    required String baseCurrency,
    required String quoteCurrency,
    required Decimal rate,
    required DateTime asOfTime,
    required DateTime updatedAt,
    required String source,
    required SnapshotType snapshotType,
    String? rawPayload,
  }) = _ExchangeRate;
}
