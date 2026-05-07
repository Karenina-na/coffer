import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';

import '../../core/money/money.dart';
import '../../core/errors.dart';
import '../../core/result.dart';
import '../../domain/entities/account_channel.dart';
import '../../domain/repositories/account_channel_repository.dart';
import '../db/daos/account_channel_dao.dart';
import '../db/database.dart';

class DriftAccountChannelRepository implements AccountChannelRepository {
  DriftAccountChannelRepository(
    this._dao, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final AccountChannelDao _dao;
  final DateTime Function() _now;

  AccountChannel _toDomain(AccountChannelRow r) => AccountChannel(
        accountId: r.accountId,
        channelId: r.channelId,
        feeRateOverride: Money.parseOrNull(r.feeRateOverride),
        fixedFeeOverride: Money.parseOrNull(r.fixedFeeOverride),
        feeCurrencyOverride: r.feeCurrencyOverride,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );

  @override
  Stream<List<AccountChannel>> watchAll() =>
      _dao.watchAll().map((rows) => rows.map(_toDomain).toList());

  @override
  Stream<List<AccountChannel>> watchByAccount(String accountId) => _dao
      .watchByAccount(accountId)
      .map((rows) => rows.map(_toDomain).toList());

  @override
  Future<Result<List<AccountChannel>, AppError>> listByChannel(
      String channelId) async {
    try {
      final rows = await _dao.listByChannel(channelId);
      return Ok(rows.map(_toDomain).toList());
    } catch (e) {
      return Err(StorageError('listByChannel failed: $e'));
    }
  }

  @override
  Future<Result<AccountChannel, AppError>> link({
    required String accountId,
    required String channelId,
  }) async {
    try {
      final now = _now();
      await _dao.upsert(AccountChannelsCompanion.insert(
        accountId: accountId,
        channelId: channelId,
        createdAt: now,
        updatedAt: const Value.absent(),
      ));
      return Ok(AccountChannel(
        accountId: accountId,
        channelId: channelId,
        feeRateOverride: null,
        fixedFeeOverride: null,
        feeCurrencyOverride: null,
        createdAt: now,
        updatedAt: null,
      ));
    } catch (e) {
      return Err(StorageError('link failed: $e'));
    }
  }

  @override
  Future<Result<AccountChannel, AppError>> saveConfig({
    required String accountId,
    required String channelId,
    Decimal? feeRateOverride,
    Decimal? fixedFeeOverride,
    String? feeCurrencyOverride,
  }) async {
    try {
      final now = _now();
      final existing = await _dao.findByKey(
        accountId: accountId,
        channelId: channelId,
      );
      final createdAt = existing?.createdAt ?? now;
      await _dao.upsert(AccountChannelsCompanion.insert(
        accountId: accountId,
        channelId: channelId,
        feeRateOverride: _val(Money.stringifyOrNull(feeRateOverride)),
        fixedFeeOverride: _val(Money.stringifyOrNull(fixedFeeOverride)),
        feeCurrencyOverride: _val(feeCurrencyOverride),
        createdAt: createdAt,
        updatedAt: Value(now),
      ));
      return Ok(AccountChannel(
        accountId: accountId,
        channelId: channelId,
        feeRateOverride: feeRateOverride,
        fixedFeeOverride: fixedFeeOverride,
        feeCurrencyOverride: feeCurrencyOverride,
        createdAt: createdAt,
        updatedAt: now,
      ));
    } catch (e) {
      return Err(StorageError('saveConfig failed: $e'));
    }
  }

  @override
  Future<Result<void, AppError>> unlink({
    required String accountId,
    required String channelId,
  }) async {
    try {
      await _dao.removeLink(accountId: accountId, channelId: channelId);
      return const Ok(null);
    } catch (e) {
      return Err(StorageError('unlink failed: $e'));
    }
  }

  @override
  Future<Result<void, AppError>> replaceForAccount({
    required String accountId,
    required List<String> channelIds,
  }) async {
    try {
      final now = _now();
      // 删除+重插必须原子完成，避免中途崩溃导致该账户通道数据丢失。
      await _dao.transaction(() async {
        await _dao.deleteAllForAccount(accountId);
        for (final cid in channelIds) {
          await _dao.upsert(AccountChannelsCompanion.insert(
            accountId: accountId,
            channelId: cid,
            createdAt: now,
            updatedAt: const Value.absent(),
          ));
        }
      });
      return const Ok(null);
    } catch (e) {
      return Err(StorageError('replaceForAccount failed: $e'));
    }
  }
}

Value<T> _val<T>(T? v) => v == null ? const Value.absent() : Value(v);
