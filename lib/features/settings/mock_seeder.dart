import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../account/presentation/account_providers.dart';
import '../asset/presentation/asset_providers.dart';
import '../card/presentation/card_providers.dart';
import '../channel/presentation/channel_providers.dart';
import '../event/presentation/event_providers.dart';
import '../exchange_rate/presentation/exchange_rate_providers.dart';
import 'seeder/card_payment_pack.dart';
import 'seeder/context.dart';
import 'seeder/core_financial_pack.dart';
import 'seeder/models.dart';

export 'seeder/models.dart';

Future<SeedResult> seedMockData(WidgetRef ref, {bool force = false}) {
  return seedMockWithDeps(
    SeedDeps(
      createAccount: ref.read(createAccountUseCaseProvider),
      createAsset: ref.read(createAssetUseCaseProvider),
      updateAsset: ref.read(updateAssetUseCaseProvider),
      createCard: ref.read(createCardUseCaseProvider),
      cardRepo: ref.read(cardRepositoryProvider),
      saveChannel: ref.read(saveChannelUseCaseProvider),
      linkAccountChannel: ref.read(linkAccountChannelUseCaseProvider),
      manageWatchedPair: ref.read(manageWatchedPairUseCaseProvider),
      saveManualRate: ref.read(saveManualRateUseCaseProvider),
      createEvent: ref.read(createEventUseCaseProvider),
      exchangeRates: ref.read(exchangeRateRepositoryProvider),
      priceHistory: ref.read(assetPriceHistoryRepositoryProvider),
      assets: ref.read(assetRepositoryProvider),
      idGen: ref.read(uuidGeneratorProvider),
      now: DateTime.now,
    ),
    force: force,
  );
}

Future<SeedResult> seedMockWithDeps(SeedDeps deps, {bool force = false}) async {
  if (!force) {
    final existing = await deps.assets.watchAll().first.timeout(
      const Duration(seconds: 2),
      onTimeout: () => const [],
    );
    if (existing.isNotEmpty) return SeedResult.alreadySeeded();
  }

  final now = deps.now();
  final ctx = SeedAssemblyContext(deps: deps, now: now);

  final baseResult = await seedCoreFinancialPack(ctx);

  final extra = await seedCardPaymentPack(ctx);
  return baseResult.merge(extra).copyWithErrors(ctx.errors);
}
