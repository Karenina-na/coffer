import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coffer/domain/entities/card.dart';
import 'package:coffer/domain/entities/card_enums.dart';

void main() {
  test('BankCard.toString does not expose ciphertext fields', () {
    final card = BankCard(
      id: 'card-1',
      accountId: 'acc-1',
      cardOrganization: 'VISA',
      cardNoMasked: '**** 1234',
      cardNoCiphertext: 'secret-card-cipher',
      cardType: CardType.credit,
      expireMonth: 12,
      expireYear: 2030,
      cvvCiphertext: 'secret-cvv-cipher',
      issuerName: 'Example Bank',
      currency: 'USD',
      creditLimit: Decimal.parse('10000'),
      availableCredit: Decimal.parse('8000'),
      status: CardStatus.active,
      createdAt: DateTime.utc(2025, 1, 1),
      updatedAt: DateTime.utc(2025, 1, 2),
    );

    final text = card.toString();
    expect(text, isNot(contains('secret-card-cipher')));
    expect(text, isNot(contains('secret-cvv-cipher')));
    expect(text, contains('**** 1234'));
  });
}
