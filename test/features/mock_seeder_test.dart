import 'package:cryptography/cryptography.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwp/core/crypto/field_cipher.dart';
import 'package:gwp/core/crypto/key_derivation.dart';
import 'package:gwp/core/crypto/secure_key_store.dart';
import 'package:gwp/data/crypto_service.dart';
import 'package:gwp/data/db/database.dart';
import 'package:gwp/data/repositories/drift_account_channel_repository.dart';
import 'package:gwp/data/repositories/drift_account_repository.dart';
import 'package:gwp/data/repositories/drift_asset_cost_history_repository.dart';
import 'package:gwp/data/repositories/drift_asset_price_history_repository.dart';
import 'package:gwp/data/repositories/drift_asset_repository.dart';
import 'package:gwp/data/repositories/drift_card_repository.dart';
import 'package:gwp/data/repositories/drift_channel_repository.dart';
import 'package:gwp/data/repositories/drift_dict_repository.dart';
import 'package:gwp/data/repositories/drift_exchange_rate_repository.dart';
import 'package:gwp/data/repositories/drift_event_repository.dart';
import 'package:gwp/data/repositories/drift_watched_pair_repository.dart';
import 'package:gwp/domain/entities/account.dart';
import 'package:gwp/domain/entities/account_type_info.dart';
import 'package:gwp/domain/entities/asset.dart';
import 'package:gwp/domain/entities/asset_type_info.dart';
import 'package:gwp/domain/entities/event_enums.dart';
import 'package:gwp/domain/events/event_bus.dart';
import 'package:gwp/domain/usecases/create_event.dart';
import 'package:gwp/features/settings/mock_seeder.dart';
import 'package:gwp/domain/usecases/create_account.dart';
import 'package:gwp/domain/usecases/create_asset.dart';
import 'package:gwp/domain/usecases/create_card.dart';
import 'package:gwp/domain/usecases/link_account_channel.dart';
import 'package:gwp/domain/usecases/manage_watched_pair.dart';
import 'package:gwp/domain/usecases/save_channel.dart';
import 'package:gwp/domain/usecases/save_manual_rate.dart';
import 'package:gwp/domain/usecases/update_asset.dart';
import 'package:uuid/uuid.dart';

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
  late SeedDeps deps;
  late DriftWatchedPairRepository watched;
  late DriftDictRepository dicts;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());

    final master = await AesGcm.with256bits().newSecretKey();
    final crypto = CryptoService(
      keyStore: _FakeKeyStore(master),
      keyDerivation: KeyDerivation(),
      fieldCipher: FieldCipher(),
    );

    final accounts = DriftAccountRepository(db.accountDao);
    final assets = DriftAssetRepository(db.assetDao);
    final cards = DriftCardRepository(db.cardDao, crypto);
    final priceHistory = DriftAssetPriceHistoryRepository(
      db.assetPriceHistoryDao,
    );
    final costHistory = DriftAssetCostHistoryRepository(db.assetCostHistoryDao);
    final channels = DriftChannelRepository(db.channelDao);
    final accountChannels = DriftAccountChannelRepository(db.accountChannelDao);
    dicts = DriftDictRepository(db.dictEntryDao);
    watched = DriftWatchedPairRepository(db.watchedPairDao);
    final events = DriftEventRepository(db.eventDao);

    const uuid = Uuid();
    deps = SeedDeps(
      createAccount: CreateAccountUseCase(
        accounts,
        idGenerator: uuid.v4,
        now: DateTime.now,
      ),
      createAsset: CreateAssetUseCase(
        assets,
        accounts,
        idGenerator: uuid.v4,
        now: DateTime.now,
      ),
      updateAsset: UpdateAssetUseCase(
        assets,
        costHistory,
        idGenerator: uuid.v4,
        now: DateTime.now,
      ),
      createCard: CreateCardUseCase(
        cards,
        accounts,
        idGenerator: uuid.v4,
        now: DateTime.now,
      ),
      cardRepo: cards,
      saveChannel: SaveChannelUseCase(channels, dicts),
      linkAccountChannel: LinkAccountChannelUseCase(
        accountChannels,
        accounts,
        channels,
      ),
      manageWatchedPair: ManageWatchedPairUseCase(watched, dicts),
      saveManualRate: SaveManualRateUseCase(
        rates: DriftExchangeRateRepository(db.exchangeRateDao),
        watchedPairs: ManageWatchedPairUseCase(watched, dicts),
        dicts: dicts,
        idGenerator: uuid.v4,
        now: DateTime.now,
      ),
      createEvent: CreateEventUseCase(events),
      exchangeRates: DriftExchangeRateRepository(db.exchangeRateDao),
      priceHistory: priceHistory,
      assets: assets,
      idGen: uuid.v4,
      now: DateTime.now,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('seedMockWithDeps 端到端注入：全部仓储零错误，计数全部 > 0', () async {
    final result = await seedMockWithDeps(deps);

    expect(result.errors, isEmpty, reason: 'seeder 不应报错，实际: ${result.errors}');
    expect(result.accounts, greaterThan(0));
    expect(result.assets, greaterThan(0));
    expect(result.cards, greaterThan(0));
    expect(result.channels, greaterThan(0));
    expect(result.channelLinks, greaterThan(0));
    expect(result.events, greaterThan(0));
    expect(result.watchedPairs, greaterThan(0));
    expect(result.rates, greaterThan(0));
    expect(result.pricePoints, greaterThan(0));
    expect(result.costHistoryPoints, greaterThan(0));
  });

  test('watchedPair 已落库且可通过仓储读回', () async {
    await seedMockWithDeps(deps);
    final list = await watched.listAll();
    expect(list, isNotEmpty);
    // 随便取一条，基线字段非空
    expect(list.first.baseCurrency, isNotEmpty);
    expect(list.first.quoteCurrency, isNotEmpty);
  });

  test('幂等守卫：第二次调用默认短路，skipped=true 且计数归零', () async {
    final first = await seedMockWithDeps(deps);
    expect(first.skipped, isFalse);
    expect(first.accounts, greaterThan(0));

    final second = await seedMockWithDeps(deps);
    expect(second.skipped, isTrue);
    expect(second.accounts, 0);
    expect(second.assets, 0);
    expect(second.errors, isEmpty);
  });

  test('force=true 绕过守卫：再次执行不短路', () async {
    await seedMockWithDeps(deps);
    final forced = await seedMockWithDeps(deps, force: true);
    expect(forced.skipped, isFalse);
    // 绕过守卫后 seeder 会实际执行一轮写入（部分条目可能因 UNIQUE 冲突落 errors）
    // 关键契约：不抛异常，且确实走到了写入路径（accounts 计数 + errors 条数之和 > 0）
    expect(forced.accounts + forced.errors.length, greaterThan(0));
  });

  test('seeded rate alerts use real pair keys and card events point to real cards', () async {
    await seedMockWithDeps(deps);

    final recent = await DriftEventRepository(db.eventDao).watchRecent().first;
    final rateAlerts = recent
        .where((e) => e.eventType == DomainEventTypes.rateAlert)
        .toList(growable: false);
    expect(rateAlerts, isNotEmpty);
    for (final event in rateAlerts) {
      expect(event.relatedId, contains('/'));
    }

    final cardEvents = recent
        .where((e) => e.relatedModel == RelatedModel.card)
        .toList(growable: false);
    expect(cardEvents, isNotEmpty);
    for (final event in cardEvents) {
      final card = await deps.cardRepo.findById(event.relatedId);
      expect(
        card.isOk,
        isTrue,
        reason: 'card event should reference real card: ${event.relatedId}',
      );
    }
  });

  test('账户注入后 typeInfo 正确：银行有 SWIFT、券商有币种、钱包有类型', () async {
    await seedMockWithDeps(deps);
    final accounts =
        await DriftAccountRepository(db.accountDao).watchAll().first;

    Account? findAcct(String institutionKeyword) {
      try {
        return accounts.firstWhere(
          (a) => a.institutionName.contains(institutionKeyword),
        );
      } catch (_) {
        return null;
      }
    }

    // Bank: SWIFT + branch + subtype
    final cmb = findAcct('招商银行');
    expect(cmb, isNotNull);
    final bankInfo = cmb!.typeInfo;
    expect(bankInfo, isA<BankAccountInfo>());
    final bi = bankInfo as BankAccountInfo;
    expect(bi.swiftBic, 'CMBCCNBS');
    expect(bi.branchName, '深圳分行');
    expect(bi.accountSubtype, 'savings');

    // Broker: margin + USD base
    final ibkr = findAcct('Interactive Brokers');
    expect(ibkr, isNotNull);
    final brokerInfo = ibkr!.typeInfo;
    expect(brokerInfo, isA<BrokerAccountInfo>());
    final bri = brokerInfo as BrokerAccountInfo;
    expect(bri.accountSubtype, 'margin');
    expect(bri.baseCurrency, 'USD');
    expect(bri.marginEnabled, isTrue);

    // Crypto wallet: hot + Ethereum
    final metamask = findAcct('MetaMask');
    expect(metamask, isNotNull);
    final walletInfo = metamask!.typeInfo;
    expect(walletInfo, isA<CryptoWalletInfo>());
    final wi = walletInfo as CryptoWalletInfo;
    expect(wi.walletType, 'hot');
    expect(wi.chain, 'Ethereum');

    // Insurance: life policy
    final pingan = findAcct('平安人寿');
    expect(pingan, isNotNull);
    final insInfo = pingan!.typeInfo;
    expect(insInfo, isA<InsuranceAccountInfo>());
    expect((insInfo as InsuranceAccountInfo).policyType, 'life');

    // Crypto exchange: has API key
    final binance = findAcct('Binance');
    expect(binance, isNotNull);
    final cexInfo = binance!.typeInfo;
    expect(cexInfo, isA<CryptoExchangeInfo>());
    expect((cexInfo as CryptoExchangeInfo).hasApiKey, isTrue);

    // Payment: wechat platform
    final wechat = findAcct('微信支付');
    expect(wechat, isNotNull);
    final payInfo = wechat!.typeInfo;
    expect(payInfo, isA<PaymentAccountInfo>());
    expect((payInfo as PaymentAccountInfo).platform, 'wechat');

    // Custody: segregated
    final fidelity = findAcct('Fidelity');
    expect(fidelity, isNotNull);
    final custodyInfo = fidelity!.typeInfo;
    expect(custodyInfo, isA<CustodyAccountInfo>());
    expect((custodyInfo as CustodyAccountInfo).accountStructure, 'segregated');

    // EU bank: IBAN
    final deutsche = findAcct('Deutsche');
    expect(deutsche, isNotNull);
    final euBankInfo = deutsche!.typeInfo;
    expect(euBankInfo, isA<BankAccountInfo>());
    expect((euBankInfo as BankAccountInfo).iban, isNotEmpty);
  });

  test('资产注入后 typeInfo 正确：CD 有利率、保单有保额、贵金属有品种', () async {
    await seedMockWithDeps(deps);
    final allAssets =
        await DriftAssetRepository(db.assetDao).watchAll().first;

    Asset? findAsset(String keyword) {
      try {
        return allAssets.firstWhere(
          (a) => (a.assetCode ?? '').contains(keyword),
        );
      } catch (_) {
        return null;
      }
    }

    // CD: FixedIncomeInfo with simple compounding
    final cd = findAsset('CNY-1Y-CD');
    expect(cd, isNotNull);
    final cdInfo = cd!.typeInfo;
    expect(cdInfo, isA<FixedIncomeInfo>());
    final cdi = cdInfo as FixedIncomeInfo;
    expect(cdi.annualRate, Decimal.parse('0.032'));
    expect(cdi.compounding, 'simple');
    expect(cdi.dayCount, 365);
    expect(cdi.maturityDate, DateTime.utc(2025, 6, 1));

    // BOND: FixedIncomeInfo with annual compounding
    final bond = findAsset('TREASURY');
    expect(bond, isNotNull);
    final bondInfo = bond!.typeInfo;
    expect(bondInfo, isA<FixedIncomeInfo>());
    final bdi = bondInfo as FixedIncomeInfo;
    expect(bdi.annualRate, Decimal.parse('0.04'));
    expect(bdi.compounding, 'annual');

    // POLICY: InsuranceInfo
    final policy = findAsset('ENDOW');
    expect(policy, isNotNull);
    final policyInfo = policy!.typeInfo;
    expect(policyInfo, isA<InsuranceInfo>());
    final pi = policyInfo as InsuranceInfo;
    expect(pi.insurer, '平安人寿');
    expect(pi.annualPremium, Decimal.parse('3000'));
    expect(pi.coverage, Decimal.parse('500000'));
    expect(pi.paymentFrequency, 'annual');

    // GOLD: PreciousMetalInfo
    final gold = findAsset('XAU');
    expect(gold, isNotNull);
    final goldInfo = gold!.typeInfo;
    expect(goldInfo, isA<PreciousMetalInfo>());
    final gmi = goldInfo as PreciousMetalInfo;
    expect(gmi.metalType, 'gold');
    expect(gmi.weight, Decimal.parse('8'));
    expect(gmi.purity, Decimal.parse('0.9999'));
  });

  test('typeInfo 与 extInfo JSON 往返一致', () async {
    await seedMockWithDeps(deps);
    final allAssets =
        await DriftAssetRepository(db.assetDao).watchAll().first;

    for (final asset in allAssets) {
      final info = asset.typeInfo;
      final json = info.toJson();
      final roundTripped = AssetTypeInfo.fromJson(json, asset.assetType);
      // Same type
      expect(roundTripped.runtimeType, info.runtimeType,
          reason: '${asset.assetCode} type mismatch');
    }

    final allAccounts =
        await DriftAccountRepository(db.accountDao).watchAll().first;
    for (final account in allAccounts) {
      final info = account.typeInfo;
      final json = info.toJson();
      final roundTripped =
          AccountTypeInfo.fromJson(json, account.accountType);
      expect(roundTripped.runtimeType, info.runtimeType,
          reason: '${account.institutionName} type mismatch');
    }
  });

}
