import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/app_top_bar.dart';
import '../../../core/ui/design_tokens.dart';
import '../../../core/ui/enum_labels.dart';
import '../../../core/ui/error_localizer.dart';
import '../../../core/ui/floating_nav_layout.dart';
import '../../../core/ui/global_search_delegate.dart';
import '../../../core/ui/gwp_donut_chart.dart';
import '../../../core/ui/gwp_empty_state.dart';
import '../../../core/ui/gwp_kpi_tile.dart';
import '../../../core/ui/gwp_node_map.dart';
import '../../../core/ui/gwp_status_badge.dart';
import '../../../core/ui/horizontal_swipe_action.dart';
import '../../../core/ui/region_meta.dart';
import '../../../core/ui/top_search_action.dart';
import '../../../domain/entities/domain_event.dart';
import '../../../domain/entities/event_enums.dart';
import 'dashboard_providers.dart';
import '../../../data/providers/dict_providers.dart';

part 'parts/dashboard_hero.dart';
part 'parts/dashboard_kpi.dart';
part 'parts/dashboard_allocation.dart';
part 'parts/dashboard_trend.dart';
part 'parts/dashboard_bills_map.dart';
part 'parts/dashboard_activity.dart';

final dashboardRefreshProviders = <dynamic>[
  dashboardSummaryProvider,
  dashboardKpiProvider,
  allocationByCurrencyProvider,
  allocationByTypeProvider,
  allocationByRegionProvider,
  nodeMapDataProvider,
  netWorthTrendProvider,
  trendDeltaProvider,
  upcomingBillsProvider,
  recentActivitiesProvider,
  todaysRateAlertsProvider,
];

void invalidateDashboardProviders(WidgetRef ref) {
  for (final provider in dashboardRefreshProviders) {
    ref.invalidate(provider);
  }
}

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  late final HorizontalSwipeAction _horizontalSwipeAction;
  late final TopSearchOpener _topSearchOpener;

  @override
  void initState() {
    super.initState();
    _horizontalSwipeAction = ref.read(horizontalSwipeActionProvider.notifier);
    _topSearchOpener = ref.read(topSearchOpenerProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _horizontalSwipeAction.set(this, null);
      _topSearchOpener.set(this, _openSearch);
    });
  }

  @override
  void dispose() {
    _topSearchOpener.clearLater(this);
    _horizontalSwipeAction.clearLater(this);
    super.dispose();
  }

  void _openSearch() {
    openGlobalSearch(
      context: context,
      ref: ref,
      current: SearchFeature.dashboard,
    );
  }

  void _invalidateAll() {
    invalidateDashboardProviders(ref);
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(dashboardSummaryProvider);
    return Scaffold(
      appBar: const AppTopBar(title: Text('仪表盘'), showAppIcon: true),
      body: RefreshIndicator(
        color: GwpColors.actionPrimary,
        backgroundColor: GwpColors.surface2,
        onRefresh: () async => _invalidateAll(),
        child: summary.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: GwpColors.actionPrimary),
          ),
          error: (e, _) => ListView(
            children: [
              const SizedBox(height: 80),
              GwpEmptyState.error(
                message: '加载失败: ${errorToMessage(e)}',
                onRetry: () => ref.invalidate(dashboardSummaryProvider),
              ),
            ],
          ),
          data: (s) => ListView(
            padding: const EdgeInsets.all(GwpSpacing.base),
            children: [
              // A. Hero: Grid World Map
              const _GridMapHero(),
              const SizedBox(height: GwpSpacing.md),

              // B+. Today's rate alerts（紧贴 Hero，作为第一视觉焦点）
              const _TodaysAlertsBanner(),

              // B. KPI（账户 / 卡片 / 待处理事件）
              _KpiGrid(
                summary: s,
                onAccountsTap: () => context.go('/holdings?tab=0'),
                onCardsTap: () => context.go('/cards'),
                onEventsTap: () => context.go('/events'),
              ),
              const SizedBox(height: GwpSpacing.md),

              // C. Asset Allocation（标题内嵌于卡片顶部）
              const _AllocationSection(),
              const SizedBox(height: GwpSpacing.md),

              // D. Net Worth Trend（标题 + 范围 chip 内嵌于卡片顶部）
              const _TrendSection(),
              const SizedBox(height: GwpSpacing.lg),

              // E. Upcoming credit bills（仅在有数据时渲染）
              const _UpcomingBillsSection(),

              // F. Recent activity（最多 3 条 + 查看全部）
              const _RecentActivitySection(),
              SizedBox(
                height: FloatingNavLayout.totalFloatingHeight(context) + 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
