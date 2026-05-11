import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/money/money.dart';
import '../../../domain/entities/channel.dart';
import '../../../domain/entities/channel_enums.dart';
import '../database.dart';

class ChannelMapper {
  const ChannelMapper();

  Channel toDomain(ChannelRow r) => Channel(
        id: r.id,
        name: r.name,
        transferProtocol: r.transferProtocol,
        isBuiltin: r.isBuiltin,
        feeRate: Money.parseOrNull(r.feeRate),
        fixedFee: Money.parseOrNull(r.fixedFee),
        sovereigntyRegionRule: r.sovereigntyRegionRule == null
            ? null
            : (jsonDecode(r.sovereigntyRegionRule!) as Map<String, dynamic>),
        limitCurrency: r.limitCurrency,
        dailyLimit: Money.parseOrNull(r.dailyLimit),
        singleLimit: Money.parseOrNull(r.singleLimit),
        status: ChannelStatus.fromCode(r.status),
        effectiveFrom: r.effectiveFrom,
        effectiveTo: r.effectiveTo,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );

  ChannelsCompanion toInsert(Channel c) => ChannelsCompanion.insert(
        id: c.id,
        name: c.name,
        transferProtocol: c.transferProtocol,
        isBuiltin: Value(c.isBuiltin),
        feeRate: _val(Money.stringifyOrNull(c.feeRate)),
        fixedFee: _val(Money.stringifyOrNull(c.fixedFee)),
        sovereigntyRegionRule: _val(
          c.sovereigntyRegionRule == null
              ? null
              : jsonEncode(c.sovereigntyRegionRule),
        ),
        limitCurrency: _val(c.limitCurrency),
        dailyLimit: _val(Money.stringifyOrNull(c.dailyLimit)),
        singleLimit: _val(Money.stringifyOrNull(c.singleLimit)),
        status: c.status.code,
        effectiveFrom: _val(c.effectiveFrom),
        effectiveTo: _val(c.effectiveTo),
        createdAt: c.createdAt,
        updatedAt: c.updatedAt,
      );
}

Value<T> _val<T>(T? v) => v == null ? const Value.absent() : Value(v);
