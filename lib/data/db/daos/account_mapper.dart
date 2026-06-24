import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'dart:convert';

import '../../../core/money/money.dart';
import '../../../domain/entities/account.dart';
import '../../../domain/entities/account_enums.dart';
import '../database.dart';

/// Account 领域模型与 Drift 行之间的双向映射。
///
/// - JSON 字段在此处序列化/反序列化
/// - 枚举在此处按 code 转换
/// - 可空字段统一用 [Value] 包装；null → [Value.absent]，否则 [Value]。
class AccountMapper {
  const AccountMapper();

  Account toDomain(AccountRow row) => Account(
    id: row.id,
    accountNo: row.accountNo,
    accountType: AccountType.fromCode(row.accountType),
    sovereigntyRegion: row.sovereigntyRegion,
    institutionName: row.institutionName,
    status: AccountStatus.fromCode(row.status),
    openedAt: row.openedAt,
    extInfo: row.extInfo == null
        ? null
        : (jsonDecode(row.extInfo!) as Map<String, dynamic>),
    fxSpreadPercent: Decimal.parse(row.fxSpreadPercent.toString()),
    fxFixedFee: Money.parseOrNull(row.fxFixedFee),
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    isDeleted: row.isDeleted,
  );

  AccountsCompanion toInsert(Account a) => AccountsCompanion.insert(
    id: a.id,
    accountNo: _val(a.accountNo),
    accountType: a.accountType.code,
    sovereigntyRegion: a.sovereigntyRegion,
    institutionName: a.institutionName,
    status: a.status.code,
    openedAt: _val(a.openedAt),
    extInfo: _val(a.extInfo == null ? null : jsonEncode(a.extInfo)),
    fxSpreadPercent: Value(a.fxSpreadPercent.toDouble()),
    fxFixedFee: Value(Money.stringifyOrNull(a.fxFixedFee) ?? '0'),
    createdAt: a.createdAt,
    updatedAt: a.updatedAt,
    isDeleted: Value(a.isDeleted),
  );
}

Value<T> _val<T>(T? v) => v == null ? const Value.absent() : Value(v);
