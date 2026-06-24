import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/money/money.dart';
import '../../../core/search/highlighted_text.dart';
import '../../../core/search/search_ranking.dart';
import '../../../core/ui/entity_search_delegate.dart';
import '../../../core/ui/region_meta.dart';
import '../../../data/providers/dict_providers.dart';
import '../../../domain/entities/account.dart';
import '../../../domain/entities/asset.dart';
import '../../../domain/entities/card.dart';
import '../../../domain/entities/domain_event.dart';
import '../../../domain/entities/watched_pair.dart';
import '../../account/presentation/account_providers.dart';
import '../../asset/presentation/asset_providers.dart';
import '../../card/presentation/card_detail_sheet.dart';
import '../../card/presentation/card_providers.dart';
import '../../event/presentation/event_providers.dart';
import '../../exchange_rate/presentation/exchange_rate_providers.dart';
import '../../exchange_rate/presentation/pair_detail_page.dart';
import 'search_commands.dart';
import 'search_history_store.dart';

/// 全局搜索覆盖的业务模块。
enum SearchFeature { dashboard, accounts, assets, cards, rates, events }

String _labelOf(SearchFeature f) => switch (f) {
  SearchFeature.dashboard => '仪表盘',
  SearchFeature.accounts => '账户',
  SearchFeature.assets => '资产',
  SearchFeature.cards => '卡片',
  SearchFeature.rates => '汇率',
  SearchFeature.events => '事件',
};

IconData _iconOf(SearchFeature f) => switch (f) {
  SearchFeature.dashboard => Icons.dashboard_outlined,
  SearchFeature.accounts => Icons.account_balance_outlined,
  SearchFeature.assets => Icons.savings_outlined,
  SearchFeature.cards => Icons.credit_card_outlined,
  SearchFeature.rates => Icons.sync_alt_outlined,
  SearchFeature.events => Icons.event_note_outlined,
};

/// 某个业务模块的搜索配置：提供数据源 + 字段抽取 + 跳转。
///
/// 新 API 采用字段抽取器（titleOf / subtitleOf / identityOf），
/// 由 [GlobalSearchDelegate] 统一渲染命中行 —— 以获得一致的高亮 /
/// 评分排序 / 访问历史记录行为。`itemBuilder` 被保留但不再使用。
class FeatureSearchConfig<T> {
  FeatureSearchConfig({
    required this.feature,
    required List<T> items,
    required String Function(T item) titleOf,
    String? Function(T item)? subtitleOf,
    required String Function(T item) identityOf,
    Widget Function(BuildContext ctx, T item)? trailingBuilder,
    bool Function(T item)? isThreeLine,
    List<String> Function(T item)? extraFields,
    required void Function(BuildContext ctx, T item) onTap,
    List<SearchFilterGroup<T>> filterGroups = const [],
  }) : items = List<dynamic>.from(items),
       titleOf = ((dynamic x) => titleOf(x as T)),
       subtitleOf = ((dynamic x) =>
           subtitleOf == null ? null : subtitleOf(x as T)),
       identityOf = ((dynamic x) => identityOf(x as T)),
       trailingBuilder = trailingBuilder == null
           ? null
           : ((ctx, dynamic x) => trailingBuilder(ctx, x as T)),
       isThreeLine = isThreeLine == null
           ? null
           : ((dynamic x) => isThreeLine(x as T)),
       extraFields = ((dynamic x) =>
           extraFields == null ? const <String>[] : extraFields(x as T)),
       onTap = ((ctx, dynamic x) => onTap(ctx, x as T)),
       filterGroups = [
         for (final g in filterGroups)
           SearchFilterGroup<dynamic>(
             title: g.title,
             chips: [
               for (final c in g.chips)
                 SearchFilterChipSpec<dynamic>(
                   label: c.label,
                   predicate: (dynamic x) => c.predicate(x as T),
                 ),
             ],
           ),
       ];

  final SearchFeature feature;
  final List<dynamic> items;
  final String Function(dynamic item) titleOf;
  final String? Function(dynamic item) subtitleOf;
  final String Function(dynamic item) identityOf;
  final Widget Function(BuildContext ctx, dynamic item)? trailingBuilder;
  final bool Function(dynamic item)? isThreeLine;
  final List<String> Function(dynamic item) extraFields;
  final void Function(BuildContext ctx, dynamic item) onTap;
  final List<SearchFilterGroup<dynamic>> filterGroups;

  String get label => _labelOf(feature);
  IconData get icon => _iconOf(feature);

  bool match(dynamic item, String q) {
    if (titleOf(item).toLowerCase().contains(q)) return true;
    final s = subtitleOf(item);
    if (s != null && s.toLowerCase().contains(q)) return true;
    for (final f in extraFields(item)) {
      if (f.toLowerCase().contains(q)) return true;
    }
    return false;
  }

  int score(dynamic item, String q) {
    return scoreMax(<String?>[
      titleOf(item),
      subtitleOf(item),
      ...extraFields(item),
    ], q);
  }
}

class _Hit {
  _Hit({
    required this.feature,
    required this.item,
    required this.config,
    required this.score,
  });
  final SearchFeature feature;
  final dynamic item;
  final FeatureSearchConfig config;
  final int score;
}

/// 打开顶部全局搜索。
Future<void> openGlobalSearch({
  required BuildContext context,
  required WidgetRef ref,
  required SearchFeature current,
  FeatureSearchConfig? override,
}) {
  final configs = <FeatureSearchConfig>[
    _buildAccountsConfig(ref),
    _buildAssetsConfig(ref),
    _buildCardsConfig(ref),
    _buildRatesConfig(ref),
    _buildEventsConfig(context, ref),
  ];
  if (override != null) {
    final i = configs.indexWhere((c) => c.feature == current);
    if (i >= 0) configs[i] = override;
  }
  return showSearch<void>(
    context: context,
    delegate: GlobalSearchDelegate(
      current: current,
      configs: configs,
      ref: ref,
      commands: defaultSearchCommands(),
    ),
  );
}

class GlobalSearchDelegate extends SearchDelegate<void> {
  GlobalSearchDelegate({
    required this.current,
    required this.configs,
    required this.ref,
    required this.commands,
  }) : super(searchFieldLabel: '搜索：账户 / 资产 / 卡片 / 汇率 / 事件（> 执行命令）');

  final SearchFeature current;
  final List<FeatureSearchConfig> configs;
  final WidgetRef ref;
  final List<SearchCommand> commands;

  final Set<SearchFilterChipSpec<dynamic>> _active = {};

  FeatureSearchConfig? get _currentConfig {
    for (final c in configs) {
      if (c.feature == current) return c;
    }
    return null;
  }

  @override
  List<Widget>? buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(
        tooltip: '清空',
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    tooltip: '返回',
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  String _lastRecordedQuery = '';

  @override
  Widget buildResults(BuildContext context) {
    final q = query.trim();
    if (q.isNotEmpty && !q.startsWith('>') && q != _lastRecordedQuery) {
      _lastRecordedQuery = q;
      ref.read(searchHistoryProvider.notifier).recordQuery(q);
    }
    return _buildBody(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) => _buildBody(context);

  Widget _buildBody(BuildContext context) {
    return StatefulBuilder(
      builder: (ctx, setInner) {
        final raw = query.trim();
        final isCommand = raw.startsWith('>');
        final q = isCommand
            ? raw.substring(1).trim().toLowerCase()
            : raw.toLowerCase();

        if (raw.isEmpty) return _buildEmptyState(ctx);
        if (isCommand) return _buildCommandView(ctx, q);
        return _buildResultsView(ctx, q, setInner);
      },
    );
  }

  // ─── 空态：最近查询 + 最近访问 + 入口提示 ───────────────────────────

  Widget _buildEmptyState(BuildContext ctx) {
    final theme = Theme.of(ctx);
    final history = ref.watch(searchHistoryProvider);

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _sectionHeader(
          ctx,
          title: '搜索小贴士',
          subtitle: '输入关键词跨模块检索 · 以 `>` 开头进入命令模式',
        ),
        if (history.queries.isNotEmpty) ...[
          _sectionHeader(
            ctx,
            title: '最近搜索',
            trailing: TextButton(
              onPressed: () =>
                  ref.read(searchHistoryProvider.notifier).clearQueries(),
              child: const Text('清空'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final q in history.queries)
                  ActionChip(
                    label: Text(q),
                    onPressed: () => query = q,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
          ),
        ],
        if (history.visits.isNotEmpty) ...[
          _sectionHeader(ctx, title: '最近访问'),
          for (final v in history.visits)
            ListTile(
              dense: true,
              leading: Icon(
                _iconOf(_parseFeature(v.feature) ?? current),
                color: theme.colorScheme.onSurfaceVariant,
              ),
              title: Text(v.label),
              subtitle: v.sublabel == null ? null : Text(v.sublabel!),
              trailing: const Icon(Icons.north_east, size: 16),
              onTap: () => _jumpToVisit(ctx, v),
            ),
        ],
        _sectionHeader(ctx, title: '快捷命令', subtitle: '输入 > 打开命令面板'),
        for (final c in commands.take(4))
          ListTile(
            dense: true,
            leading: Icon(c.icon),
            title: Text(c.title),
            subtitle: c.subtitle == null ? null : Text(c.subtitle!),
            onTap: () {
              close(ctx, null);
              c.run(ctx, ref);
            },
          ),
      ],
    );
  }

  // ─── 命令面板（> 前缀） ───────────────────────────────────────────

  Widget _buildCommandView(BuildContext ctx, String q) {
    final scored = <(SearchCommand, int)>[];
    for (final c in commands) {
      final s = q.isEmpty
          ? 10
          : scoreMax(<String?>[c.title, c.subtitle, ...c.keywords], q);
      if (s > 0) scored.add((c, s));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _sectionHeader(
          ctx,
          title: '命令面板',
          subtitle: scored.isEmpty ? '无匹配命令' : '${scored.length} 条命令',
        ),
        for (final (cmd, _) in scored)
          ListTile(
            leading: Icon(cmd.icon),
            title: HighlightedText(text: cmd.title, query: q),
            subtitle: cmd.subtitle == null
                ? null
                : HighlightedText(text: cmd.subtitle!, query: q),
            onTap: () {
              close(ctx, null);
              cmd.run(ctx, ref);
            },
          ),
      ],
    );
  }

  // ─── 结果视图（两段：全局命中 + 当前模块精筛） ────────────────────

  Widget _buildResultsView(
    BuildContext ctx,
    String q,
    void Function(VoidCallback) setInner,
  ) {
    final curr = _currentConfig;
    final theme = Theme.of(ctx);

    // 第一段：全局命中（按分数排序；同分时当前模块优先）
    final hits = <_Hit>[];
    for (final c in configs) {
      for (final item in c.items) {
        final s = c.score(item, q);
        if (s > 0) {
          hits.add(_Hit(feature: c.feature, item: item, config: c, score: s));
        }
      }
    }
    hits.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      // 当前模块优先
      final aC = a.feature == current ? 0 : 1;
      final bC = b.feature == current ? 0 : 1;
      return aC.compareTo(bC);
    });

    // 第二段：当前模块精筛（保留原有 filter chips 行为）
    List<dynamic> currList = const [];
    if (curr != null) {
      Iterable<dynamic> it = curr.items;
      it = it.where((e) => curr.match(e, q));
      for (final g in curr.filterGroups) {
        final active = g.chips.where((c) => _active.contains(c)).toList();
        if (active.isEmpty) continue;
        it = it.where((x) => active.any((c) => c.predicate(x)));
      }
      currList = it.toList(growable: false);
    }

    // 命令联想：结果不多时提示 `>` 命令模式
    final cmdSuggest = scoreMax(
      commands
          .expand((c) => <String?>[c.title, c.subtitle, ...c.keywords])
          .toList(growable: false),
      q,
    );

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _sectionHeader(
            ctx,
            title: '全局搜索',
            subtitle: curr == null
                ? '${hits.length} 条结果'
                : '${hits.length} 条结果 · 「${curr.label}」优先',
          ),
        ),
        if (hits.isEmpty)
          SliverToBoxAdapter(child: _buildEmptyCtas(ctx, q))
        else
          SliverToBoxAdapter(
            child: Column(
              children: [
                for (int i = 0; i < hits.length; i++) ...[
                  if (i == 0 || hits[i - 1].feature != hits[i].feature)
                    _featureGroupLabel(
                      ctx,
                      feature: hits[i].feature,
                      isCurrent: hits[i].feature == current,
                    ),
                  if (i > 0 && hits[i - 1].feature == hits[i].feature)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                  _renderHitTile(ctx, hits[i], q),
                ],
              ],
            ),
          ),
        if (cmdSuggest > 0)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => query = '>$q',
                  icon: const Icon(Icons.terminal, size: 16),
                  label: Text('试试命令：>$q'),
                ),
              ),
            ),
          ),
        if (curr != null) ...[
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(
            child: _sectionHeader(
              ctx,
              title: '${curr.label} · 精筛',
              subtitle: curr.filterGroups.isEmpty ? null : '在当前模块内结合标签组合过滤',
            ),
          ),
          if (curr.filterGroups.isNotEmpty)
            SliverToBoxAdapter(
              child: SearchFilterChipsBar<dynamic>(
                groups: curr.filterGroups,
                active: _active,
                onToggle: (chip) => setInner(() {
                  if (!_active.remove(chip)) _active.add(chip);
                }),
                onClear: _active.isEmpty ? null : () => setInner(_active.clear),
              ),
            ),
          if (currList.isEmpty)
            SliverToBoxAdapter(child: _emptyHint(theme, '无匹配结果'))
          else
            SliverToBoxAdapter(
              child: Column(
                children: [
                  for (int i = 0; i < currList.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    _renderTile(ctx, curr, currList[i], q),
                  ],
                ],
              ),
            ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 48)),
      ],
    );
  }

  // ─── 空结果 CTA：新建 / 开命令 ─────────────────────────────────

  Widget _buildEmptyCtas(BuildContext ctx, String q) {
    final theme = Theme.of(ctx);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '未找到「$q」',
            style: theme.textTheme.titleSmall?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 8),
          Text(
            '是否新建 ——',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _ctaChip(
                ctx,
                '新建账户',
                Icons.account_balance_outlined,
                () => ctx.push('/accounts/new'),
              ),
              _ctaChip(
                ctx,
                '新建资产',
                Icons.savings_outlined,
                () => ctx.push('/assets/new'),
              ),
              _ctaChip(
                ctx,
                '新建卡片',
                Icons.credit_card_outlined,
                () => ctx.push('/cards/new'),
              ),
              _ctaChip(
                ctx,
                '新建事件',
                Icons.event_note_outlined,
                () => ctx.push('/events/new'),
              ),
              _ctaChip(
                ctx,
                '新建渠道',
                Icons.hub_outlined,
                () => ctx.push('/channels/new'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ctaChip(
    BuildContext ctx,
    String label,
    IconData icon,
    VoidCallback go,
  ) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onPressed: () {
        close(ctx, null);
        go();
      },
    );
  }

  // ─── 命中行渲染 ─────────────────────────────────────────────

  Widget _renderHitTile(BuildContext ctx, _Hit h, String q) =>
      _renderTile(ctx, h.config, h.item, q);

  Widget _renderTile(
    BuildContext ctx,
    FeatureSearchConfig c,
    dynamic item,
    String q,
  ) {
    final title = c.titleOf(item);
    final sub = c.subtitleOf(item);
    final isThree = c.isThreeLine?.call(item) ?? false;
    return ListTile(
      leading: CircleAvatar(child: Icon(c.icon)),
      title: HighlightedText(
        text: title,
        query: q,
        style: Theme.of(ctx).textTheme.bodyLarge,
      ),
      subtitle: sub == null
          ? null
          : HighlightedText(
              text: sub,
              query: q,
              style: Theme.of(ctx).textTheme.bodySmall,
              maxLines: isThree ? 3 : 2,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: c.trailingBuilder?.call(ctx, item),
      isThreeLine: isThree,
      onTap: () {
        // 记录历史
        ref
            .read(searchHistoryProvider.notifier)
            .recordVisit(
              SearchVisit(
                feature: c.feature.name,
                targetId: c.identityOf(item),
                label: title,
                sublabel: sub,
                visitedAt: DateTime.now(),
              ),
            );
        if (query.trim().isNotEmpty) {
          ref.read(searchHistoryProvider.notifier).recordQuery(query.trim());
        }
        close(ctx, null);
        c.onTap(ctx, item);
      },
    );
  }

  // ─── headers ────────────────────────────────────────────────

  Widget _sectionHeader(
    BuildContext ctx, {
    required String title,
    String? subtitle,
    Widget? trailing,
  }) {
    final theme = Theme.of(ctx);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _featureGroupLabel(
    BuildContext ctx, {
    required SearchFeature feature,
    required bool isCurrent,
  }) {
    final theme = Theme.of(ctx);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          Text(
            _labelOf(feature),
            style: theme.textTheme.labelMedium?.copyWith(
              color: isCurrent
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isCurrent) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '当前',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyHint(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.all(24),
    child: Center(
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
      ),
    ),
  );

  // ─── 最近访问跳转 ─────────────────────────────────────────────

  SearchFeature? _parseFeature(String name) {
    for (final f in SearchFeature.values) {
      if (f.name == name) return f;
    }
    return null;
  }

  void _jumpToVisit(BuildContext ctx, SearchVisit v) {
    close(ctx, null);
    final f = _parseFeature(v.feature);
    switch (f) {
      case SearchFeature.accounts:
        ctx.push('/accounts/${v.targetId}');
      case SearchFeature.assets:
        ctx.push('/assets/${v.targetId}');
      case SearchFeature.cards:
        // 卡片详情是 bottom sheet；在没有卡对象时跳列表。
        ctx.go('/cards');
      case SearchFeature.rates:
        Navigator.of(ctx).push(
          MaterialPageRoute(
            builder: (_) => PairDetailPage(pairKey: v.targetId),
          ),
        );
      case SearchFeature.events:
        ctx.go('/events');
      case SearchFeature.dashboard:
      case null:
        ctx.go('/dashboard');
    }
  }
}

// ───────────────────────── default per-feature configs ─────────────────────────

FeatureSearchConfig<Account> _buildAccountsConfig(WidgetRef ref) {
  final accounts = ref.read(accountListProvider).value ?? const <Account>[];
  final regionIndex = ref.read(regionMetaIndexProvider).value ?? const {};
  final types = accounts.map((a) => a.accountType).toSet().toList()
    ..sort((a, b) => a.code.compareTo(b.code));
  final statuses = accounts.map((a) => a.status).toSet().toList()
    ..sort((a, b) => a.code.compareTo(b.code));
  final regions = accounts.map((a) => a.sovereigntyRegion).toSet().toList()
    ..sort();
  return FeatureSearchConfig<Account>(
    feature: SearchFeature.accounts,
    items: accounts,
    identityOf: (a) => a.id,
    titleOf: (a) => a.institutionName,
    subtitleOf: (a) =>
        '${a.accountType.code} · ${regionLabel(regionIndex, a.sovereigntyRegion)}'
        '${a.accountNo != null ? ' · ${a.accountNo}' : ''}',
    extraFields: (a) => [
      a.accountNo ?? '',
      a.sovereigntyRegion,
      a.accountType.code,
    ],
    onTap: (ctx, a) => ctx.push('/accounts/${a.id}'),
    filterGroups: [
      if (types.isNotEmpty)
        SearchFilterGroup<Account>(
          title: '类型',
          chips: [
            for (final t in types)
              SearchFilterChipSpec<Account>(
                label: t.code,
                predicate: (a) => a.accountType == t,
              ),
          ],
        ),
      if (statuses.isNotEmpty)
        SearchFilterGroup<Account>(
          title: '状态',
          chips: [
            for (final s in statuses)
              SearchFilterChipSpec<Account>(
                label: s.code,
                predicate: (a) => a.status == s,
              ),
          ],
        ),
      if (regions.length > 1)
        SearchFilterGroup<Account>(
          title: '地区',
          chips: [
            for (final r in regions)
              SearchFilterChipSpec<Account>(
                label: regionLabel(regionIndex, r),
                predicate: (a) => a.sovereigntyRegion == r,
              ),
          ],
        ),
    ],
  );
}

FeatureSearchConfig<Asset> _buildAssetsConfig(WidgetRef ref) {
  final assets = ref.read(assetListProvider).value ?? const <Asset>[];
  final types = assets.map((a) => a.assetType).toSet().toList()
    ..sort((a, b) => a.code.compareTo(b.code));
  final statuses = assets.map((a) => a.status).toSet().toList()
    ..sort((a, b) => a.code.compareTo(b.code));
  final currencies = assets.map((a) => a.currency).toSet().toList()..sort();
  return FeatureSearchConfig<Asset>(
    feature: SearchFeature.assets,
    items: assets,
    identityOf: (a) => a.id,
    titleOf: (a) => a.assetCode ?? a.assetType.code,
    subtitleOf: (a) => '${a.assetType.code} · 数量 ${a.quantity} · ${a.currency}',
    extraFields: (a) => [a.assetCode ?? '', a.assetType.code, a.currency],
    trailingBuilder: (ctx, a) {
      final mv = a.marketValue;
      return Text(
        mv == null ? '—' : Money.format(mv, currency: a.currency),
        style: Theme.of(ctx).textTheme.titleMedium,
      );
    },
    onTap: (ctx, a) => ctx.push('/assets/${a.id}'),
    filterGroups: [
      if (types.isNotEmpty)
        SearchFilterGroup<Asset>(
          title: '类型',
          chips: [
            for (final t in types)
              SearchFilterChipSpec<Asset>(
                label: t.code,
                predicate: (a) => a.assetType == t,
              ),
          ],
        ),
      if (statuses.isNotEmpty)
        SearchFilterGroup<Asset>(
          title: '状态',
          chips: [
            for (final s in statuses)
              SearchFilterChipSpec<Asset>(
                label: s.code,
                predicate: (a) => a.status == s,
              ),
          ],
        ),
      if (currencies.length > 1)
        SearchFilterGroup<Asset>(
          title: '币种',
          chips: [
            for (final c in currencies)
              SearchFilterChipSpec<Asset>(
                label: c,
                predicate: (a) => a.currency == c,
              ),
          ],
        ),
    ],
  );
}

FeatureSearchConfig<BankCard> _buildCardsConfig(WidgetRef ref) {
  final cards = ref.read(cardListProvider).value ?? const <BankCard>[];
  final accounts = ref.read(accountListProvider).value ?? const <Account>[];
  final byId = <String, Account>{for (final a in accounts) a.id: a};
  final orgs = cards.map((c) => c.cardOrganization).toSet().toList()..sort();
  final types = cards.map((c) => c.cardType).toSet().toList()
    ..sort((a, b) => a.code.compareTo(b.code));
  final statuses = cards.map((c) => c.status).toSet().toList()
    ..sort((a, b) => a.code.compareTo(b.code));
  return FeatureSearchConfig<BankCard>(
    feature: SearchFeature.cards,
    items: cards,
    identityOf: (c) => c.id,
    titleOf: (c) => c.cardNoMasked,
    subtitleOf: (c) =>
        '${c.issuerName} · ${c.cardOrganization} · ${c.cardType.code}'
        '${c.currency != null ? ' · ${c.currency}' : ''}',
    extraFields: (c) => [
      c.issuerName,
      c.cardOrganization,
      c.cardType.code,
      c.currency ?? '',
    ],
    onTap: (ctx, c) {
      final acc = byId[c.accountId];
      CardDetailSheet.show(ctx, card: c, account: acc);
    },
    filterGroups: [
      if (types.isNotEmpty)
        SearchFilterGroup<BankCard>(
          title: '类型',
          chips: [
            for (final t in types)
              SearchFilterChipSpec<BankCard>(
                label: t.code,
                predicate: (c) => c.cardType == t,
              ),
          ],
        ),
      if (orgs.length > 1)
        SearchFilterGroup<BankCard>(
          title: '组织',
          chips: [
            for (final o in orgs)
              SearchFilterChipSpec<BankCard>(
                label: o,
                predicate: (c) => c.cardOrganization == o,
              ),
          ],
        ),
      if (statuses.isNotEmpty)
        SearchFilterGroup<BankCard>(
          title: '状态',
          chips: [
            for (final s in statuses)
              SearchFilterChipSpec<BankCard>(
                label: s.code,
                predicate: (c) => c.status == s,
              ),
          ],
        ),
      SearchFilterGroup<BankCard>(
        title: '快速',
        chips: [
          SearchFilterChipSpec<BankCard>(
            label: '虚拟卡',
            predicate: (c) => c.isVirtual,
          ),
        ],
      ),
    ],
  );
}

FeatureSearchConfig<WatchedPair> _buildRatesConfig(WidgetRef ref) {
  final pairs =
      ref.read(watchedPairListProvider).value ?? const <WatchedPair>[];
  final bases = pairs.map((p) => p.baseCurrency).toSet().toList()..sort();
  final quotes = pairs.map((p) => p.quoteCurrency).toSet().toList()..sort();
  return FeatureSearchConfig<WatchedPair>(
    feature: SearchFeature.rates,
    items: pairs,
    identityOf: (p) => p.pairKey,
    titleOf: (p) => p.pairKey,
    subtitleOf: (p) => '${p.baseCurrency} → ${p.quoteCurrency}',
    extraFields: (p) => [p.baseCurrency, p.quoteCurrency],
    onTap: (ctx, p) => Navigator.of(ctx).push(
      MaterialPageRoute(builder: (_) => PairDetailPage(pairKey: p.pairKey)),
    ),
    filterGroups: [
      if (bases.length > 1)
        SearchFilterGroup<WatchedPair>(
          title: '基准币种',
          chips: [
            for (final b in bases)
              SearchFilterChipSpec<WatchedPair>(
                label: b,
                predicate: (p) => p.baseCurrency == b,
              ),
          ],
        ),
      if (quotes.length > 1)
        SearchFilterGroup<WatchedPair>(
          title: '报价币种',
          chips: [
            for (final q in quotes)
              SearchFilterChipSpec<WatchedPair>(
                label: q,
                predicate: (p) => p.quoteCurrency == q,
              ),
          ],
        ),
    ],
  );
}

FeatureSearchConfig<DomainEvent> _buildEventsConfig(
  BuildContext context,
  WidgetRef ref,
) {
  return buildEventsConfig(
    ref: ref,
    onTap: (_) {
      context.go('/events');
    },
  );
}

/// 事件 feature 的 config 工厂：暴露出来以便事件页自定义点击回调。
FeatureSearchConfig<DomainEvent> buildEventsConfig({
  required WidgetRef ref,
  required void Function(DomainEvent e) onTap,
}) {
  final list = ref.read(recentEventsProvider).value ?? const <DomainEvent>[];
  final models = list.map((e) => e.relatedModel).toSet().toList()
    ..sort((a, b) => a.code.compareTo(b.code));
  final statuses = list.map((e) => e.status).toSet().toList()
    ..sort((a, b) => a.code.compareTo(b.code));
  final types = list.map((e) => e.eventType).toSet().toList()..sort();
  return FeatureSearchConfig<DomainEvent>(
    feature: SearchFeature.events,
    items: list,
    identityOf: (e) => e.id,
    titleOf: (e) => e.eventType,
    subtitleOf: (e) =>
        '${e.relatedModel.code} · ${e.relatedId}\n${e.triggerTime.toLocal()}',
    isThreeLine: (_) => true,
    extraFields: (e) => [
      e.relatedModel.code,
      e.relatedId,
      e.handler ?? '',
      e.handlingNote ?? '',
    ],
    onTap: (_, e) => onTap(e),
    filterGroups: [
      if (models.isNotEmpty)
        SearchFilterGroup<DomainEvent>(
          title: '关联模型',
          chips: [
            for (final m in models)
              SearchFilterChipSpec<DomainEvent>(
                label: m.code,
                predicate: (e) => e.relatedModel == m,
              ),
          ],
        ),
      if (statuses.isNotEmpty)
        SearchFilterGroup<DomainEvent>(
          title: '状态',
          chips: [
            for (final s in statuses)
              SearchFilterChipSpec<DomainEvent>(
                label: s.code,
                predicate: (e) => e.status == s,
              ),
          ],
        ),
      if (types.length > 1 && types.length <= 12)
        SearchFilterGroup<DomainEvent>(
          title: '事件类型',
          chips: [
            for (final t in types)
              SearchFilterChipSpec<DomainEvent>(
                label: t,
                predicate: (e) => e.eventType == t,
              ),
          ],
        ),
    ],
  );
}
