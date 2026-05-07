import '../../../domain/entities/card.dart';
import '../../../domain/entities/card_enums.dart';
import '../../../domain/entities/domain_event.dart';
import '../../../domain/entities/event_enums.dart';
import 'context.dart';
import 'models.dart';
import 'util.dart';

Future<SeedResult> seedCardPaymentPack(SeedAssemblyContext ctx) async {
  var accounts = 0;
  var cards = 0;
  var events = 0;
  final deps = ctx.deps;
  final now = ctx.now;

  Future<void> createCardIfMissing({
    required String id,
    required String accountId,
    required String plainCardNo,
    required CardType type,
    required CardStatus status,
    required String organization,
    required String issuer,
  }) async {
    final existing = await deps.cardRepo.findById(id);
    if (existing.isOk) return;
    final result = await deps.cardRepo.create(
      card: BankCard(
        id: id,
        accountId: accountId,
        cardOrganization: organization,
        cardNoMasked: '**** **** **** ${plainCardNo.substring(plainCardNo.length - 4)}',
        cardType: type,
        expireMonth: now.month,
        expireYear: status == CardStatus.expired ? now.year - 1 : now.year + 2,
        issuerName: issuer,
        currency: 'CNY',
        status: status,
        createdAt: now,
        updatedAt: now,
      ),
      plainCardNo: plainCardNo,
      plainCvv: '321',
    );
    result.when(
      ok: (_) {
        ctx.cardIds[id] = id;
        cards++;
      },
      err: (e) => ctx.errors.add('card pack $id: ${e.message}'),
    );
  }

  final paymentId = ctx.accountIds['cn_payment'];
  final bankId = ctx.accountIds['cn_bank'];
  if (paymentId != null) {
    await createCardIfMissing(
      id: 'pack-card-debit',
      accountId: paymentId,
      plainCardNo: '5555555555554444',
      type: CardType.debit,
      status: CardStatus.active,
      organization: CardOrganization.mastercard.code,
      issuer: '微信支付借记卡',
    );
    await createCardIfMissing(
      id: 'pack-card-prepaid',
      accountId: paymentId,
      plainCardNo: '6221558812340005',
      type: CardType.prepaid,
      status: CardStatus.active,
      organization: CardOrganization.unionpay.code,
      issuer: '微信支付礼品卡',
    );
  }
  if (bankId != null) {
    await createCardIfMissing(
      id: 'pack-card-locked',
      accountId: bankId,
      plainCardNo: '4000056655665556',
      type: CardType.credit,
      status: CardStatus.locked,
      organization: CardOrganization.visa.code,
      issuer: '招商银行锁定卡',
    );
    await createCardIfMissing(
      id: 'pack-card-expired',
      accountId: bankId,
      plainCardNo: '6011111111111117',
      type: CardType.credit,
      status: CardStatus.expired,
      organization: CardOrganization.discover.code,
      issuer: '招商银行过期卡',
    );
  }

  final bank = ctx.accountIds['cn_bank'];
  if (bank != null) {
    final r = await deps.createEvent(
      DomainEvent(
        id: deps.idGen(),
        eventType: 'CARD_STATUS_CHANGED',
        relatedModel: RelatedModel.card,
        relatedId: 'pack-card-locked',
        triggerTime: now.subtract(const Duration(minutes: 20)),
        priority: EventPriority.medium,
        status: EventStatus.triggered,
        handlingStatus: HandlingStatus.processing,
        handlingNote: '检测到异常交易，卡片已临时锁定',
        sourceKey: 'CARD_STATUS_CHANGED:pack-card-locked:${yyyymmdd(now)}',
        ackRequirement: AckRequirement.required_,
        createdAt: now,
        updatedAt: now,
      ),
    );
    r.when(
      ok: (_) => events++,
      err: (e) => ctx.errors.add('card pack event: ${e.message}'),
    );
  }

  return SeedResult(
    accounts: accounts,
    assets: 0,
    cards: cards,
    channels: 0,
    channelLinks: 0,
    events: events,
    watchedPairs: 0,
    rates: 0,
    pricePoints: 0,
    costHistoryPoints: 0,
    errors: const [],
  );
}
