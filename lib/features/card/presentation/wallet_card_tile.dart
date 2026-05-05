import 'package:flutter/material.dart';

import '../../../core/ui/enum_labels.dart';
import '../../../core/ui/region_meta.dart';
import '../../../domain/entities/account.dart';
import '../../../domain/entities/card.dart';
import '../../../domain/entities/card_enums.dart';
import 'brand_theme.dart';

/// Apple Wallet 风格的卡片磁贴。
///
/// 整张卡按发卡组织渲染渐变色，信息密度参考钱包 App：
/// - 顶部：发卡行 + 状态
/// - 中部：掩码卡号（突出后 4 位）
/// - 底部左：关联账户 + 卡类型
/// - 底部右：品牌名 + 有效期
class WalletCardTile extends StatelessWidget {
  const WalletCardTile({
    super.key,
    required this.card,
    required this.account,
    this.regionMeta,
    this.onTap,
    this.heroTag,
  });

  final BankCard card;
  final Account? account;
  final RegionMeta? regionMeta;
  final VoidCallback? onTap;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final brand = BrandTheme.of(card.cardOrganization);
    final content = _Face(
      card: card,
      account: account,
      brand: brand,
      regionMeta: regionMeta,
    );

    final tile = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: brand.gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: brand.gradient.colors.last.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 200,
            width: double.infinity,
            child: Stack(
              children: [
                _Decoration(color: brand.onColor),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: content,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (heroTag != null) {
      return Hero(tag: heroTag!, child: tile);
    }
    return tile;
  }
}

/// 右下角装饰环，仿钱包卡面的非接触符号 / 线条。
class _Decoration extends StatelessWidget {
  const _Decoration({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: -30,
      top: -30,
      child: IgnorePointer(
        child: Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.08), width: 60),
          ),
        ),
      ),
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({
    required this.card,
    required this.account,
    required this.brand,
    this.regionMeta,
  });

  final BankCard card;
  final Account? account;
  final BrandTheme brand;
  final RegionMeta? regionMeta;

  @override
  Widget build(BuildContext context) {
    final fg = brand.onColor;
    final muted = fg.withValues(alpha: 0.75);
    final last4 = _last4(card.cardNoMasked);
    final expiry = ExpirySignal.of(card);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 顶部：发卡行 + 状态 + 地区
        Row(
          children: [
            Expanded(
              child: Text(
                card.issuerName,
                style: TextStyle(
                  color: fg,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (regionMeta != null) ...[
              _RegionChip(meta: regionMeta!, fg: fg),
              const SizedBox(width: 6),
            ],
            _StatusBadge(status: card.status, fg: fg),
          ],
        ),
        const Spacer(),
        // 中部:卡号掩码
        Text(
          '•••• $last4',
          style: TextStyle(
            color: fg,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 4,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 14),
        // 底部:关联账户 + 品牌
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '关联账户',
                    style: TextStyle(
                      color: muted,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    account == null
                        ? '—'
                        : '${account!.institutionName} · ${account!.accountType.code}',
                    style: TextStyle(
                      color: fg,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  _ExpiryLine(card: card, expiry: expiry, muted: muted),
                ],
              ),
            ),
            Text(
              brand.label,
              style: TextStyle(
                color: fg,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _last4(String masked) {
    final trimmed = masked.trim();
    if (trimmed.length <= 4) return trimmed;
    return trimmed.substring(trimmed.length - 4);
  }
}

/// 到期紧急度分档，外部（如 `CardListPage`）也会复用做排序 / 横条聚合。
enum ExpiryTone { none, warn, critical, expired }

/// 根据卡片的 `expireMonth / expireYear` 计算的到期信号。
///
/// 以"有效期月份的最后一天 23:59:59 本地时间"为到期点：
/// - 已过期 → [ExpiryTone.expired]
/// - ≤30 天 → [ExpiryTone.critical]
/// - ≤90 天 → [ExpiryTone.warn]
/// - 其他 → [ExpiryTone.none]
class ExpirySignal {
  const ExpirySignal({required this.daysLeft, required this.tone});

  final int daysLeft; // 负数代表已过期后的天数
  final ExpiryTone tone;

  bool get expired => tone == ExpiryTone.expired;
  bool get urgent => tone == ExpiryTone.critical || tone == ExpiryTone.expired;

  static ExpirySignal of(BankCard c, {DateTime? now}) {
    final n = now ?? DateTime.now();
    // 当月最后一天末尾：DateTime(y, m+1, 0) = 下月第 0 日 = 本月最后一天
    final lastDay = DateTime(c.expireYear, c.expireMonth + 1, 0);
    final expiryAt =
        DateTime(lastDay.year, lastDay.month, lastDay.day, 23, 59, 59);
    final diff = expiryAt.difference(n).inDays;
    if (expiryAt.isBefore(n)) {
      return ExpirySignal(daysLeft: diff, tone: ExpiryTone.expired);
    }
    if (diff <= 30) {
      return ExpirySignal(daysLeft: diff, tone: ExpiryTone.critical);
    }
    if (diff <= 90) {
      return ExpirySignal(daysLeft: diff, tone: ExpiryTone.warn);
    }
    return ExpirySignal(daysLeft: diff, tone: ExpiryTone.none);
  }
}

String _expiryMmYy(BankCard c) {
  String p(int n) => n.toString().padLeft(2, '0');
  return '${p(c.expireMonth)}/${p(c.expireYear % 100)}';
}

/// 卡面底部"CARDTYPE · MM/YY [· 倒计时/已过期]"行，按紧急度染色。
class _ExpiryLine extends StatelessWidget {
  const _ExpiryLine({
    required this.card,
    required this.expiry,
    required this.muted,
  });

  final BankCard card;
  final ExpirySignal expiry;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final base = '${card.cardType.labelZh} · ${_expiryMmYy(card)}';
    final suffix = switch (expiry.tone) {
      ExpiryTone.expired => ' · 已过期',
      ExpiryTone.critical => ' · 剩 ${expiry.daysLeft}d',
      ExpiryTone.warn => ' · 剩 ${expiry.daysLeft}d',
      ExpiryTone.none => '',
    };
    final color = switch (expiry.tone) {
      ExpiryTone.expired => Colors.redAccent.shade100,
      ExpiryTone.critical => Colors.redAccent.shade100,
      ExpiryTone.warn => Colors.amberAccent.shade100,
      ExpiryTone.none => muted,
    };
    final weight = expiry.tone == ExpiryTone.none
        ? FontWeight.normal
        : FontWeight.w600;
    return Text(
      '$base$suffix',
      style: TextStyle(
        color: color,
        fontSize: 11,
        letterSpacing: 0.4,
        fontWeight: weight,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.fg});

  final CardStatus status;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      CardStatus.active => Colors.greenAccent.shade400,
      CardStatus.locked => Colors.orangeAccent.shade200,
      CardStatus.expired => Colors.white70,
      CardStatus.closed => Colors.white54,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.code,
            style: TextStyle(
              color: fg,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _RegionChip extends StatelessWidget {
  const _RegionChip({required this.meta, required this.fg});

  final RegionMeta meta;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    final label = meta.parentName != null
        ? '${meta.parentName} | ${meta.displayName}'
        : meta.displayName;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (meta.flag != null) ...[
            Text(meta.flag!, style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
