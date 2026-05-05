import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/app_top_bar.dart';
import '../../../core/ui/design_tokens.dart';
import '../../../core/ui/error_localizer.dart';
import '../../../core/ui/global_search_delegate.dart';
import '../../../core/ui/top_search_action.dart';
import '../../../domain/valuation/asset_valuator.dart';
import '../../account/presentation/account_list_page.dart';
import '../../asset/presentation/asset_list_page.dart';
import '../../asset/presentation/asset_providers.dart';
import '../../channel/presentation/transfer_simulate_page.dart';
import 'portfolio_analysis_body.dart';

/// Merged main page grouping tightly-coupled entities:
/// 账户 (Account) ← 资产 (Asset) 绑定账户 / 转账 (Transfer) 在账户之间移动资金。
class HoldingsPage extends ConsumerStatefulWidget {
  const HoldingsPage({super.key, this.initialTab});

  final int? initialTab;

  @override
  ConsumerState<HoldingsPage> createState() => _HoldingsPageState();
}

class _HoldingsPageState extends ConsumerState<HoldingsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    final initial = (widget.initialTab ?? 0).clamp(0, 3);
    _tab = TabController(length: 4, vsync: this, initialIndex: initial)
      ..addListener(() {
        if (mounted) {
          setState(() {}); // rebuild AppBar/FAB per active tab
          _syncTopSearch(); // 转账 tab 走全局搜索，其它 tab 各自模块优先
        }
      });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncTopSearch();
    });
  }

  @override
  void dispose() {
    ref.read(topSearchOpenerProvider.notifier).set(null);
    _tab.dispose();
    super.dispose();
  }

  void _syncTopSearch() {
    final idx = _tab.index;
    ref
        .read(topSearchOpenerProvider.notifier)
        .set(() => _openSearch(context, idx));
  }

  @override
  Widget build(BuildContext context) {
    final idx = _tab.index;
    return Scaffold(
      appBar: AppTopBar(
        title: const Text('资金'),
        showAppIcon: true,
        actions: _actionsFor(context, idx),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: '账户'),
            Tab(text: '资产'),
            Tab(text: '转账'),
            Tab(text: '分析'),
          ],
        ),
      ),
      floatingActionButton: _fabFor(context, idx),
      body: TabBarView(
        controller: _tab,
        children: const [
          AccountListBody(),
          AssetListBody(),
          TransferSimulateBody(),
          PortfolioAnalysisBody(),
        ],
      ),
    );
  }

  List<Widget> _actionsFor(BuildContext context, int idx) {
    // 搜索按钮已上提至一级 Bar（由 [topSearchOpenerProvider] 动态显示）。
    // 备份 / 恢复是 App 级全局能力，统一放到「设置」，不在本页显示。
    if (idx == 2) {
      return [
        IconButton(
          tooltip: '通道管理',
          icon: const Icon(Icons.swap_horiz_outlined),
          onPressed: () => context.push('/channels'),
        ),
      ];
    }
    // 账户 / 资产 / 分析 tab 共用「同步资产行情」入口：
    // 调 `RefreshAssetPriceUseCase.refreshAll`，与汇率页一致的增量 / 全量选择。
    return [
      PopupMenuButton<SyncMode>(
        tooltip: '同步资产行情',
        enabled: !_refreshing,
        onSelected: (mode) => _refreshAssets(mode),
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: SyncMode.incremental,
            child: Row(
              children: [
                Icon(Icons.trending_up_outlined, size: 18),
                SizedBox(width: 8),
                Text('增量同步（仅最新）'),
              ],
            ),
          ),
          PopupMenuItem(
            value: SyncMode.full,
            child: Row(
              children: [
                Icon(Icons.timeline_outlined, size: 18),
                SizedBox(width: 8),
                Text('全量同步（近 30 日）'),
              ],
            ),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _refreshing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: GwpColors.actionPrimary,
                  ),
                )
              : const Icon(Icons.sync),
        ),
      ),
    ];
  }

  Future<void> _refreshAssets(SyncMode mode) async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    final useCase = ref.read(refreshAssetPriceUseCaseProvider);
    final r = await useCase.refreshAll(mode: mode);
    if (!mounted) return;
    setState(() => _refreshing = false);
    r.when(
      ok: (res) {
        final label = mode == SyncMode.incremental ? '增量' : '全量';
        final msg = res.success.isEmpty && res.failed.isEmpty
            ? '当前没有可同步的资产'
            : '$label同步成功 ${res.success.length} 项'
                '${res.failed.isEmpty ? '' : '，失败 ${res.failed.length} 项'}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      },
      err: (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('刷新失败：${errorToMessage(e)}')),
        );
      },
    );
  }

  Future<void> _openSearch(BuildContext context, int idx) async {
    await openGlobalSearch(
      context: context,
      ref: ref,
      current: switch (idx) {
        0 => SearchFeature.accounts,
        1 => SearchFeature.assets,
        _ => SearchFeature.dashboard, // 转账/分析 tab：无专属列表，直接全局搜索
      },
    );
  }

  Widget? _fabFor(BuildContext context, int idx) {
    switch (idx) {
      case 0:
        return FloatingActionButton.extended(
          onPressed: () => context.push('/accounts/new'),
          icon: const Icon(Icons.add),
          label: const Text('新建账户'),
        );
      case 1:
        return FloatingActionButton.extended(
          onPressed: () => context.push('/assets/new'),
          icon: const Icon(Icons.add),
          label: const Text('新建资产'),
        );
      default:
        return null; // transfer tab: 无 FAB（页面内有 "模拟报价" 按钮）
    }
  }
}
