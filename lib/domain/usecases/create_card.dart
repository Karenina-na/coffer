import '../../core/errors.dart';
import '../../core/result.dart';
import '../entities/card.dart';
import '../entities/card_enums.dart';
import '../repositories/account_repository.dart';
import '../repositories/card_repository.dart';

/// 新建银行卡用例。
///
/// 职责：
/// - 校验账户存在、卡号基础格式
/// - 计算脱敏卡号（保留后 4 位）
/// - 委派 Repository 完成字段级加密与持久化
class CreateCardUseCase {
  CreateCardUseCase(
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

  Future<Result<BankCard, AppError>> call({
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
    String? billingAddress,
    bool isVirtual = false,
    CardStatus status = CardStatus.active,
  }) async {
    final digits = plainCardNo.replaceAll(RegExp(r'\s+'), '');
    if (digits.length < 10 || !RegExp(r'^\d+$').hasMatch(digits)) {
      return const Err(ValidationError('卡号必须为 10 位以上数字'));
    }
    if (!_luhnCheck(digits)) {
      return const Err(ValidationError('卡号未通过 Luhn 校验'));
    }
    if (expireMonth < 1 || expireMonth > 12) {
      return const Err(ValidationError('expireMonth 必须在 1..12'));
    }
    if (expireYear < 2000 || expireYear > 2100) {
      return const Err(ValidationError('expireYear 超出合理范围'));
    }

    // 规范化支持币种列表
    final normalized = supportsAllCurrencies
        ? const <String>[]
        : _normalizeCurrencies(supportedCurrencies);

    final accountCheck = await _accounts.findById(accountId);
    if (accountCheck.isErr) return Err(accountCheck.errorOrNull!);

    final now = _now();

    final masked = _mask(digits);
    final card = BankCard(
      id: _idGen(),
      accountId: accountId,
      cardOrganization: cardOrganization,
      cardNoMasked: masked,
      cardType: cardType,
      expireMonth: expireMonth,
      expireYear: expireYear,
      issuerName: issuerName,
      currency: currency,
      supportsAllCurrencies: supportsAllCurrencies,
      supportedCurrencies: normalized,
      billingAddress: billingAddress,
      isVirtual: isVirtual,
      status: status,
      createdAt: now,
      updatedAt: now,
    );
    return _cards.create(
      card: card,
      plainCardNo: digits,
      plainCvv: plainCvv,
    );
  }

  static List<String> _normalizeCurrencies(List<String> input) {
    final seen = <String>{};
    final out = <String>[];
    for (final raw in input) {
      final s = raw.trim().toUpperCase();
      if (s.isEmpty) continue;
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
