import 'package:cryptography/cryptography.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coffer/core/crypto/field_cipher.dart';
import 'package:coffer/core/crypto/key_derivation.dart';
import 'package:coffer/core/crypto/secure_key_store.dart';
import 'package:coffer/core/errors.dart';
import 'package:coffer/data/crypto_service.dart';
import 'package:coffer/data/db/database.dart';
import 'package:coffer/data/repositories/drift_account_repository.dart';
import 'package:coffer/data/repositories/drift_card_repository.dart';
import 'package:coffer/domain/entities/account_enums.dart';
import 'package:coffer/domain/entities/card_enums.dart';
import 'package:coffer/domain/usecases/create_account.dart';
import 'package:coffer/domain/usecases/create_card.dart';

class _FakeKeyStore implements SecureKeyStore {
  _FakeKeyStore(this._key);
  final SecretKey _key;

  @override
  Future<SecretKey> loadOrCreateMaster() async => _key;

  @override
  Future<void> destroyMaster() async {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppDatabase db;
  late DriftAccountRepository accounts;
  late DriftCardRepository cards;
  late CryptoService crypto;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    accounts = DriftAccountRepository(db.accountDao);
    final master = await AesGcm.with256bits().newSecretKey();
    crypto = CryptoService(
      keyStore: _FakeKeyStore(master),
      keyDerivation: KeyDerivation(),
      fieldCipher: FieldCipher(),
    );
    cards = DriftCardRepository(db.cardDao, crypto);

    // seed account
    final uc = CreateAccountUseCase(
      accounts,
      idGenerator: () => 'acc-1',
      now: DateTime.now,
    );
    await uc(
      accountType: AccountType.bank,
      sovereigntyRegion: 'CN',
      institutionName: 'CMB',
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('create 加密卡号与 CVV，落库仅为密文', () async {
    final uc = CreateCardUseCase(
      cards,
      accounts,
      idGenerator: () => 'card-1',
      now: DateTime.now,
    );
    final r = await uc(
      accountId: 'acc-1',
      cardOrganization: 'VISA',
      plainCardNo: '4111111111111111',
      cardType: CardType.credit,
      expireMonth: 12,
      expireYear: 2030,
      issuerName: 'CMB',
      plainCvv: '123',
    );
    expect(r.isOk, isTrue);
    final saved = r.valueOrNull!;
    expect(saved.cardNoMasked, '**** **** **** 1111');
    expect(saved.cardNoCiphertext, isNotNull);
    expect(saved.cvvCiphertext, isNotNull);
    expect(saved.cardNoCiphertext, isNot(contains('4111')));
  });

  test('decryptCardNo 还原明文；decryptCvv 还原明文', () async {
    final uc = CreateCardUseCase(
      cards,
      accounts,
      idGenerator: () => 'card-2',
      now: DateTime.now,
    );
    await uc(
      accountId: 'acc-1',
      cardOrganization: 'MC',
      plainCardNo: '5500 0000 0000 0004',
      cardType: CardType.debit,
      expireMonth: 1,
      expireYear: 2029,
      issuerName: 'CMB',
      plainCvv: '999',
    );

    final pan = await cards.decryptCardNo('card-2');
    expect(pan.valueOrNull, '5500000000000004');

    final cvv = await cards.decryptCvv('card-2');
    expect(cvv.valueOrNull, '999');
  });

  test('非法卡号返回 ValidationError', () async {
    final uc = CreateCardUseCase(
      cards,
      accounts,
      idGenerator: () => 'x',
      now: DateTime.now,
    );
    final r = await uc(
      accountId: 'acc-1',
      cardOrganization: 'VISA',
      plainCardNo: '12a',
      cardType: CardType.credit,
      expireMonth: 1,
      expireYear: 2029,
      issuerName: 'X',
    );
    expect(r.errorOrNull, isA<ValidationError>());
  });

  test('account 不存在返回 NotFoundError', () async {
    final uc = CreateCardUseCase(
      cards,
      accounts,
      idGenerator: () => 'x',
      now: DateTime.now,
    );
    final r = await uc(
      accountId: 'missing',
      cardOrganization: 'VISA',
      plainCardNo: '4111111111111111',
      cardType: CardType.credit,
      expireMonth: 12,
      expireYear: 2030,
      issuerName: 'X',
    );
    expect(r.errorOrNull, isA<NotFoundError>());
  });

  test('supportedCurrencies 大写去重后持久化，读回顺序稳定', () async {
    final uc = CreateCardUseCase(
      cards,
      accounts,
      idGenerator: () => 'card-ccy',
      now: DateTime.now,
    );
    final r = await uc(
      accountId: 'acc-1',
      cardOrganization: 'VISA',
      plainCardNo: '4111111111111111',
      cardType: CardType.credit,
      expireMonth: 12,
      expireYear: 2030,
      issuerName: 'CMB',
      currency: 'CNY',
      supportedCurrencies: ['usd', 'USD', ' eur ', 'HKD'],
    );
    expect(r.isOk, isTrue);
    final saved = r.valueOrNull!;
    expect(saved.currency, 'CNY');
    expect(saved.supportsAllCurrencies, isFalse);
    expect(saved.supportedCurrencies, ['USD', 'EUR', 'HKD']);

    final reread = await cards.findById('card-ccy');
    expect(reread.valueOrNull!.supportedCurrencies, ['USD', 'EUR', 'HKD']);
  });

  test('supportsAllCurrencies=true 时忽略 supportedCurrencies', () async {
    final uc = CreateCardUseCase(
      cards,
      accounts,
      idGenerator: () => 'card-all',
      now: DateTime.now,
    );
    final r = await uc(
      accountId: 'acc-1',
      cardOrganization: 'VISA',
      plainCardNo: '4111111111111111',
      cardType: CardType.credit,
      expireMonth: 12,
      expireYear: 2030,
      issuerName: 'CMB',
      currency: 'USD',
      supportsAllCurrencies: true,
      supportedCurrencies: ['CNY', 'EUR'],
    );
    expect(r.isOk, isTrue);
    final saved = r.valueOrNull!;
    expect(saved.supportsAllCurrencies, isTrue);
    expect(saved.supportedCurrencies, isEmpty);
  });

  test('update: 改卡号时重新加密并更新 masked', () async {
    final create = CreateCardUseCase(
      cards,
      accounts,
      idGenerator: () => 'card-upd',
      now: DateTime.now,
    );
    final created = await create(
      accountId: 'acc-1',
      cardOrganization: 'VISA',
      plainCardNo: '4111111111111111',
      cardType: CardType.credit,
      expireMonth: 12,
      expireYear: 2030,
      issuerName: 'CMB',
      plainCvv: '123',
    );
    expect(created.isOk, isTrue);
    final original = created.valueOrNull!;
    expect(original.cardNoMasked, '**** **** **** 1111');

    // 换新卡号；CVV 保持不变（不传 plainCvv）。
    final newPan = '5500000000000004';
    final newMasked = '**** **** **** 0004';
    final updated = await cards.update(
      card: original.copyWith(
        cardNoMasked: newMasked,
        issuerName: 'CMB-renamed',
      ),
      plainCardNo: newPan,
    );
    expect(updated.isOk, isTrue);
    final saved = updated.valueOrNull!;
    expect(saved.cardNoMasked, newMasked);
    expect(saved.issuerName, 'CMB-renamed');
    expect(saved.cardNoCiphertext, isNot(original.cardNoCiphertext));

    // 解密明文确认新密文落库。
    final pan = await cards.decryptCardNo('card-upd');
    expect(pan.valueOrNull, newPan);
    // 未传 plainCvv 时，旧 CVV 明文仍可解出。
    final cvv = await cards.decryptCvv('card-upd');
    expect(cvv.valueOrNull, '123');
  });

  test('update: 不传 plainCardNo/plainCvv 时保留原密文', () async {
    final create = CreateCardUseCase(
      cards,
      accounts,
      idGenerator: () => 'card-upd2',
      now: DateTime.now,
    );
    final created = await create(
      accountId: 'acc-1',
      cardOrganization: 'VISA',
      plainCardNo: '4111111111111111',
      cardType: CardType.credit,
      expireMonth: 12,
      expireYear: 2030,
      issuerName: 'CMB',
      plainCvv: '321',
    );
    final original = created.valueOrNull!;
    final updated = await cards.update(
      card: original.copyWith(issuerName: 'CMB-2'),
    );
    expect(updated.isOk, isTrue);
    final pan = await cards.decryptCardNo('card-upd2');
    expect(pan.valueOrNull, '4111111111111111');
    final cvv = await cards.decryptCvv('card-upd2');
    expect(cvv.valueOrNull, '321');
  });

  test('decryptCvv: 未知 cardId 返回 NotFoundError', () async {
    final r = await cards.decryptCvv('does-not-exist');
    expect(r.isErr, isTrue);
    expect(r.errorOrNull, isA<NotFoundError>());
  });

  test('decryptCvv: 创建卡未录入 CVV 时 ciphertext=null，解密返回 NotFoundError', () async {
    final uc = CreateCardUseCase(
      cards,
      accounts,
      idGenerator: () => 'card-no-cvv',
      now: DateTime.now,
    );
    final created = await uc(
      accountId: 'acc-1',
      cardOrganization: 'VISA',
      plainCardNo: '4111111111111111',
      cardType: CardType.credit,
      expireMonth: 12,
      expireYear: 2030,
      issuerName: 'CMB',
      // 关键：不传 plainCvv
    );
    expect(created.isOk, isTrue);
    expect(created.valueOrNull!.cvvCiphertext, isNull);

    final cvv = await cards.decryptCvv('card-no-cvv');
    expect(cvv.isErr, isTrue);
    expect(cvv.errorOrNull, isA<NotFoundError>());
  });

  test('decryptCvv: 用错误主密钥实例化的 CryptoService 无法解密已有密文 → CryptoError', () async {
    // 先用正确密钥写入一张卡
    final uc = CreateCardUseCase(
      cards,
      accounts,
      idGenerator: () => 'card-rotated',
      now: DateTime.now,
    );
    await uc(
      accountId: 'acc-1',
      cardOrganization: 'VISA',
      plainCardNo: '4111111111111111',
      cardType: CardType.credit,
      expireMonth: 12,
      expireYear: 2030,
      issuerName: 'CMB',
      plainCvv: '456',
    );

    // 构造一个「主密钥不同」的 CryptoService（模拟 keystore 被换 / 跨设备恢复失败）
    final wrongMaster = await AesGcm.with256bits().newSecretKey();
    final wrongCrypto = CryptoService(
      keyStore: _FakeKeyStore(wrongMaster),
      keyDerivation: KeyDerivation(),
      fieldCipher: FieldCipher(),
    );
    final wrongCards = DriftCardRepository(db.cardDao, wrongCrypto);

    final cvv = await wrongCards.decryptCvv('card-rotated');
    expect(cvv.isErr, isTrue);
    expect(cvv.errorOrNull, isA<CryptoError>());

    final pan = await wrongCards.decryptCardNo('card-rotated');
    expect(pan.isErr, isTrue);
    expect(pan.errorOrNull, isA<CryptoError>());
  });
}
