import '../../../domain/repositories/asset_price_history_repository.dart';
import '../../../domain/repositories/asset_repository.dart';
import '../../../domain/repositories/card_repository.dart';
import '../../../domain/repositories/exchange_rate_repository.dart';
import '../../../domain/usecases/create_account.dart';
import '../../../domain/usecases/create_asset.dart';
import '../../../domain/usecases/create_card.dart';
import '../../../domain/usecases/create_event.dart';
import '../../../domain/usecases/link_account_channel.dart';
import '../../../domain/usecases/manage_watched_pair.dart';
import '../../../domain/usecases/save_channel.dart';
import '../../../domain/usecases/save_manual_rate.dart';
import '../../../domain/usecases/update_asset.dart';

class SeedResult {
  const SeedResult({
    required this.accounts,
    required this.assets,
    required this.cards,
    required this.channels,
    required this.channelLinks,
    required this.events,
    required this.watchedPairs,
    required this.rates,
    required this.pricePoints,
    required this.costHistoryPoints,
    required this.errors,
    this.skipped = false,
  });

  factory SeedResult.alreadySeeded() => const SeedResult(
        accounts: 0,
        assets: 0,
        cards: 0,
        channels: 0,
        channelLinks: 0,
        events: 0,
        watchedPairs: 0,
        rates: 0,
        pricePoints: 0,
        costHistoryPoints: 0,
        errors: <String>[],
        skipped: true,
      );

  final int accounts;
  final int assets;
  final int cards;
  final int channels;
  final int channelLinks;
  final int events;
  final int watchedPairs;
  final int rates;
  final int pricePoints;
  final int costHistoryPoints;
  final List<String> errors;
  final bool skipped;

  SeedResult merge(SeedResult other) {
    return SeedResult(
      accounts: accounts + other.accounts,
      assets: assets + other.assets,
      cards: cards + other.cards,
      channels: channels + other.channels,
      channelLinks: channelLinks + other.channelLinks,
      events: events + other.events,
      watchedPairs: watchedPairs + other.watchedPairs,
      rates: rates + other.rates,
      pricePoints: pricePoints + other.pricePoints,
      costHistoryPoints: costHistoryPoints + other.costHistoryPoints,
      errors: [...errors, ...other.errors],
      skipped: skipped && other.skipped,
    );
  }

  SeedResult copyWithErrors(List<String> nextErrors) {
    return SeedResult(
      accounts: accounts,
      assets: assets,
      cards: cards,
      channels: channels,
      channelLinks: channelLinks,
      events: events,
      watchedPairs: watchedPairs,
      rates: rates,
      pricePoints: pricePoints,
      costHistoryPoints: costHistoryPoints,
      errors: nextErrors,
      skipped: skipped,
    );
  }

  @override
  String toString() {
    if (skipped) return '检测到已有资产数据，已跳过注入';
    return '账户 $accounts · 资产 $assets · 卡 $cards · '
        '通道 $channels ($channelLinks 连接) · 事件 $events · '
        '币对 $watchedPairs · 汇率 $rates · 价格点 $pricePoints · '
        '成本调整 $costHistoryPoints'
        '${errors.isEmpty ? '' : '\n错误: ${errors.length} 条'}';
  }
}

class SeedDeps {
  const SeedDeps({
    required this.createAccount,
    required this.createAsset,
    required this.updateAsset,
    required this.createCard,
    required this.cardRepo,
    required this.saveChannel,
    required this.linkAccountChannel,
    required this.manageWatchedPair,
    required this.saveManualRate,
    required this.createEvent,
    required this.exchangeRates,
    required this.priceHistory,
    required this.assets,
    required this.idGen,
    required this.now,
  });

  final CreateAccountUseCase createAccount;
  final CreateAssetUseCase createAsset;
  final UpdateAssetUseCase updateAsset;
  final CreateCardUseCase createCard;
  final CardRepository cardRepo;
  final SaveChannelUseCase saveChannel;
  final LinkAccountChannelUseCase linkAccountChannel;
  final ManageWatchedPairUseCase manageWatchedPair;
  final SaveManualRateUseCase saveManualRate;
  final CreateEventUseCase createEvent;
  final ExchangeRateRepository exchangeRates;
  final AssetPriceHistoryRepository priceHistory;
  final AssetRepository assets;
  final String Function() idGen;
  final DateTime Function() now;
}
