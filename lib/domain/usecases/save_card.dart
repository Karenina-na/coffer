import 'package:decimal/decimal.dart';

import '../../core/errors.dart';
import '../../core/result.dart';
import '../entities/card.dart';
import '../entities/card_enums.dart';
import '../repositories/account_repository.dart';
import '../repositories/card_repository.dart';

class SaveCardUseCase {
  SaveCardUseCase(
    this._cards,
    this._accounts, {
    required String Function() idGenerator,
    required DateTime Function() now,
  })  : _idGen = idGenerator,
        _now = now;

  final CardRepository _cards;
  final AccountRepository _accounts;
  final String Function() _idGen;
  final DateTime Function() _now;

  Future<Result<BankCard, AppError>> create({
    required String accountId,
    required String cardOrganization,
    required String plainCardNo,
    required CardType cardType,
    required int expireMonth,
    required int expireYear,
    required String issuerName,
    String? plainCvv,
    String? currency,
    bool supportsAllCurrencies = false,
    List<String> supportedCurrencies = const <String>[],
    Decimal? creditLimit,
    Decimal? availableCredit,
    int? billingCycleDay,
    int? paymentDueDay,
    String? billingAddress,
    bool isVirtual = false,
    CardStatus status = CardStatus.active,
  }) async {
    final digits = plainCardNo.replaceAll(RegExp(r'\s+'), '');
    final validate = await _validateCommon(
      accountId: accountId,
      cardOrganization: cardOrganization,
      digits: digits,
      expireMonth: expireMonth,
      expireYear: expireYear,
      issuerName: issuerName,
      currency: currency,
      supportedCurrencies: supportedCurrencies,
      supportsAllCurrencies: supportsAllCurrencies,
      creditLimit: creditLimit,
      availableCredit: availableCredit,
      billingCycleDay: billingCycleDay,
      paymentDueDay: paymentDueDay,
    );
    if (validate.isErr) return Err(validate.errorOrNull!);

    final normalizedCurrencies = supportsAllCurrencies
        ? const <String>[]
        : _normalizeCurrencies(supportedCurrencies);
    final now = _now();
    final card = BankCard(
      id: _idGen(),
      accountId: accountId,
      cardOrganization: cardOrganization.trim().toUpperCase(),
      cardNoMasked: _mask(digits),
      cardType: cardType,
      expireMonth: expireMonth,
      expireYear: expireYear,
      issuerName: issuerName.trim(),
      currency: currency?.trim().toUpperCase(),
      supportsAllCurrencies: supportsAllCurrencies,
      supportedCurrencies: normalizedCurrencies,
      creditLimit: creditLimit,
      availableCredit: availableCredit,
      billingCycleDay: billingCycleDay,
      paymentDueDay: paymentDueDay,
      billingAddress: billingAddress?.trim().isEmpty == true
          ? null
          : billingAddress?.trim(),
      isVirtual: isVirtual,
      status: status,
      createdAt: now,
      updatedAt: now,
    );
    return _cards.create(card: card, plainCardNo: digits, plainCvv: plainCvv);
  }

  Future<Result<BankCard, AppError>> update({
    required BankCard prev,
    required String cardOrganization,
    String? plainCardNo,
    required CardType cardType,
    required int expireMonth,
    required int expireYear,
    required String issuerName,
    String? plainCvv,
    String? currency,
    bool supportsAllCurrencies = false,
    List<String> supportedCurrencies = const <String>[],
    Decimal? creditLimit,
    Decimal? availableCredit,
    int? billingCycleDay,
    int? paymentDueDay,
    String? billingAddress,
    bool? isVirtual,
    CardStatus? status,
  }) async {
    final digits = plainCardNo?.replaceAll(RegExp(r'\s+'), '');
    final validate = await _validateCommon(
      accountId: prev.accountId,
      cardOrganization: cardOrganization,
      digits: digits,
      expireMonth: expireMonth,
      expireYear: expireYear,
      issuerName: issuerName,
      currency: currency,
      supportedCurrencies: supportedCurrencies,
      supportsAllCurrencies: supportsAllCurrencies,
      creditLimit: creditLimit,
      availableCredit: availableCredit,
      billingCycleDay: billingCycleDay,
      paymentDueDay: paymentDueDay,
      requireCardDigits: false,
    );
    if (validate.isErr) return Err(validate.errorOrNull!);

    final normalizedCurrencies = supportsAllCurrencies
        ? const <String>[]
        : _normalizeCurrencies(supportedCurrencies);
    final updated = prev.copyWith(
      cardOrganization: cardOrganization.trim().toUpperCase(),
      cardNoMasked:
          digits == null || digits.isEmpty ? prev.cardNoMasked : _mask(digits),
      cardType: cardType,
      expireMonth: expireMonth,
      expireYear: expireYear,
      issuerName: issuerName.trim(),
      currency: currency?.trim().toUpperCase(),
      supportsAllCurrencies: supportsAllCurrencies,
      supportedCurrencies: normalizedCurrencies,
      creditLimit: creditLimit,
      availableCredit: availableCredit,
      billingCycleDay: billingCycleDay,
      paymentDueDay: paymentDueDay,
      billingAddress: billingAddress?.trim().isEmpty == true
          ? null
          : billingAddress?.trim(),
      isVirtual: isVirtual ?? prev.isVirtual,
      status: status ?? prev.status,
      updatedAt: _now(),
    );
    return _cards.update(card: updated, plainCardNo: digits, plainCvv: plainCvv);
  }

  Future<Result<void, AppError>> _validateCommon({
    required String accountId,
    required String cardOrganization,
    required String? digits,
    required int expireMonth,
    required int expireYear,
    required String issuerName,
    required String? currency,
    required List<String> supportedCurrencies,
    required bool supportsAllCurrencies,
    required Decimal? creditLimit,
    required Decimal? availableCredit,
    required int? billingCycleDay,
    required int? paymentDueDay,
    bool requireCardDigits = true,
  }) async {
    if (accountId.trim().isEmpty) {
      return const Err(ValidationError('请选择归属账户'));
    }
    if (cardOrganization.trim().isEmpty) {
      return const Err(ValidationError('请选择发卡组织'));
    }
    if (issuerName.trim().isEmpty) {
      return const Err(ValidationError('发卡行不能为空'));
    }
    if (requireCardDigits || (digits != null && digits.isNotEmpty)) {
      if (digits == null || digits.length < 10 || !RegExp(r'^\d+$').hasMatch(digits)) {
        return const Err(ValidationError('卡号必须为 10 位以上数字'));
      }
      if (!_luhnCheck(digits)) {
        return const Err(ValidationError('卡号未通过 Luhn 校验'));
      }
    }
    if (expireMonth < 1 || expireMonth > 12) {
      return const Err(ValidationError('expireMonth 必须在 1..12'));
    }
    if (expireYear < 2000 || expireYear > 2100) {
      return const Err(ValidationError('expireYear 超出合理范围'));
    }
    if (currency != null && currency.trim().isEmpty) {
      return const Err(ValidationError('主记账币种不能为空字符串'));
    }
    if (creditLimit != null && creditLimit < Decimal.zero) {
      return const Err(ValidationError('信用额度不能为负数'));
    }
    if (availableCredit != null && availableCredit < Decimal.zero) {
      return const Err(ValidationError('可用额度不能为负数'));
    }
    if (creditLimit != null && availableCredit != null && availableCredit > creditLimit) {
      return const Err(ValidationError('可用额度不能大于信用额度'));
    }
    if (billingCycleDay != null && (billingCycleDay < 1 || billingCycleDay > 31)) {
      return const Err(ValidationError('账单日必须在 1..31'));
    }
    if (paymentDueDay != null && (paymentDueDay < 1 || paymentDueDay > 31)) {
      return const Err(ValidationError('还款日必须在 1..31'));
    }
    if (!supportsAllCurrencies) {
      _normalizeCurrencies(supportedCurrencies);
    }

    final accountCheck = await _accounts.findById(accountId);
    if (accountCheck.isErr) return Err(accountCheck.errorOrNull!);
    return const Ok(null);
  }

  static List<String> _normalizeCurrencies(List<String> input) {
    final seen = <String>{};
    final out = <String>[];
    for (final raw in input) {
      final s = raw.trim().toUpperCase();
      if (s.isEmpty) continue;
      if (!RegExp(r'^[A-Z]{3}$').hasMatch(s)) {
        throw const ValidationError('支持币种需为 3 位 ISO-4217 代码');
      }
      if (seen.add(s)) out.add(s);
    }
    return out;
  }

  static String _mask(String digits) {
    final tail = digits.substring(digits.length - 4);
    return '**** **** **** $tail';
  }

  static bool _luhnCheck(String digits) {
    var sum = 0;
    var alternate = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var n = int.parse(digits[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }
}
