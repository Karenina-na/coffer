import 'package:drift/drift.dart';

import 'accounts.dart';

/// Card: 银行卡。
///
/// See doc/data-definitions.md §5.
/// 卡号与 CVV 以密文（base64 of AES-GCM）存储，脱敏展示字段独立。
@DataClassName('CardRow')
class Cards extends Table {
  TextColumn get id => text()();
  TextColumn get accountId =>
      text().named('account_id').references(Accounts, #id)();
  TextColumn get cardOrganization => text().named('card_organization')();
  TextColumn get cardNoMasked => text().named('card_no_masked')();
  TextColumn get cardNoCiphertext =>
      text().named('card_no_ciphertext').nullable()();
  TextColumn get cardType => text().named('card_type')();
  IntColumn get expireMonth => integer().named('expire_month')();
  IntColumn get expireYear => integer().named('expire_year')();
  TextColumn get cvvCiphertext => text().named('cvv_ciphertext').nullable()();
  TextColumn get issuerName => text().named('issuer_name')();
  TextColumn get currency => text().nullable()();
  BoolColumn get supportsAllCurrencies => boolean()
      .named('supports_all_currencies')
      .withDefault(const Constant(false))();

  /// CSV of ISO-4217 uppercase codes, e.g. "USD,EUR,HKD". `null` or empty
  /// means "仅主币种"。Not used when `supports_all_currencies = 1`.
  TextColumn get supportedCurrencies =>
      text().named('supported_currencies').nullable()();
  TextColumn get creditLimit => text().named('credit_limit').nullable()();
  TextColumn get availableCredit =>
      text().named('available_credit').nullable()();
  IntColumn get billingCycleDay =>
      integer().named('billing_cycle_day').nullable()();
  IntColumn get paymentDueDay =>
      integer().named('payment_due_day').nullable()();
  TextColumn get billingAddress =>
      text().named('billing_address').nullable()();
  BoolColumn get isVirtual =>
      boolean().named('is_virtual').withDefault(const Constant(false))();
  TextColumn get status => text()();
  IntColumn get sortOrder =>
      integer().named('sort_order').withDefault(const Constant(1000))();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}
