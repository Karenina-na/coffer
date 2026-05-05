import 'package:drift/drift.dart';

import '../../../core/money/money.dart';
import '../../../domain/entities/card.dart';
import '../../../domain/entities/card_enums.dart';
import '../database.dart';

/// Card 领域模型与 Drift 行之间的双向映射。
///
/// 注意：不负责加解密。ciphertext 列直接透传。
class CardMapper {
  const CardMapper();

  BankCard toDomain(CardRow row) => BankCard(
        id: row.id,
        accountId: row.accountId,
        cardOrganization: row.cardOrganization,
        cardNoMasked: row.cardNoMasked,
        cardNoCiphertext: row.cardNoCiphertext,
        cardType: CardType.fromCode(row.cardType),
        expireMonth: row.expireMonth,
        expireYear: row.expireYear,
        cvvCiphertext: row.cvvCiphertext,
        issuerName: row.issuerName,
        currency: row.currency,
        supportsAllCurrencies: row.supportsAllCurrencies,
        supportedCurrencies: _csvToList(row.supportedCurrencies),
        creditLimit: Money.parseOrNull(row.creditLimit),
        availableCredit: Money.parseOrNull(row.availableCredit),
        billingCycleDay: row.billingCycleDay,
        paymentDueDay: row.paymentDueDay,
        billingAddress: row.billingAddress,
        isVirtual: row.isVirtual,
        status: CardStatus.fromCode(row.status),
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  CardsCompanion toInsert(BankCard c) => CardsCompanion.insert(
        id: c.id,
        accountId: c.accountId,
        cardOrganization: c.cardOrganization,
        cardNoMasked: c.cardNoMasked,
        cardNoCiphertext: _val(c.cardNoCiphertext),
        cardType: c.cardType.code,
        expireMonth: c.expireMonth,
        expireYear: c.expireYear,
        cvvCiphertext: _val(c.cvvCiphertext),
        issuerName: c.issuerName,
        currency: _val(c.currency),
        supportsAllCurrencies: Value(c.supportsAllCurrencies),
        supportedCurrencies: _val(_listToCsv(c.supportedCurrencies)),
        creditLimit: _val(Money.stringifyOrNull(c.creditLimit)),
        availableCredit: _val(Money.stringifyOrNull(c.availableCredit)),
        billingCycleDay: _val(c.billingCycleDay),
        paymentDueDay: _val(c.paymentDueDay),
        billingAddress: _val(c.billingAddress),
        isVirtual: Value(c.isVirtual),
        status: c.status.code,
        createdAt: c.createdAt,
        updatedAt: c.updatedAt,
      );

  /// 用于 `update`：以 `Value()` 显式写入所有字段（含 null），
  /// 使 `replace` 能把未填的列重置为 NULL。
  CardsCompanion toUpdate(BankCard c) => CardsCompanion(
        id: Value(c.id),
        accountId: Value(c.accountId),
        cardOrganization: Value(c.cardOrganization),
        cardNoMasked: Value(c.cardNoMasked),
        cardNoCiphertext: Value(c.cardNoCiphertext),
        cardType: Value(c.cardType.code),
        expireMonth: Value(c.expireMonth),
        expireYear: Value(c.expireYear),
        cvvCiphertext: Value(c.cvvCiphertext),
        issuerName: Value(c.issuerName),
        currency: Value(c.currency),
        supportsAllCurrencies: Value(c.supportsAllCurrencies),
        supportedCurrencies: Value(_listToCsv(c.supportedCurrencies)),
        creditLimit: Value(Money.stringifyOrNull(c.creditLimit)),
        availableCredit: Value(Money.stringifyOrNull(c.availableCredit)),
        billingCycleDay: Value(c.billingCycleDay),
        paymentDueDay: Value(c.paymentDueDay),
        billingAddress: Value(c.billingAddress),
        isVirtual: Value(c.isVirtual),
        status: Value(c.status.code),
        createdAt: Value(c.createdAt),
        updatedAt: Value(c.updatedAt),
      );
}

Value<T> _val<T>(T? v) => v == null ? const Value.absent() : Value(v);

List<String> _csvToList(String? csv) {
  if (csv == null || csv.isEmpty) return const <String>[];
  return csv
      .split(',')
      .map((s) => s.trim().toUpperCase())
      .where((s) => s.isNotEmpty)
      .toList(growable: false);
}

String? _listToCsv(List<String> list) {
  if (list.isEmpty) return null;
  final seen = <String>{};
  final cleaned = <String>[];
  for (final raw in list) {
    final s = raw.trim().toUpperCase();
    if (s.isEmpty) continue;
    if (seen.add(s)) cleaned.add(s);
  }
  return cleaned.isEmpty ? null : cleaned.join(',');
}
