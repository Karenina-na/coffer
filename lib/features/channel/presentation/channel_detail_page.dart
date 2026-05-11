import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/builtin_badge.dart';
import '../../../core/ui/design_tokens.dart';
import '../../../core/ui/enum_labels.dart';
import '../../../core/ui/error_localizer.dart';
import '../../../core/ui/gwp_empty_state.dart';
import '../../../core/ui/gwp_status_badge.dart';
import '../../../core/ui/protocol_display.dart';
import '../../../data/providers/dict_providers.dart';
import '../../../domain/entities/account_channel.dart';
import '../../../domain/entities/channel.dart';
import '../../../domain/entities/channel_enums.dart';
import '../../../domain/entities/dict_entry.dart';
import '../../../domain/entities/dict_type.dart';
import '../../account/presentation/account_providers.dart';
import 'channel_form.dart';
import 'channel_providers.dart';

class ChannelDetailPage extends ConsumerWidget {
  const ChannelDetailPage({super.key, required this.channelId});

  final String channelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channels = ref.watch(channelListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('通道详情')),
      body: channels.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: GwpColors.actionPrimary),
        ),
        error: (e, _) => GwpEmptyState.error(
          message: '加载失败: ${errorToMessage(e)}',
          onRetry: () => ref.invalidate(channelListProvider),
        ),
        data: (list) {
          final c = list.where((x) => x.id == channelId).firstOrNull;
          if (c == null) {
            return const GwpEmptyState(
              icon: Icons.swap_horiz_outlined,
              title: '通道不存在或已删除',
              subtitle: '该通道可能已被移除',
            );
          }
          return _DetailBody(channel: c);
        },
      ),
    );
  }
}

class _DetailBody extends ConsumerStatefulWidget {
  const _DetailBody({required this.channel});

  final Channel channel;

  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.channel;
    final protocolEntriesAsync = ref.watch(dictEntriesProvider(DictType.transferProtocol));
    final ProtocolIndex protocolIndex = {
      for (final entry in protocolEntriesAsync.value ?? const <DictEntry>[]) entry.code: entry,
    };
    if (_editing) {
      return ChannelForm(
        initial: c,
        onSaved: () => setState(() => _editing = false),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _headerCard(context, c, protocolIndex),
        const SizedBox(height: 16),
        _ruleCard(context, c),
        const SizedBox(height: 16),
        _MembersCard(channel: c),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: () => setState(() => _editing = true),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('编辑'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _toggleStatus(c),
              icon: Icon(c.status == ChannelStatus.enabled
                  ? Icons.block_outlined
                  : Icons.play_arrow_outlined),
              label: Text(
                  c.status == ChannelStatus.enabled ? '禁用' : '启用'),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _headerCard(
    BuildContext context,
    Channel c,
    ProtocolIndex protocolIndex,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    c.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (c.isBuiltin) const BuiltinBadge(),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${protocolDisplayLabel(protocolIndex, c.transferProtocol)} · ${c.status.labelZh}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'id: ${c.id}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _ruleCard(BuildContext context, Channel c) {
    final rules = <_RuleItem>[
      _RuleItem(
        icon: Icons.toggle_on_outlined,
        title: '状态',
        value: c.status.labelZh,
        ok: c.status == ChannelStatus.enabled,
      ),
      _RuleItem(
        icon: Icons.date_range_outlined,
        title: '生效窗口',
        value: _windowText(c),
        ok: true,
      ),
      _RuleItem(
        icon: Icons.attach_money_outlined,
        title: '限额币种',
        value: c.limitCurrency ?? '不限',
        ok: true,
      ),
      _RuleItem(
        icon: Icons.payments_outlined,
        title: '费率 / 固定费',
        value:
            '${c.feeRate ?? '0'} / ${c.fixedFee ?? '0'} ${c.limitCurrency ?? ''}',
        ok: true,
      ),
      _RuleItem(
        icon: Icons.speed_outlined,
        title: '单笔上限',
        value: c.singleLimit?.toString() ?? '不限',
        ok: true,
      ),
      _RuleItem(
        icon: Icons.stacked_bar_chart_outlined,
        title: '日累计上限',
        value: c.dailyLimit?.toString() ?? '不限',
        ok: true,
      ),
      ..._regionRules(c),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            for (var i = 0; i < rules.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              ListTile(
                leading: Icon(rules[i].icon),
                title: Text(rules[i].title),
                subtitle: Text(rules[i].value),
                trailing: rules[i].ok
                    ? const Icon(Icons.check_circle_outline)
                    : const Icon(Icons.error_outline),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _windowText(Channel c) {
    String f(DateTime? t) => t == null ? '—' : t.toIso8601String();
    if (c.effectiveFrom == null && c.effectiveTo == null) return '始终有效';
    return '${f(c.effectiveFrom)}  →  ${f(c.effectiveTo)}';
  }

  List<_RuleItem> _regionRules(Channel c) {
    final rule = c.sovereigntyRegionRule;
    if (rule == null || rule.isEmpty) {
      return [
        const _RuleItem(
          icon: Icons.public_outlined,
          title: '主权区域规则',
          value: '无限制',
          ok: true,
        ),
      ];
    }
    final items = <_RuleItem>[];
    final allowed = (rule['allowedRegions'] as List?)?.join(', ');
    final blocked = (rule['blockedRegions'] as List?)?.join(', ');
    final sameRegion = rule['requireSameRegion'] == true;
    if (allowed != null && allowed.isNotEmpty) {
      items.add(_RuleItem(
        icon: Icons.verified_outlined,
        title: '仅允许区域',
        value: allowed,
        ok: true,
      ));
    }
    if (blocked != null && blocked.isNotEmpty) {
      items.add(_RuleItem(
        icon: Icons.block_outlined,
        title: '禁止区域',
        value: blocked,
        ok: true,
      ));
    }
    if (sameRegion) {
      items.add(const _RuleItem(
        icon: Icons.sync_alt_outlined,
        title: '要求同一区域',
        value: '源与目的必须一致',
        ok: true,
      ));
    }
    return items.isEmpty
        ? [
            const _RuleItem(
              icon: Icons.public_outlined,
              title: '主权区域规则',
              value: '无限制',
              ok: true,
            ),
          ]
        : items;
  }

  Future<void> _toggleStatus(Channel c) async {
    final next = c.status == ChannelStatus.enabled
        ? ChannelStatus.disabled
        : ChannelStatus.enabled;
    final result = await ref.read(channelRepositoryProvider).setStatus(c.id, next);
    if (result.isErr && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('状态更新失败：${result.errorOrNull?.message ?? '未知错误'}')),
      );
    }
  }
}

class _RuleItem {
  const _RuleItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.ok,
  });
  final IconData icon;
  final String title;
  final String value;
  final bool ok;
}

/// 展示当前已接入此 Channel 的账户列表；管理动作在账户详情页完成。
class _MembersCard extends ConsumerWidget {
  const _MembersCard({required this.channel});

  final Channel channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(accountChannelListProvider);
    final accountsAsync = ref.watch(accountListProvider);
    return linksAsync.when(
      loading: () => const Card(child: Padding(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(color: GwpColors.actionPrimary),
      )),
      error: (e, _) => Card(child: ListTile(title: Text('加载关联失败: ${errorToMessage(e)}'))),
      data: (links) {
        return accountsAsync.when(
          loading: () => const Card(child: Padding(
            padding: EdgeInsets.all(16),
            child: LinearProgressIndicator(color: GwpColors.actionPrimary),
          )),
          error: (e, _) =>
              Card(child: ListTile(title: Text('加载账户失败: ${errorToMessage(e)}'))),
          data: (accounts) {
            final accById = {for (final a in accounts) a.id: a};
            final members = [
              for (final l in links)
                if (l.channelId == channel.id && accById[l.accountId] != null)
                  (account: accById[l.accountId]!, link: l),
            ];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.account_balance_wallet_outlined),
                      const SizedBox(width: 8),
                      Text('接入账户 (${members.length})',
                          style:
                              Theme.of(context).textTheme.titleSmall),
                    ]),
                    const SizedBox(height: 8),
                    if (members.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text('暂无账户接入此通道，可在账户详情页添加'),
                      )
                    else
                      for (final member in members)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.link),
                          title: Text(member.account.institutionName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${member.account.accountType.labelZh} · ${member.account.sovereigntyRegion}',
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _memberFeeLine(member.link, channel),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _hasFeeOverride(member.link)
                                      ? GwpColors.info
                                      : GwpColors.textMuted,
                                  fontWeight: _hasFeeOverride(member.link)
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                          trailing: _hasFeeOverride(member.link)
                              ? const GwpStatusBadge(
                                  label: '已覆盖',
                                  variant: StatusVariant.info,
                                )
                              : const GwpStatusBadge(
                                  label: '默认',
                                  variant: StatusVariant.muted,
                                ),
                          onTap: () => context.push('/accounts/${member.account.id}'),
                        ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

bool _hasFeeOverride(AccountChannel link) {
  return link.feeRateOverride != null ||
      link.fixedFeeOverride != null ||
      (link.feeCurrencyOverride != null &&
          link.feeCurrencyOverride!.trim().isNotEmpty);
}

String _channelFeeDesc(Channel channel) {
  return _renderFeeDesc(
    feeRate: channel.feeRate,
    fixedFee: channel.fixedFee,
    currency: channel.limitCurrency,
  );
}

String _accountFeeDesc(AccountChannel link, Channel channel) {
  return _renderFeeDesc(
    feeRate: link.feeRateOverride ?? channel.feeRate,
    fixedFee: link.fixedFeeOverride ?? channel.fixedFee,
    currency: link.feeCurrencyOverride ?? channel.limitCurrency,
  );
}

String _memberFeeLine(AccountChannel link, Channel channel) {
  if (_hasFeeOverride(link)) {
    return '账户费率覆盖：${_accountFeeDesc(link, channel)}';
  }
  return '沿用通道默认费率：${_channelFeeDesc(channel)}';
}

String _renderFeeDesc({
  required Decimal? feeRate,
  required Decimal? fixedFee,
  required String? currency,
}) {
  String text = '';
  if (feeRate != null && feeRate > Decimal.zero) {
    text += '${(feeRate.toDouble() * 100).toStringAsFixed(2)}%';
  }
  if (fixedFee != null && fixedFee > Decimal.zero) {
    if (text.isNotEmpty) text += ' + ';
    text += '${currency ?? ''} ${fixedFee.toStringAsFixed(2)}';
  }
  if (text.isEmpty) return '免费';
  return text;
}
