import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'card_enums.dart';

part 'card.freezed.dart';

/// 银行卡领域模型。
///
/// 卡号与 CVV：
/// - 在领域/UI 层仅以 [cardNoMasked] 对外展示
/// - 明文仅在创建/校验瞬间存在于内存
/// - 持久化时由 data 层加密为 [cardNoCiphertext] / [cvvCiphertext]
///
/// 币种支持：
/// - [currency] 为主记账币种（信用额度 / 可用额度的计价单位）
/// - [supportsAllCurrencies] = true 时视为全币种卡，[supportedCurrencies]
///   被忽略
/// - 否则 [supportedCurrencies] 为显式的可消费币种（ISO-4217 大写代码）。
///   空列表表示「仅主币种」
///
/// 字段对齐 doc/data-definitions.md §5。
@freezed
abstract class BankCard with _$BankCard {
  const factory BankCard({
    required String id,
    required String accountId,
    required String cardOrganization,
    required String cardNoMasked,
    String? cardNoCiphertext,
    required CardType cardType,
    required int expireMonth,
    required int expireYear,
    String? cvvCiphertext,
    required String issuerName,
    String? currency,
    @Default(false) bool supportsAllCurrencies,
    @Default(<String>[]) List<String> supportedCurrencies,
    Decimal? creditLimit,
    Decimal? availableCredit,
    int? billingCycleDay,
    int? paymentDueDay,
    String? billingAddress,
    @Default(false) bool isVirtual,
    required CardStatus status,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _BankCard;

  @override
  String toString() => 'BankCard('
      'id: $id, '
      'accountId: $accountId, '
      'cardNoMasked: $cardNoMasked, '
      'cardType: $cardType, '
      'cardOrganization: $cardOrganization, '
      'issuerName: $issuerName, '
      'currency: $currency, '
      'status: $status'
      ')';
}
