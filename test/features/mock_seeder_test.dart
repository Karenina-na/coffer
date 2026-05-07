import 'package:cryptography/cryptography.dart';
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
import 'package:gwp/data/repositories/drift_exchange_rate_repository.dart';
import 'package:gwp/data/repositories/drift_event_repository.dart';
import 'package:gwp/data/repositories/drift_watched_pair_repository.dart';
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
      saveChannel: SaveChannelUseCase(channels),
      linkAccountChannel: LinkAccountChannelUseCase(
        accountChannels,
        accounts,
        channels,
      ),
      manageWatchedPair: ManageWatchedPairUseCase(watched),
      saveManualRate: SaveManualRateUseCase(
        rates: DriftExchangeRateRepository(db.exchangeRateDao),
        watchedPairs: ManageWatchedPairUseCase(watched),
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

}
