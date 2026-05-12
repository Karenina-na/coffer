import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/money/money.dart';
import '../../../core/ui/enum_labels.dart';
import '../../../core/ui/error_localizer.dart';
import '../../../core/ui/region_meta.dart';
import '../../../data/providers/dict_providers.dart';
import '../../../domain/entities/account.dart';
import '../../../domain/entities/card.dart';
import '../../../domain/entities/card_enums.dart';
import 'brand_theme.dart';
import 'card_providers.dart';
import 'wallet_card_tile.dart';

/// 卡片详情弹层（模态底部面板）。
///
/// 展示卡面 + KPI 概览 + 信用卡额度 + 敏感字段按需解密（卡号 / CVV）
/// + 账单周期 + 关联账户 + 时间戳，沿用资产/账户详情页的 SectionCard 模式。
class CardDetailSheet extends ConsumerStatefulWidget {
  const CardDetailSheet({super.key, required this.card, this.account});

  final BankCard card;
  final Account? account;

  static Future<void> show(
    BuildContext context, {
    required BankCard card,
    Account? account,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => CardDetailSheet(card: card, account: account),
    );
  }

  @override
  ConsumerState<CardDetailSheet> createState() => _CardDetailSheetState();
}

class _CardDetailSheetState extends ConsumerState<CardDetailSheet> {
  String? _revealedCardNo;
  String? _revealedCvv;
  bool _busyCardNo = false;
  bool _busyCvv = false;

  // 敏感字段解密后自动隐藏，避免用户离开弹层后明文长时间暴露。
  // 卡号相对低敏，窗口更宽：60s；CVV 极敏感：30s。
  static const _cardNoAutoHide = Duration(seconds: 60);
  static const _cvvAutoHide = Duration(seconds: 30);
  Timer? _cardNoHideTimer;
  Timer? _cvvHideTimer;

  @override
  void dispose() {
    _cardNoHideTimer?.cancel();
    _cvvHideTimer?.cancel();
    super.dispose();
  }

  Future<void> _toggleRevealCardNo() async {
    if (_revealedCardNo != null) {
      _cardNoHideTimer?.cancel();
      setState(() => _revealedCardNo = null);
      return;
    }
    setState(() => _busyCardNo = true);
    final r =
        await ref.read(cardRepositoryProvider).decryptCardNo(widget.card.id);
    if (!mounted) return;
    setState(() => _busyCardNo = false);
    r.when(
      ok: (plain) {
        setState(() => _revealedCardNo = _spaced(plain));
        _cardNoHideTimer?.cancel();
        _cardNoHideTimer = Timer(_cardNoAutoHide, () {
          if (!mounted) return;
          setState(() => _revealedCardNo = null);
        });
      },
      err: (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('解密失败: ${errorToMessage(e)}')),
      ),
    );
  }

  Future<void> _toggleRevealCvv() async {
    if (_revealedCvv != null) {
      _cvvHideTimer?.cancel();
      setState(() => _revealedCvv = null);
      return;
    }
    setState(() => _busyCvv = true);
    final r =
        await ref.read(cardRepositoryProvider).decryptCvv(widget.card.id);
    if (!mounted) return;
    setState(() => _busyCvv = false);
    r.when(
      ok: (plain) {
        setState(() => _revealedCvv = plain);
        _cvvHideTimer?.cancel();
        _cvvHideTimer = Timer(_cvvAutoHide, () {
          if (!mounted) return;
          setState(() => _revealedCvv = null);
        });
      },
      err: (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('解密失败: ${errorToMessage(e)}')),
      ),
    );
  }

  Future<void> _onEdit() async {
    // 先持有 navigator 引用，再 pop，避免 pop 卸载 Widget 后 mounted=false
    // 导致后续 context.push 被 guard 拦截而永远无法执行。
    final nav = GoRouter.of(context);
    Navigator.of(context).pop();
    nav.push('/cards/${widget.card.id}/edit');
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('删除卡片'),
        content: Text(
          '将删除卡片「${widget.card.cardNoMasked}」，相关的卡片事件与历史'
          '仍会保留。该操作不可恢复，请确认。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('取消'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: FilledButton.styleFrom(
              foregroundColor: Theme.of(dialogCtx).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final r = await ref.read(cardRepositoryProvider).delete(widget.card.id);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    r.when(
      ok: (_) {
        Navigator.of(context).pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('已删除卡片')),
        );
      },
      err: (e) => messenger.showSnackBar(
        SnackBar(content: Text('删除失败: ${errorToMessage(e)}')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.card;
    final brand = BrandTheme.of(c.cardOrganization);
    final scheme = Theme.of(context).colorScheme;
    final regionIndex = ref.watch(regionMetaIndexProvider).value ?? const {};

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          WalletCardTile(card: c, account: widget.account),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('编辑'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _confirmDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.error,
                  ),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('删除'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // ── KPI 概览 ──
          _KpiStrip(card: c),
          const SizedBox(height: 16),
          // ── 信用卡额度 ──
          if (c.cardType == CardType.credit) ...[
            _SectionCard(
              icon: Icons.credit_card_outlined,
              title: '信用卡额度',
              accent: brand.gradient.colors.last,
              children: [_CreditUtilization(card: c)],
            ),
            const SizedBox(height: 12),
            if (c.billingCycleDay != null || c.paymentDueDay != null) ...[
              _SectionCard(
                icon: Icons.event_outlined,
                title: '账单周期',
                accent: brand.gradient.colors.last,
                children: [_BillingCycle(card: c)],
              ),
              const SizedBox(height: 12),
            ],
          ],
          // ── 敏感字段 ──
          _SectionCard(
            icon: Icons.key_outlined,
            title: '敏感字段',
            accent: brand.gradient.colors.last,
            children: [
              _SensitiveRow(
                label: '卡号',
                value: _revealedCardNo ?? c.cardNoMasked,
                revealed: _revealedCardNo != null,
                busy: _busyCardNo,
                onToggle: _toggleRevealCardNo,
                canCopy: _revealedCardNo != null,
                copyValue: (_revealedCardNo ?? '').replaceAll(' ', ''),
              ),
              const Divider(height: 16),
              _SensitiveRow(
                label: 'CVV',
                value: _revealedCvv ?? '•••',
                revealed: _revealedCvv != null,
                busy: _busyCvv,
                onToggle: _toggleRevealCvv,
                canCopy: _revealedCvv != null,
                copyValue: _revealedCvv ?? '',
                hasCiphertext: c.cvvCiphertext != null,
              ),
              const Divider(height: 16),
              _ExpiryRow(card: c),
            ],
          ),
          const SizedBox(height: 12),
          // ── 基本信息 ──
          _SectionCard(
            icon: Icons.info_outline,
            title: '基本信息',
            accent: brand.gradient.colors.last,
            children: [
              _Kv('发卡行', c.issuerName, copy: true),
              _Kv('卡组织', brand.label),
              _Kv('卡类型', _typeLabel(c.cardType)),
              _Kv('状态', _statusLabel(c.status), valueColor: _statusColor(c.status, scheme)),
              _Kv('形态', c.isVirtual ? '虚拟卡' : '实体卡'),
              if (c.currency != null) _Kv('币种', c.currency!),
              _Kv('卡 ID', c.id, copy: true, mono: true),
            ],
          ),
          const SizedBox(height: 12),
          // ── 支持币种 ──
          _SectionCard(
            icon: Icons.language,
            title: '支持币种',
            accent: brand.gradient.colors.last,
            children: [_SupportedCurrencies(card: c)],
          ),
          const SizedBox(height: 12),
          // ── 账单地址 ──
          if (c.billingAddress != null && c.billingAddress!.isNotEmpty) ...[
            _SectionCard(
              icon: Icons.home_outlined,
              title: '账单地址',
              accent: brand.gradient.colors.last,
              children: [_MultilineCopyBlock(value: c.billingAddress!)],
            ),
            const SizedBox(height: 12),
          ],
          // ── 关联账户 ──
          _SectionCard(
            icon: Icons.account_balance_outlined,
            title: '关联账户',
            accent: brand.gradient.colors.last,
            children: [
              if (widget.account != null)
                _AccountLinkTile(
                  account: widget.account!,
                  accountRegionLabel: regionLabel(
                    regionIndex,
                    widget.account!.sovereigntyRegion,
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/accounts/${widget.account!.id}');
                  },
                )
              else
                _LinkRow(
                  k: '账户 ID',
                  v: c.accountId,
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/accounts/${c.accountId}');
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          // ── 时间戳 ──
          _SectionCard(
            icon: Icons.access_time,
            title: '时间戳',
            accent: brand.gradient.colors.last,
            children: [
              _Kv('创建时间', _fmt(c.createdAt), mono: true),
              _Kv('更新时间', _fmt(c.updatedAt), mono: true),
            ],
          ),
        ],
      ),
    );
  }

  static String _spaced(String digits) {
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  static String _typeLabel(CardType t) => switch (t) {
        CardType.debit => '借记卡',
        CardType.credit => '信用卡',
        CardType.prepaid => '预付卡',
      };

  static String _statusLabel(CardStatus s) => switch (s) {
        CardStatus.active => '正常',
        CardStatus.locked => '冻结',
        CardStatus.expired => '过期',
        CardStatus.closed => '销户',
      };

  static Color _statusColor(CardStatus s, ColorScheme scheme) => switch (s) {
        CardStatus.active => Colors.green.shade700,
        CardStatus.locked => Colors.orange.shade700,
        CardStatus.expired => scheme.error,
        CardStatus.closed => scheme.onSurfaceVariant,
      };

  static String _fmt(DateTime d) {
    final l = d.toLocal();
    String p(int n) => n.toString().padLeft(2, '0');
    return '${l.year}-${p(l.month)}-${p(l.day)} ${p(l.hour)}:${p(l.minute)}';
  }
}

// ──────────────────────────────────────────────────────────────
// 工具：有效期 / 倒计时
// ──────────────────────────────────────────────────────────────

/// 返回卡片有效期的最后一天（月末）。
DateTime _expiryEnd(BankCard c) {
  // 有效期通常到 "expireMonth" 月末（当月最后一刻）。
  final year = c.expireYear < 100 ? 2000 + c.expireYear : c.expireYear;
  final nextMonth = DateTime(year, c.expireMonth + 1, 1);
  return nextMonth.subtract(const Duration(days: 1));
}

/// 有效期剩余天数；已过期为负。
int _daysUntilExpiry(BankCard c) {
  final now = DateTime.now();
  final end = _expiryEnd(c);
  return end.difference(DateTime(now.year, now.month, now.day)).inDays;
}

/// 计算最近的未来账单日/还款日（相对今天的 [day]），返回该日期与倒计时天数。
({DateTime date, int days}) _nextDayOfMonth(int day) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  // 若本月该日未过，返回本月；否则返回下月。
  final thisMonth = DateTime(now.year, now.month, day);
  if (!thisMonth.isBefore(today)) {
    return (date: thisMonth, days: thisMonth.difference(today).inDays);
  }
  final next = DateTime(now.year, now.month + 1, day);
  return (date: next, days: next.difference(today).inDays);
}

String _fmtMd(DateTime d) {
  String p(int n) => n.toString().padLeft(2, '0');
  return '${p(d.month)}-${p(d.day)}';
}

// ──────────────────────────────────────────────────────────────
// Section 卡片容器（icon + title + divider + children）
// ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.accent,
    required this.children,
  });

  final IconData icon;
  final String title;
  final Color accent;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.6),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(
              height: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// KPI 概览条（有效期倒计时 / 状态 / 形态 / 币种）
// ──────────────────────────────────────────────────────────────

class _KpiStrip extends StatelessWidget {
  const _KpiStrip({required this.card});
  final BankCard card;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final days = _daysUntilExpiry(card);
    final isExpired = days < 0;
    final expiringSoon = !isExpired && days <= 60;

    final expiryColor = isExpired
        ? scheme.error
        : (expiringSoon ? Colors.orange.shade700 : Colors.green.shade700);
    final expiryLabel = isExpired
        ? '已过期'
        : (days == 0 ? '今天过期' : '$days 天');
    final expirySub = isExpired
        ? '${-days} 天前'
        : (expiringSoon ? '即将过期' : '有效期至 ${_fmtMd(_expiryEnd(card))}');

    return Row(
      children: [
        _KpiChip(
          icon: Icons.schedule,
          iconColor: expiryColor,
          label: '有效期',
          value: expiryLabel,
          sub: expirySub,
        ),
        const SizedBox(width: 8),
        _KpiChip(
          icon: Icons.verified_user_outlined,
          iconColor: _CardDetailSheetState._statusColor(card.status, scheme),
          label: '状态',
          value: _CardDetailSheetState._statusLabel(card.status),
          sub: card.status.labelZh,
        ),
        const SizedBox(width: 8),
        _KpiChip(
          icon: card.isVirtual ? Icons.smartphone : Icons.credit_card,
          iconColor: scheme.primary,
          label: '形态',
          value: card.isVirtual ? '虚拟卡' : '实体卡',
          sub: card.currency ?? '—',
        ),
      ],
    );
  }
}

class _KpiChip extends StatelessWidget {
  const _KpiChip({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.sub,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: iconColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: iconColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: TextStyle(
                fontSize: 10,
                color: scheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 信用卡额度利用率
// ──────────────────────────────────────────────────────────────

class _CreditUtilization extends StatelessWidget {
  const _CreditUtilization({required this.card});
  final BankCard card;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final limit = card.creditLimit;
    final avail = card.availableCredit;
    final ccy = card.currency ?? '';

    if (limit == null) {
      return Text(
        '未设置信用额度',
        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
      );
    }

    final limitD = limit.toDouble();
    final avail0 = avail ?? Decimal.zero;
    final used = (avail != null) ? (limit - avail) : null;
    final usedD = used?.toDouble();
    final usedRatio = (usedD != null && limitD > 0)
        ? (usedD / limitD).clamp(0.0, 1.0)
        : null;

    // 颜色分段：<30% 绿；30-70% 橙；>70% 红。
    Color ringColor = scheme.primary;
    if (usedRatio != null) {
      if (usedRatio < 0.3) {
        ringColor = Colors.green.shade600;
      } else if (usedRatio < 0.7) {
        ringColor = Colors.orange.shade700;
      } else {
        ringColor = scheme.error;
      }
    }

    String money(Decimal v) => Money.format(v, currency: ccy);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 利用率条
        Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: CircularProgressIndicator(
                      value: usedRatio ?? 0,
                      strokeWidth: 6,
                      backgroundColor:
                          scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                      valueColor: AlwaysStoppedAnimation(ringColor),
                    ),
                  ),
                  Text(
                    usedRatio == null
                        ? '—'
                        : '${(usedRatio * 100).round()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: ringColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '可用额度',
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    avail == null ? '—' : Money.format(avail, currency: ccy),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '总额度 ${Money.format(limit, currency: ccy)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 细分：已用 / 可用
        Row(
          children: [
            _MiniMetric(
              label: '已用',
              value: used == null ? '—' : money(used),
              color: ringColor,
            ),
            const SizedBox(width: 8),
            _MiniMetric(
              label: '可用',
              value: avail == null ? '—' : money(avail0),
              color: scheme.primary,
            ),
            const SizedBox(width: 8),
            _MiniMetric(
              label: '总额',
              value: money(limit),
              color: scheme.onSurface,
            ),
          ],
        ),
      ],
    );
  }
}

// 注意：Money.format 接收 Decimal；派生金额（used = limit - avail）直接通过
// Decimal 相减得到，避免 double 金额运算带来的精度损失。
class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 账单周期：账单日 / 还款日 + 倒计时
// ──────────────────────────────────────────────────────────────

class _BillingCycle extends StatelessWidget {
  const _BillingCycle({required this.card});
  final BankCard card;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = <Widget>[];
    if (card.billingCycleDay != null) {
      final next = _nextDayOfMonth(card.billingCycleDay!);
      items.add(_CycleTile(
        icon: Icons.receipt_long_outlined,
        label: '下个账单日',
        date: next.date,
        days: next.days,
        note: '每月 ${card.billingCycleDay} 日',
        color: scheme.primary,
      ));
    }
    if (card.paymentDueDay != null) {
      final next = _nextDayOfMonth(card.paymentDueDay!);
      final urgent = next.days <= 3;
      items.add(_CycleTile(
        icon: Icons.alarm_outlined,
        label: '下个还款日',
        date: next.date,
        days: next.days,
        note: '每月 ${card.paymentDueDay} 日',
        color: urgent ? scheme.error : Colors.orange.shade700,
      ));
    }
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(child: items[i]),
          if (i < items.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _CycleTile extends StatelessWidget {
  const _CycleTile({
    required this.icon,
    required this.label,
    required this.date,
    required this.days,
    required this.note,
    required this.color,
  });
  final IconData icon;
  final String label;
  final DateTime date;
  final int days;
  final String note;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            days == 0 ? '今天' : '$days 天后',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${_fmtMd(date)} · $note',
            style: TextStyle(
              fontSize: 10,
              color: scheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 敏感字段行（卡号 / CVV）
// ──────────────────────────────────────────────────────────────

class _SensitiveRow extends StatelessWidget {
  const _SensitiveRow({
    required this.label,
    required this.value,
    required this.revealed,
    required this.busy,
    required this.onToggle,
    required this.canCopy,
    required this.copyValue,
    this.hasCiphertext = true,
  });

  final String label;
  final String value;
  final bool revealed;
  final bool busy;
  final VoidCallback onToggle;
  final bool canCopy;
  final String copyValue;
  final bool hasCiphertext;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: label == '卡号' ? 2 : 4,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: scheme.onSurface,
            ),
          ),
        ),
        if (canCopy) _CopyIconButton(value: copyValue, label: label),
        IconButton(
          tooltip: !hasCiphertext
              ? '未存储 $label'
              : (revealed ? '隐藏' : '显示'),
          onPressed: (!hasCiphertext || busy) ? null : onToggle,
          icon: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  revealed
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                ),
        ),
      ],
    );
  }
}

class _ExpiryRow extends StatelessWidget {
  const _ExpiryRow({required this.card});
  final BankCard card;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final days = _daysUntilExpiry(card);
    final isExpired = days < 0;
    final expiringSoon = !isExpired && days <= 60;
    final color = isExpired
        ? scheme.error
        : (expiringSoon ? Colors.orange.shade700 : scheme.onSurface);
    final expiry =
        '${card.expireMonth.toString().padLeft(2, '0')}/${(card.expireYear % 100).toString().padLeft(2, '0')}';
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(
            '有效期',
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            expiry,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        if (isExpired || expiringSoon)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isExpired ? '已过期' : '$days 天内过期',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        _CopyIconButton(value: expiry, label: '有效期'),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 关联账户 tile
// ──────────────────────────────────────────────────────────────

class _AccountLinkTile extends StatelessWidget {
  const _AccountLinkTile({
    required this.account,
    required this.accountRegionLabel,
    required this.onTap,
  });
  final Account account;
  final String accountRegionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.account_balance,
                  size: 18,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.institutionName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${account.accountType.labelZh} · $accountRegionLabel'
                      '${account.accountNo != null ? ' · ${account.accountNo}' : ''}',
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 支持币种
// ──────────────────────────────────────────────────────────────

class _SupportedCurrencies extends StatelessWidget {
  const _SupportedCurrencies({required this.card});
  final BankCard card;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = card.currency;

    if (card.supportsAllCurrencies) {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.primary.withValues(alpha: 0.18),
                  scheme.tertiary.withValues(alpha: 0.18),
                ],
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.35),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.public, size: 14, color: scheme.primary),
                const SizedBox(width: 4),
                Text(
                  '全币种',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              primary == null ? '任意币种消费' : '任意币种消费 · 主记账 $primary',
              style: TextStyle(
                fontSize: 11,
                color: scheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    // 合并主币种 + supportedCurrencies，保持顺序，主币种置前。
    final chips = <String>[];
    if (primary != null && primary.isNotEmpty) chips.add(primary);
    for (final c in card.supportedCurrencies) {
      if (!chips.contains(c)) chips.add(c);
    }
    if (chips.isEmpty) {
      return Text(
        '未声明',
        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final ccy in chips)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ccy == primary
                      ? scheme.primary.withValues(alpha: 0.14)
                      : scheme.surfaceContainerHighest.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: ccy == primary
                        ? scheme.primary.withValues(alpha: 0.4)
                        : scheme.outlineVariant,
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (ccy == primary) ...[
                      Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 3),
                    ],
                    Text(
                      ccy,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: ccy == primary
                            ? scheme.primary
                            : scheme.onSurface,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          card.supportedCurrencies.isEmpty ? '仅主记账币种消费' : '共 ${chips.length} 种',
          style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 通用 Key-Value / Link / Copy 组件
// ──────────────────────────────────────────────────────────────

class _Kv extends StatelessWidget {
  const _Kv(
    this.k,
    this.v, {
    this.copy = false,
    this.mono = false,
    this.valueColor,
  });
  final String k;
  final String v;
  final bool copy;
  final bool mono;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              k,
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: valueColor ?? scheme.onSurface,
                fontFeatures: mono ? const [FontFeature.tabularFigures()] : null,
              ),
            ),
          ),
          if (copy) _CopyIconButton(value: v, label: k),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.k, required this.v, required this.onTap});
  final String k;
  final String v;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 72,
              child: Text(
                k,
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Text(
                v,
                style: TextStyle(
                  fontSize: 13,
                  color: scheme.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: scheme.primary.withValues(alpha: 0.4),
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: scheme.primary),
          ],
        ),
      ),
    );
  }
}

class _MultilineCopyBlock extends StatelessWidget {
  const _MultilineCopyBlock({required this.value});
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          _CopyIconButton(value: value, label: '账单地址'),
        ],
      ),
    );
  }
}

class _CopyIconButton extends StatelessWidget {
  const _CopyIconButton({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: '复制 $label',
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.copy_outlined, size: 18),
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: value));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已复制$label'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }
}
