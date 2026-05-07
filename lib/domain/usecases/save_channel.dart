import 'package:decimal/decimal.dart';

import '../../core/errors.dart';
import '../../core/result.dart';
import '../entities/channel.dart';
import '../repositories/channel_repository.dart';

class SaveChannelUseCase {
  const SaveChannelUseCase(this._repo);

  final ChannelRepository _repo;

  Future<Result<Channel, AppError>> call(Channel channel) {
    if (channel.name.trim().isEmpty) {
      return Future.value(const Err(ValidationError('通道名称不能为空')));
    }
    if (channel.transferProtocol.trim().isEmpty) {
      return Future.value(const Err(ValidationError('转账协议不能为空')));
    }
    if (channel.feeRate != null && channel.feeRate! < Decimal.zero) {
      return Future.value(const Err(ValidationError('费率不能为负数')));
    }
    if (channel.fixedFee != null && channel.fixedFee! < Decimal.zero) {
      return Future.value(const Err(ValidationError('固定费用不能为负数')));
    }
    if (channel.singleLimit != null && channel.singleLimit! <= Decimal.zero) {
      return Future.value(const Err(ValidationError('单笔限额必须大于 0')));
    }
    if (channel.dailyLimit != null && channel.dailyLimit! <= Decimal.zero) {
      return Future.value(const Err(ValidationError('日累计限额必须大于 0')));
    }
    if (channel.effectiveFrom != null &&
        channel.effectiveTo != null &&
        channel.effectiveFrom!.isAfter(channel.effectiveTo!)) {
      return Future.value(const Err(ValidationError('生效时间不能晚于失效时间')));
    }

    final normalized = channel.copyWith(
      name: channel.name.trim(),
      transferProtocol: channel.transferProtocol.trim(),
      limitCurrency: channel.limitCurrency?.trim().toUpperCase(),
      sovereigntyRegionRule: _normalizeRule(channel.sovereigntyRegionRule),
    );
    return _repo.upsert(normalized);
  }

  Map<String, dynamic>? _normalizeRule(Map<String, dynamic>? rule) {
    if (rule == null || rule.isEmpty) return null;
    List<String>? normalizeList(Object? raw) {
      if (raw is! List) return null;
      final out = raw
          .whereType<String>()
          .map((e) => e.trim().toUpperCase())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
      return out.isEmpty ? null : out;
    }

    final allowed = normalizeList(rule['allowedRegions']);
    final blocked = normalizeList(rule['blockedRegions']);
    final normalized = <String, dynamic>{};
    if (allowed != null) normalized['allowedRegions'] = allowed;
    if (blocked != null) normalized['blockedRegions'] = blocked;
    if (rule['requireSameRegion'] == true) {
      normalized['requireSameRegion'] = true;
    }
    return normalized.isEmpty ? null : normalized;
  }
}
