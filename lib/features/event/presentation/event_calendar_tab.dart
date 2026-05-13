part of 'event_list_page.dart';

// ==============================  事件筛选维度  ==============================

enum _EventFilter {
  all,
  account,
  asset,
  card,
  channel,
  rateAlert,
  highPriority,
  pendingAck,
  failed,
}

extension on _EventFilter {
  String get label => switch (this) {
        _EventFilter.all => '全部',
        _EventFilter.account => '账户',
        _EventFilter.asset => '资产',
        _EventFilter.card => '卡片',
        _EventFilter.channel => '渠道',
        _EventFilter.rateAlert => '汇率预警',
        _EventFilter.highPriority => '仅高优',
        _EventFilter.pendingAck => '待确认',
        _EventFilter.failed => '失败',
      };

  IconData get icon => switch (this) {
        _EventFilter.all => Icons.list_alt_outlined,
        _EventFilter.account => Icons.account_balance_outlined,
        _EventFilter.asset => Icons.show_chart_outlined,
        _EventFilter.card => Icons.credit_card_outlined,
        _EventFilter.channel => Icons.swap_horiz_outlined,
        _EventFilter.rateAlert => Icons.notifications_active_outlined,
        _EventFilter.highPriority => Icons.priority_high,
        _EventFilter.pendingAck => Icons.pending_actions_outlined,
        _EventFilter.failed => Icons.error_outline,
      };

  bool match(DomainEvent e) => switch (this) {
        _EventFilter.all => true,
        _EventFilter.account => e.relatedModel == RelatedModel.account &&
            e.eventType != DomainEventTypes.rateAlert,
        _EventFilter.asset => e.relatedModel == RelatedModel.asset,
        _EventFilter.card => e.relatedModel == RelatedModel.card,
        _EventFilter.channel => e.relatedModel == RelatedModel.channel,
        _EventFilter.rateAlert => e.eventType == DomainEventTypes.rateAlert,
        _EventFilter.highPriority =>
          e.priority == EventPriority.high ||
              e.priority == EventPriority.critical,
        _EventFilter.pendingAck =>
          e.ackRequirement == AckRequirement.required_ &&
              e.ackStatus == AckStatus.pending,
        _EventFilter.failed => e.handlingStatus == HandlingStatus.failed,
      };

  /// Whether this filter shows events across all days (not just the selected day).
  bool get isGlobal => this == _EventFilter.pendingAck || this == _EventFilter.failed;
}

// ==============================  事件排序维度  ==============================

enum _EventSort {
  timeDesc,
  priorityDesc,
  groupedByModel,
}

extension on _EventSort {
  String get label => switch (this) {
        _EventSort.timeDesc => '时间↓',
        _EventSort.priorityDesc => '优先级↓',
        _EventSort.groupedByModel => '按类型',
      };
}

// ==============================  日历 Tab  ==============================

class _CalendarTab extends ConsumerStatefulWidget {
  const _CalendarTab({super.key});

  @override
  ConsumerState<_CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends ConsumerState<_CalendarTab>
    with AutomaticKeepAliveClientMixin {
  late DateTime _visibleMonth;
  late DateTime _selectedDay;
  late DateTime _visibleWeekStart;
  bool _calendarExpanded = false;
  _EventFilter _filter = _EventFilter.all;
  _EventSort _sort = _EventSort.timeDesc;
  final Set<String> _expandedBatches = <String>{};
  bool _batchAcking = false;

  DateTime get selectedDay => _selectedDay;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
    _visibleMonth = DateTime(now.year, now.month, 1);
    _visibleWeekStart = _weekStart(_selectedDay);
  }

  void jumpTo(DateTime t) {
    setState(() {
      _visibleMonth = DateTime(t.year, t.month, 1);
      _selectedDay = DateTime(t.year, t.month, t.day);
      _visibleWeekStart = _weekStart(_selectedDay);
    });
  }

  void _goMonth(int delta) {
    setState(() {
      _visibleMonth =
          DateTime(_visibleMonth.year, _visibleMonth.month + delta, 1);
      final maxDay = _daysInMonth(_visibleMonth);
      if (_selectedDay.day > maxDay || _selectedDay.month != _visibleMonth.month) {
        _selectedDay = DateTime(
          _visibleMonth.year,
          _visibleMonth.month,
          _selectedDay.day.clamp(1, maxDay),
        );
      }
      _visibleWeekStart = _weekStart(_selectedDay);
    });
  }

  void _goWeek(int delta) {
    setState(() {
      _visibleWeekStart =
          _visibleWeekStart.add(Duration(days: delta * 7));
    });
  }

  void _selectDay(DateTime d) {
    setState(() {
      _selectedDay = DateTime(d.year, d.month, d.day);
      _visibleWeekStart = _weekStart(_selectedDay);
    });
  }

  void _toggleExpanded() {
    setState(() {
      _calendarExpanded = !_calendarExpanded;
      if (_calendarExpanded) {
        _visibleMonth =
            DateTime(_visibleWeekStart.year, _visibleWeekStart.month, 1);
      }
    });
  }

  void _showYearPicker() {
    final currentYear = _visibleMonth.year;
    final startYear = currentYear - 4;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GwpColors.surface2,
        title: const Text(
          '选择年份',
          style: TextStyle(color: GwpColors.textPrimary),
        ),
        content: SizedBox(
          width: 280,
          child: GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2,
            children: List.generate(10, (i) {
              final year = startYear + i;
              final isCurrent = year == currentYear;
              return FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor:
                      isCurrent ? GwpColors.actionPrimary : GwpColors.surface3,
                ),
                onPressed: () {
                  setState(() {
                    _visibleMonth = DateTime(year, _visibleMonth.month, 1);
                    final maxDay = _daysInMonth(_visibleMonth);
                    if (_selectedDay.day > maxDay) {
                      _selectedDay = DateTime(year, _visibleMonth.month, maxDay);
                    } else if (_selectedDay.month != _visibleMonth.month) {
                      _selectedDay = DateTime(year, _visibleMonth.month,
                          _selectedDay.day.clamp(1, maxDay));
                    }
                    _visibleWeekStart = _weekStart(_selectedDay);
                  });
                  Navigator.of(ctx).pop();
                },
                child: Text(
                  '$year',
                  style: TextStyle(
                    color: isCurrent ? Colors.white : GwpColors.textPrimary,
                  ),
                ),
              );
            }),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAll(List<DomainEvent> list) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('批量确认'),
        content: Text('将确认当前 ${list.length} 条待处理事件，继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('全部确认'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _batchAcking = true);
    final useCase = ref.read(ackEventUseCaseProvider);
    var ok = 0;
    var fail = 0;
    for (final e in list) {
      final r = await useCase.confirm(e.id);
      r.when(ok: (_) => ok++, err: (_) => fail++);
    }
    if (!mounted) return;
    setState(() => _batchAcking = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(fail == 0 ? '已确认 $ok 条' : '已确认 $ok 条，失败 $fail 条'),
      ),
    );
  }

  static DateTime _weekStart(DateTime d) {
    final wd = d.weekday;
    return DateTime(d.year, d.month, d.day - (wd - 1));
  }

  static int _daysInMonth(DateTime d) =>
      DateTime(d.year, d.month + 1, 0).day;

  String _formatWeekRange(DateTime weekStart) {
    final end = weekStart.add(const Duration(days: 6));
    if (weekStart.month == end.month) {
      return '${weekStart.month}月${weekStart.day}日 - ${end.day}日';
    }
    return '${weekStart.month}月${weekStart.day}日 - ${end.month}月${end.day}日';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final events = ref.watch(recentEventsProvider);
    return events.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: GwpColors.actionPrimary),
      ),
      error: (e, _) => GwpEmptyState.error(
        message: '加载失败: ${errorToMessage(e)}',
        onRetry: () => ref.invalidate(recentEventsProvider),
      ),
      data: (allEvents) {
        final byDay = _groupByDay(allEvents);
        // Global filters ignore the selected day and show all matching events.
        final globalEvents = _filter.isGlobal
            ? allEvents.where((e) => _filter.match(e)).toList()
            : null;

        List<DomainEvent> dayEvents;
        String? headerLabel; // override for _SelectedDayHeader

        if (globalEvents != null) {
          dayEvents = globalEvents;
          // Apply appropriate default sort for global modes
          switch (_filter) {
            case _EventFilter.pendingAck:
              dayEvents.sort((a, b) {
                final ad = a.dueAt;
                final bd = b.dueAt;
                if (ad != null && bd != null) {
                  final c = ad.compareTo(bd);
                  if (c != 0) return c;
                } else if (ad != null) {
                  return -1;
                } else if (bd != null) {
                  return 1;
                }
                return b.triggerTime.compareTo(a.triggerTime);
              });
            case _EventFilter.failed:
              dayEvents.sort(
                  (a, b) => b.triggerTime.compareTo(a.triggerTime));
            case _:
              break;
          }
          headerLabel =
              '${_filter.label} · ${dayEvents.length} 条';
        } else {
          final rawDayEvents =
              byDay[_dayKey(_selectedDay)] ?? const [];
          dayEvents =
              rawDayEvents.where((e) => _filter.match(e)).toList();
          _applySort(dayEvents);
        }

        final groups = _buildBatchGroups(dayEvents);
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _CalendarHeader(
                month: _visibleMonth,
                onPrev: () =>
                    _calendarExpanded ? _goMonth(-1) : _goWeek(-1),
                onNext: () =>
                    _calendarExpanded ? _goMonth(1) : _goWeek(1),
                onToday: () {
                  final now = DateTime.now();
                  setState(() {
                    _visibleMonth = DateTime(now.year, now.month, 1);
                    _selectedDay =
                        DateTime(now.year, now.month, now.day);
                    _visibleWeekStart = _weekStart(_selectedDay);
                    _calendarExpanded = true;
                  });
                },
                expanded: _calendarExpanded,
                onToggleExpanded: _toggleExpanded,
                weekLabel: _calendarExpanded
                    ? null
                    : _formatWeekRange(_visibleWeekStart),
                onLongPressLabel: _showYearPicker,
              ),
            ),
            SliverToBoxAdapter(
              child: HorizontalGestureGuard(
                claimHorizontalDrag: _calendarExpanded,
                swipeThreshold: 72,
                axisLockThreshold: 20,
                horizontalDominanceRatio: 1.4,
                onSwipe: _calendarExpanded
                    ? (direction) {
                        _goMonth(
                          direction == HorizontalSwipeDirection.forward
                              ? 1
                              : -1,
                        );
                      }
                    : null,
                child: _calendarExpanded
                    ? _MonthGrid(
                        visibleMonth: _visibleMonth,
                        selectedDay: _selectedDay,
                        eventsByDay: byDay,
                        onTapDay: _selectDay,
                      )
                    : _WeekStrip(
                        weekStart: _visibleWeekStart,
                        selectedDay: _selectedDay,
                        eventsByDay: byDay,
                        onTapDay: (d) {
                          setState(() {
                            _selectedDay =
                                DateTime(d.year, d.month, d.day);
                          });
                        },
                        onSwipeWeek: (delta) => _goWeek(delta),
                      ),
              ),
            ),
            if (_filter == _EventFilter.pendingAck && dayEvents.isNotEmpty)
              SliverToBoxAdapter(
                child: _BatchConfirmBar(
                  count: dayEvents.length,
                  busy: _batchAcking,
                  onConfirm: () => _confirmAll(dayEvents),
                ),
              ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyFilterDelegate(
                selectedDay: _selectedDay,
                count: dayEvents.length,
                filter: _filter,
                onFilterChanged: (f) => setState(() => _filter = f),
                sort: _sort,
                onSortChanged: (s) => setState(() => _sort = s),
                overriddenLabel: headerLabel,
              ),
            ),
            if (dayEvents.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _filter.isGlobal
                    ? GwpEmptyState(
                        icon: _filter == _EventFilter.pendingAck
                            ? Icons.check_circle_outline
                            : Icons.verified_outlined,
                        title: _filter == _EventFilter.pendingAck
                            ? '没有待确认事件'
                            : '没有失败事件',
                        subtitle: _filter == _EventFilter.pendingAck
                            ? '需要人工确认的事件都已处理完毕'
                            : '所有自动化流程当前状态正常',
                      )
                    : allEvents
                            .where((e) => e.triggerTime
                                .toLocal()
                                .difference(_selectedDay)
                                .inDays ==
                                0)
                            .isEmpty
                        ? _EmptyDayState(day: _selectedDay)
                        : const GwpEmptyState(
                            icon: Icons.filter_alt_outlined,
                            title: '当前筛选下无事件',
                            subtitle: '清除筛选或切换到"全部"查看',
                          ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: GwpSpacing.base,
                ),
                sliver: SliverList.builder(
                  itemCount: groups.length,
                  itemBuilder: (_, i) {
                    final g = groups[i];
                    final gap =
                        i < groups.length - 1 ? GwpSpacing.sm : 0.0;
                    final child = g.events.length == 1
                        ? _EventCard(event: g.events.first)
                        : _BatchCard(
                            group: g,
                            expanded:
                                _expandedBatches.contains(g.batchId),
                            onToggle: () => setState(() {
                              if (_expandedBatches.contains(g.batchId)) {
                                _expandedBatches.remove(g.batchId);
                              } else {
                                _expandedBatches.add(g.batchId);
                              }
                            }),
                          );
                    return Padding(
                      padding: EdgeInsets.only(bottom: gap),
                      child: child,
                    );
                  },
                ),
              ),
            SliverToBoxAdapter(
              child: SizedBox(
                height:
                    FloatingNavLayout.totalFloatingHeight(context) + 24,
              ),
            ),
          ],
        );
      },
    );
  }

  void _applySort(List<DomainEvent> events) {
    switch (_sort) {
      case _EventSort.timeDesc:
        events.sort((a, b) => b.triggerTime.compareTo(a.triggerTime));
      case _EventSort.priorityDesc:
        events.sort((a, b) {
          final pa = a.priority ?? EventPriority.low;
          final pb = b.priority ?? EventPriority.low;
          final cmp = pb.index.compareTo(pa.index);
          if (cmp != 0) return cmp;
          return b.triggerTime.compareTo(a.triggerTime);
        });
      case _EventSort.groupedByModel:
        events.sort((a, b) {
          final ma = a.relatedModel.index;
          final mb = b.relatedModel.index;
          if (ma != mb) return ma.compareTo(mb);
          return b.triggerTime.compareTo(a.triggerTime);
        });
    }
  }

  Map<String, List<DomainEvent>> _groupByDay(List<DomainEvent> list) {
    final map = <String, List<DomainEvent>>{};
    for (final e in list) {
      final k = _dayKey(e.triggerTime.toLocal());
      (map[k] ??= []).add(e);
    }
    for (final v in map.values) {
      v.sort((a, b) => b.triggerTime.compareTo(a.triggerTime));
    }
    return map;
  }
}

String _dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

// ──────────────────────────────────────────────────────────────
// Calendar header
// ──────────────────────────────────────────────────────────────

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.month,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onLongPressLabel,
    this.weekLabel,
  });

  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onLongPressLabel;
  final String? weekLabel;

  @override
  Widget build(BuildContext context) {
    final label = expanded
        ? '${month.year} 年 ${month.month} 月'
        : (weekLabel ?? '${month.year} 年 ${month.month} 月');

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left,
                color: GwpColors.textSecondary),
            onPressed: onPrev,
            tooltip: expanded ? '上个月' : '上一周',
          ),
          Expanded(
            child: GestureDetector(
              onLongPress: onLongPressLabel,
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: GwpColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right,
                color: GwpColors.textSecondary),
            onPressed: onNext,
            tooltip: expanded ? '下个月' : '下一周',
          ),
          IconButton(
            icon: Icon(
              expanded ? Icons.expand_less : Icons.expand_more,
              color: GwpColors.textSecondary,
              size: 20,
            ),
            onPressed: onToggleExpanded,
            tooltip: expanded ? '折叠为周视图' : '展开为月视图',
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: GwpColors.textSecondary,
              side: const BorderSide(color: GwpColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onToday,
            icon: const Icon(Icons.calendar_today_outlined, size: 14),
            label: const Text('今天', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Week strip
// ──────────────────────────────────────────────────────────────

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.weekStart,
    required this.selectedDay,
    required this.eventsByDay,
    required this.onTapDay,
    required this.onSwipeWeek,
  });

  final DateTime weekStart;
  final DateTime selectedDay;
  final Map<String, List<DomainEvent>> eventsByDay;
  final ValueChanged<DateTime> onTapDay;
  final ValueChanged<int> onSwipeWeek;

  static const _dayLabels = ['一', '二', '三', '四', '五', '六', '日'];

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayKey = _dayKey(today);
    final selectedKey = _dayKey(selectedDay);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: HorizontalGestureGuard(
        swipeThreshold: 48,
        onSwipe: (direction) {
          onSwipeWeek(
              direction == HorizontalSwipeDirection.forward ? 1 : -1);
        },
        child: Row(
          children: List.generate(7, (i) {
            final d = weekStart.add(Duration(days: i));
            final key = _dayKey(d);
            final isSelected = key == selectedKey;
            final isToday = key == todayKey;
            final isWeekend = d.weekday == 6 || d.weekday == 7;
            final dayEvents =
                eventsByDay[key] ?? const <DomainEvent>[];
            final modelCounts = <RelatedModel, int>{};
            for (final e in dayEvents) {
              modelCounts[e.relatedModel] =
                  (modelCounts[e.relatedModel] ?? 0) + 1;
            }

            return Expanded(
              child: InkWell(
                onTap: () => onTapDay(d),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected ? GwpColors.actionPrimary : null,
                    borderRadius: BorderRadius.circular(10),
                    border: isToday && !isSelected
                        ? Border.all(
                            color: GwpColors.actionPrimary
                                .withValues(alpha: 0.5),
                          )
                        : null,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _dayLabels[i],
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected
                              ? Colors.white70
                              : isWeekend
                                  ? GwpColors.textMuted.withValues(alpha: 0.5)
                                  : GwpColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${d.day}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isToday || isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : isWeekend
                                  ? GwpColors.textMuted
                                  : GwpColors.textPrimary,
                        ),
                      ),
                      if (modelCounts.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: _ModelDotRow(modelCounts: modelCounts),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Month grid
// ──────────────────────────────────────────────────────────────

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.visibleMonth,
    required this.selectedDay,
    required this.eventsByDay,
    required this.onTapDay,
  });

  final DateTime visibleMonth;
  final DateTime selectedDay;
  final Map<String, List<DomainEvent>> eventsByDay;
  final ValueChanged<DateTime> onTapDay;

  static const _weekdayLabels = ['一', '二', '三', '四', '五', '六', '日'];

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(visibleMonth.year, visibleMonth.month, 1);
    final leading = firstOfMonth.weekday - 1;
    final gridStart = firstOfMonth.subtract(Duration(days: leading));
    final cells = List<DateTime>.generate(
      42,
      (i) => gridStart.add(Duration(days: i)),
    );

    final today = DateTime.now();
    final todayKey = _dayKey(today);
    final selectedKey = _dayKey(selectedDay);

    // Fixed-height grid: 6 rows × cell height
    final cellHeight = (MediaQuery.of(context).size.width - 16) / 7;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Column(
        children: [
          Row(
            children: _weekdayLabels
                .map((l) => Expanded(
                      child: Center(
                        child: Text(
                          l,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: GwpColors.textMuted,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: cellHeight * 6,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 42,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.0,
              ),
              itemBuilder: (_, i) {
                final d = cells[i];
                final key = _dayKey(d);
                final inMonth = d.month == visibleMonth.month;
                final isSelected = key == selectedKey;
                final isToday = key == todayKey;
                final isWeekend =
                    d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;
                final dayEvents =
                    eventsByDay[key] ?? const <DomainEvent>[];
                final modelCounts = <RelatedModel, int>{};
                for (final e in dayEvents) {
                  modelCounts[e.relatedModel] =
                      (modelCounts[e.relatedModel] ?? 0) + 1;
                }
                return _DayCell(
                  day: d,
                  inMonth: inMonth,
                  isSelected: isSelected,
                  isToday: isToday,
                  isWeekend: isWeekend,
                  modelCounts: modelCounts,
                  onTap: () => onTapDay(d),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Day cell
// ──────────────────────────────────────────────────────────────

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.inMonth,
    required this.isSelected,
    required this.isToday,
    required this.isWeekend,
    required this.modelCounts,
    required this.onTap,
  });

  final DateTime day;
  final bool inMonth;
  final bool isSelected;
  final bool isToday;
  final bool isWeekend;
  final Map<RelatedModel, int> modelCounts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = !inMonth
        ? GwpColors.textMuted.withValues(alpha: 0.35)
        : isSelected
            ? Colors.white
            : isWeekend
                ? GwpColors.textMuted
                : GwpColors.textPrimary;
    final bg = isSelected
        ? GwpColors.actionPrimary
        : (isToday
            ? GwpColors.actionPrimary.withValues(alpha: 0.15)
            : Colors.transparent);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: isToday && !isSelected
              ? Border.all(
                  color: GwpColors.actionPrimary.withValues(alpha: 0.5))
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight:
                    isToday || isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (modelCounts.isNotEmpty)
              Positioned(
                bottom: 3,
                child: _ModelDotRow(modelCounts: modelCounts),
              ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Shared model-color dot row (up to 3 colored dots)
// ──────────────────────────────────────────────────────────────

class _ModelDotRow extends StatelessWidget {
  const _ModelDotRow({required this.modelCounts});

  final Map<RelatedModel, int> modelCounts;

  @override
  Widget build(BuildContext context) {
    final sorted = modelCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final display = sorted.take(3).toList();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: display.map((entry) {
        return Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: _modelColor(entry.key),
            shape: BoxShape.circle,
          ),
        );
      }).toList(),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Selected day header
// ──────────────────────────────────────────────────────────────

class _SelectedDayHeader extends StatelessWidget {
  const _SelectedDayHeader({
    required this.day,
    required this.count,
    this.overriddenLabel,
  });
  final DateTime day;
  final int count;
  final String? overriddenLabel;

  @override
  Widget build(BuildContext context) {
    final label = overriddenLabel ??
        '${day.year}-${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Icon(
            overriddenLabel != null
                ? Icons.filter_list_outlined
                : Icons.today_outlined,
            size: 16,
            color: GwpColors.textMuted,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: GwpColors.textPrimary,
              fontFamily: GwpTypo.monoFont,
            ),
          ),
          const Spacer(),
          Text(
            '$count 条事件',
            style: const TextStyle(
              fontSize: 12,
              color: GwpColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Filter & sort row
// ──────────────────────────────────────────────────────────────

class _FilterChipRow extends StatelessWidget {
  const _FilterChipRow({
    required this.current,
    required this.onChanged,
    required this.sort,
    required this.onSortChanged,
  });
  final _EventFilter current;
  final ValueChanged<_EventFilter> onChanged;
  final _EventSort sort;
  final ValueChanged<_EventSort> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: Row(
        children: [
          Expanded(
            child: HorizontalGestureGuard(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: GwpSpacing.base),
                itemCount: _EventFilter.values.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final f = _EventFilter.values[i];
                  final selected = f == current;
                  return FilterChip(
                    label: Text(f.label),
                    avatar: Icon(
                      f.icon,
                      size: 14,
                      color: selected ? Colors.white : GwpColors.textSecondary,
                    ),
                    selected: selected,
                    showCheckmark: false,
                    onSelected: (_) => onChanged(f),
                    selectedColor: GwpColors.actionPrimary,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: selected ? Colors.white : GwpColors.textSecondary,
                    ),
                    backgroundColor: GwpColors.surface2,
                    side: BorderSide(
                      color: selected
                          ? GwpColors.actionPrimary
                          : GwpColors.border,
                      width: 0.5,
                    ),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () {
                  final next = _EventSort.values[
                      (sort.index + 1) % _EventSort.values.length];
                  onSortChanged(next);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: GwpColors.surface2,
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: GwpColors.border, width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sort,
                          size: 14, color: GwpColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        sort.label,
                        style: const TextStyle(
                          fontSize: 11,
                          color: GwpColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Sticky filter header delegate
// ──────────────────────────────────────────────────────────────

class _StickyFilterDelegate extends SliverPersistentHeaderDelegate {
  _StickyFilterDelegate({
    required this.selectedDay,
    required this.count,
    required this.filter,
    required this.onFilterChanged,
    required this.sort,
    required this.onSortChanged,
    this.overriddenLabel,
  });

  final DateTime selectedDay;
  final int count;
  final _EventFilter filter;
  final ValueChanged<_EventFilter> onFilterChanged;
  final _EventSort sort;
  final ValueChanged<_EventSort> onSortChanged;
  final String? overriddenLabel;

  static const _headerHeight = 66.0;

  @override
  double get minExtent => _headerHeight;

  @override
  double get maxExtent => _headerHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: GwpColors.canvas,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SelectedDayHeader(
            day: selectedDay,
            count: count,
            overriddenLabel: overriddenLabel,
          ),
          _FilterChipRow(
            current: filter,
            onChanged: onFilterChanged,
            sort: sort,
            onSortChanged: onSortChanged,
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_StickyFilterDelegate old) =>
      old.selectedDay != selectedDay ||
      old.count != count ||
      old.filter != filter ||
      old.sort != sort ||
      old.overriddenLabel != overriddenLabel;
}

// ──────────────────────────────────────────────────────────────
// Batch confirm bar (pending ack mode)
// ──────────────────────────────────────────────────────────────

class _BatchConfirmBar extends StatelessWidget {
  const _BatchConfirmBar({
    required this.count,
    required this.busy,
    required this.onConfirm,
  });

  final int count;
  final bool busy;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: GwpSpacing.base,
        vertical: GwpSpacing.sm,
      ),
      color: GwpColors.warningBg,
      child: Row(
        children: [
          const Icon(Icons.pending_actions_outlined,
              size: 16, color: GwpColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '共 $count 条待确认',
              style: const TextStyle(
                fontSize: 12,
                color: GwpColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: GwpColors.warning,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: busy ? null : onConfirm,
            icon: busy
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: GwpColors.warning,
                    ),
                  )
                : const Icon(Icons.done_all, size: 16),
            label: const Text('全部确认', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Empty day state
// ──────────────────────────────────────────────────────────────

class _EmptyDayState extends StatelessWidget {
  const _EmptyDayState({required this.day});
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final dayStr = '${day.year}-${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined,
                size: 48, color: GwpColors.textMuted),
            const SizedBox(height: 16),
            const Text(
              '当日无事件',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: GwpColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '选择其他日期查看',
              style: TextStyle(
                fontSize: 13,
                color: GwpColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: GwpColors.actionPrimary,
              ),
              onPressed: () => context.push('/events/new?day=$dayStr'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('新建事件'),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Helpers: event colors
// ──────────────────────────────────────────────────────────────

Color _modelColor(RelatedModel m) => switch (m) {
      RelatedModel.account => const Color(0xFF64748B),
      RelatedModel.asset => const Color(0xFF22C55E),
      RelatedModel.card => const Color(0xFFEC4899),
      RelatedModel.channel => const Color(0xFFF59E0B),
    };

IconData _modelIcon(RelatedModel m) => switch (m) {
      RelatedModel.account => Icons.account_balance_outlined,
      RelatedModel.asset => Icons.show_chart_outlined,
      RelatedModel.card => Icons.credit_card_outlined,
      RelatedModel.channel => Icons.swap_horiz_outlined,
    };

double _priorityAlpha(EventPriority? p) => switch (p) {
      EventPriority.critical => 1.0,
      EventPriority.high => 0.85,
      EventPriority.medium => 0.65,
      EventPriority.low => 0.45,
      null => 0.55,
    };

(String, Color)? _dueStateText(DateTime? dueAt) {
  if (dueAt == null) return null;
  final now = DateTime.now();
  final due = dueAt.toLocal();
  final diff = due.difference(now);
  if (diff.isNegative) {
    final days = (-diff).inDays;
    return (days == 0 ? '已逾期' : '逾期$days天', GwpColors.negative);
  }
  if (diff.inDays == 0) return ('今日到期', GwpColors.warning);
  if (diff.inDays <= 3) return ('${diff.inDays}天内到期', GwpColors.warning);
  return null;
}

// ──────────────────────────────────────────────────────────────
// Event card
// ──────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final DomainEvent event;

  @override
  Widget build(BuildContext context) {
    final baseColor = _modelColor(event.relatedModel);
    final accent = baseColor.withValues(alpha: _priorityAlpha(event.priority));
    final isHighPri = event.priority == EventPriority.critical ||
        event.priority == EventPriority.high;
    final pendingReq = event.ackRequirement == AckRequirement.required_ &&
        event.ackStatus == AckStatus.pending;
    final failed = event.handlingStatus == HandlingStatus.failed;
    final dueInfo = _dueStateText(event.dueAt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          useRootNavigator: true,
          builder: (_) => _EventDetailSheet(event: event),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: GwpColors.surface1,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: pendingReq
                  ? GwpColors.warning.withValues(alpha: 0.6)
                  : GwpColors.border,
              width: pendingReq ? 1.0 : 0.5,
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: GwpSpacing.md),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: GwpSpacing.md),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          _modelIcon(event.relatedModel),
                          size: 18,
                          color: accent,
                        ),
                      ),
                      if (isHighPri)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: event.priority == EventPriority.critical
                                  ? GwpColors.negative
                                  : GwpColors.warning,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: GwpColors.surface1,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: GwpSpacing.md),
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: GwpSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          event.eventType,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: GwpColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '${event.relatedModel.labelZh} · ${_fmtDayTime(event.triggerTime)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: GwpColors.textMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (dueInfo != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: dueInfo.$2.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  dueInfo.$1,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: dueInfo.$2,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: GwpSpacing.sm),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: GwpSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _eventStatusBadge(event.status),
                      if (failed) ...[
                        const SizedBox(height: 4),
                        const GwpStatusBadge(
                          label: 'FAILED',
                          variant: StatusVariant.negative,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: GwpSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _fmtDayTime(DateTime t) {
  final l = t.toLocal();
  final now = DateTime.now();
  String p(int n) => n.toString().padLeft(2, '0');
  if (l.year == now.year && l.month == now.month && l.day == now.day) {
    return '${p(l.hour)}:${p(l.minute)}';
  }
  return '${p(l.month)}-${p(l.day)} ${p(l.hour)}:${p(l.minute)}';
}

// ──────────────────────────────────────────────────────────────
// Batch card
// ──────────────────────────────────────────────────────────────

class _BatchCard extends StatelessWidget {
  const _BatchCard({
    required this.group,
    required this.expanded,
    required this.onToggle,
  });

  final _BatchGroup group;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final dominantModel = _dominantModel(group.events);
    final accent = _modelColor(dominantModel);
    final pendingCount = group.events
        .where((e) =>
            e.ackRequirement == AckRequirement.required_ &&
            e.ackStatus == AckStatus.pending)
        .length;
    final typeLabel = _summaryLabel(group.events);
    return Container(
      decoration: BoxDecoration(
        color: GwpColors.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: pendingCount > 0
              ? GwpColors.warning.withValues(alpha: 0.6)
              : GwpColors.border,
          width: pendingCount > 0 ? 1.0 : 0.5,
        ),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onToggle,
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: GwpSpacing.md),
                    Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.symmetric(
                          vertical: GwpSpacing.md),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '×${group.events.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: GwpSpacing.md),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: GwpSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              typeLabel,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: GwpColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '批次 · ${_shortBatch(group.batchId)}'
                              '${pendingCount > 0 ? " · 待确认 $pendingCount" : ""}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: GwpColors.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      color: GwpColors.textSecondary,
                    ),
                    const SizedBox(width: GwpSpacing.md),
                  ],
                ),
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1, color: GwpColors.border),
            ...group.events.map(
              (e) => Padding(
                padding: const EdgeInsets.fromLTRB(GwpSpacing.sm,
                    GwpSpacing.xs, GwpSpacing.sm, GwpSpacing.xs),
                child: _EventCard(event: e),
              ),
            ),
            const SizedBox(height: GwpSpacing.xs),
          ],
        ],
      ),
    );
  }

  RelatedModel _dominantModel(List<DomainEvent> list) {
    final counts = <RelatedModel, int>{};
    for (final e in list) {
      counts[e.relatedModel] = (counts[e.relatedModel] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  String _summaryLabel(List<DomainEvent> list) {
    final types = <String>{for (final e in list) e.eventType};
    if (types.length == 1) return '${list.first.eventType}（${list.length}）';
    return '${list.first.eventType} 等 ${types.length} 类 · 共 ${list.length}';
  }

  String _shortBatch(String id) {
    if (id.length <= 8) return id;
    return id.substring(0, 8);
  }
}

Widget _eventStatusBadge(EventStatus status) {
  final (label, variant) = switch (status) {
    EventStatus.pending => ('PENDING', StatusVariant.neutral),
    EventStatus.triggered => ('TRIGGERED', StatusVariant.warning),
    EventStatus.resolved => ('RESOLVED', StatusVariant.positive),
    EventStatus.closed => ('CLOSED', StatusVariant.muted),
  };
  return GwpStatusBadge(label: label, variant: variant);
}

// ──────────────────────────────────────────────────────────────
// Batch group
// ──────────────────────────────────────────────────────────────

class _BatchGroup {
  _BatchGroup({required this.batchId, required this.events});
  final String batchId;
  final List<DomainEvent> events;
}

List<_BatchGroup> _buildBatchGroups(List<DomainEvent> events) {
  final map = <String, _BatchGroup>{};
  final ordered = <String>[];
  var singletonCursor = 0;
  for (final e in events) {
    final bid = (e.batchId ?? '').isEmpty
        ? '__single_${singletonCursor++}'
        : e.batchId!;
    final g = map[bid];
    if (g == null) {
      map[bid] = _BatchGroup(batchId: bid, events: [e]);
      ordered.add(bid);
    } else {
      g.events.add(e);
    }
  }
  return ordered.map((k) => map[k]!).toList();
}

// ──────────────────────────────────────────────────────────────
// Event detail sheet
// ──────────────────────────────────────────────────────────────

class _EventDetailSheet extends ConsumerWidget {
  const _EventDetailSheet({required this.event});

  final DomainEvent event;

  static const _modelRoutePrefix = <RelatedModel, String>{
    RelatedModel.account: '/accounts',
    RelatedModel.asset: '/assets',
    RelatedModel.channel: '/channels',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final note = _prettyJson(event.handlingNote);
    final routePrefix = _modelRoutePrefix[event.relatedModel];
    final isRateAlert = event.eventType == DomainEventTypes.rateAlert;
    final canOpen = isRateAlert ||
        event.relatedModel == RelatedModel.card ||
        (routePrefix != null && event.relatedId.isNotEmpty);
    Future<void> openRelated() async {
      final nav = Navigator.of(context);
      if (isRateAlert && event.relatedId.isNotEmpty) {
        nav.pop();
        if (!context.mounted) return;
        await Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (_) => PairDetailPage(pairKey: event.relatedId),
          ),
        );
      } else if (event.relatedModel == RelatedModel.card) {
        final cardRepo = ref.read(cardRepositoryProvider);
        final accRepo = ref.read(accountRepositoryProvider);
        final card = (await cardRepo.findById(event.relatedId)).valueOrNull;
        if (card == null) {
          nav.pop();
          return;
        }
        final account = (await accRepo.findById(card.accountId)).valueOrNull;
        nav.pop();
        if (!context.mounted) return;
        await CardDetailSheet.show(context, card: card, account: account);
      } else if (routePrefix != null) {
        nav.pop();
        if (!context.mounted) return;
        context.push('$routePrefix/${event.relatedId}');
      }
    }

    final dueInfo = _dueStateText(event.dueAt);
    final refs = event.refs ?? const <String, String>{};

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 4,
          bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: GwpColors.surface3,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      _modelIcon(event.relatedModel),
                      size: 20,
                      color: GwpColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.eventType, style: textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          _fmtFull(event.triggerTime),
                          style: const TextStyle(
                            fontSize: 12,
                            color: GwpColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _eventStatusBadge(event.status),
                  IconButton(
                    tooltip: '删除事件',
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: Theme.of(context).colorScheme.error,
                    onPressed: () => _confirmDelete(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (event.priority != null)
                    _MetaChip(
                      icon: Icons.flag_outlined,
                      label: '优先级 · ${event.priority!.code}',
                      emphasis: event.priority == EventPriority.critical ||
                          event.priority == EventPriority.high,
                    ),
                  if (event.handlingStatus != null)
                    _MetaChip(
                      icon: Icons.build_circle_outlined,
                      label: '处理 · ${event.handlingStatus!.code}',
                      emphasis: event.handlingStatus == HandlingStatus.failed,
                    ),
                  if ((event.handler ?? '').isNotEmpty)
                    _MetaChip(
                      icon: Icons.person_outline,
                      label: '执行 · ${event.handler}',
                    ),
                  if (event.ackRequirement != AckRequirement.notApplicable)
                    _MetaChip(
                      icon: _ackIcon(event.ackStatus),
                      label:
                          '${event.ackRequirement.labelZh} · ${event.ackStatus.labelZh}',
                      emphasis: event.ackRequirement ==
                              AckRequirement.required_ &&
                          event.ackStatus == AckStatus.pending,
                    ),
                  if (dueInfo != null)
                    _MetaChip(
                      icon: Icons.schedule,
                      label: dueInfo.$1,
                      emphasis: true,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _KvRow(
                  label: '关联模型', value: event.relatedModel.labelBilingual),
              _KvRow(
                label: '关联 ID',
                value: event.relatedId,
                copyable: true,
                trailing: !canOpen
                    ? null
                    : TextButton.icon(
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('打开'),
                        onPressed: openRelated,
                      ),
              ),
              _KvRow(label: '事件 ID', value: event.id, copyable: true),
              if (event.dueAt != null)
                _KvRow(label: '截止时间', value: _fmtFull(event.dueAt!)),
              if ((event.batchId ?? '').isNotEmpty)
                _KvRow(
                    label: '批次 ID',
                    value: event.batchId!,
                    copyable: true),
              _KvRow(label: '创建时间', value: _fmtFull(event.createdAt)),
              _KvRow(label: '更新时间', value: _fmtFull(event.updatedAt)),
              if ((event.ackNote ?? '').isNotEmpty)
                _KvRow(label: '确认备注', value: event.ackNote!),
              if (refs.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  '辅助关联',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: GwpColors.actionPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                _RefChips(refs: refs),
              ],
              if (_canRetry(event)) ...[
                const SizedBox(height: 16),
                _RetryButton(event: event),
              ],
              if (event.ackRequirement != AckRequirement.notApplicable) ...[
                const SizedBox(height: 16),
                _AckBar(event: event),
              ],
              if (note != null) ...[
                const SizedBox(height: 12),
                const Text(
                  '处理备注',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: GwpColors.actionPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: GwpColors.surface2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: GwpColors.border, width: 0.5),
                  ),
                  child: SelectableText(
                    note,
                    style: const TextStyle(
                      fontFamily: GwpTypo.monoFont,
                      fontSize: 12,
                      height: 1.4,
                      color: GwpColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _fmtFull(DateTime t) {
    final l = t.toLocal();
    String p(int n) => n.toString().padLeft(2, '0');
    return '${l.year}-${p(l.month)}-${p(l.day)} ${p(l.hour)}:${p(l.minute)}:${p(l.second)}';
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('删除事件'),
        content: Text(
          '将删除事件「${event.eventType}」。删除后该事件不再出现在列表与'
          '日历中，相关联的业务数据不受影响。',
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
    if (confirmed != true || !context.mounted) return;
    final r = await ref.read(eventRepositoryProvider).softDelete(event.id);
    if (!context.mounted) return;
    r.when(
      ok: (_) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已删除事件')),
        );
      },
      err: (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败: ${errorToMessage(e)}')),
      ),
    );
  }

  String? _prettyJson(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[event] payload JSON parse failed: ${e.runtimeType}');
      }
      return raw;
    }
  }
}

// ──────────────────────────────────────────────────────────────
// Ref chips
// ──────────────────────────────────────────────────────────────

class _RefChips extends StatelessWidget {
  const _RefChips({required this.refs});
  final Map<String, String> refs;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: refs.entries.map((e) {
        final parsed = _parseRef(e.value);
        final canJump = parsed != null && parsed.$1 != RelatedModel.card;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: canJump
                ? () {
                    final prefix =
                        _EventDetailSheet._modelRoutePrefix[parsed.$1];
                    if (prefix == null) return;
                    final nav = Navigator.of(context);
                    final target = '$prefix/${parsed.$2}';
                    nav.pop();
                    context.push(target);
                  }
                : () => Clipboard.setData(ClipboardData(text: e.value)),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: GwpColors.surface3,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: GwpColors.border, width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${e.key}:',
                    style: const TextStyle(
                      fontSize: 11,
                      color: GwpColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    e.value,
                    style: const TextStyle(
                      fontSize: 11,
                      color: GwpColors.textPrimary,
                      fontFamily: GwpTypo.monoFont,
                    ),
                  ),
                  if (canJump) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.open_in_new,
                        size: 12, color: GwpColors.textMuted),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  (RelatedModel, String)? _parseRef(String raw) {
    final i = raw.indexOf(':');
    if (i <= 0 || i == raw.length - 1) return null;
    final mcode = raw.substring(0, i).toUpperCase();
    final id = raw.substring(i + 1);
    try {
      return (RelatedModel.fromCode(mcode), id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[event] unknown RelatedModel code: $mcode');
      }
      return null;
    }
  }
}

class _KvRow extends StatelessWidget {
  const _KvRow({
    required this.label,
    required this.value,
    this.copyable = false,
    this.trailing,
  });

  final String label;
  final String value;
  final bool copyable;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: GwpColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: copyable
                ? SelectableText(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      color: GwpColors.textPrimary,
                    ),
                  )
                : Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      color: GwpColors.textPrimary,
                    ),
                  ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    this.emphasis = false,
  });
  final IconData icon;
  final String label;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final bg = emphasis ? GwpColors.negativeBg : GwpColors.surface3;
    final fg = emphasis ? GwpColors.negative : GwpColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

IconData _ackIcon(AckStatus s) => switch (s) {
      AckStatus.pending => Icons.pending_outlined,
      AckStatus.confirmed => Icons.check_circle_outline,
      AckStatus.dismissed => Icons.do_not_disturb_on_outlined,
    };

bool _canRetry(DomainEvent e) =>
    e.handlingStatus == HandlingStatus.failed &&
    e.eventType == DomainEventTypes.assetValuationFailed &&
    e.relatedModel == RelatedModel.asset &&
    e.relatedId.isNotEmpty;

// ──────────────────────────────────────────────────────────────
// Retry button
// ──────────────────────────────────────────────────────────────

class _RetryButton extends ConsumerStatefulWidget {
  const _RetryButton({required this.event});
  final DomainEvent event;

  @override
  ConsumerState<_RetryButton> createState() => _RetryButtonState();
}

class _RetryButtonState extends ConsumerState<_RetryButton> {
  bool _busy = false;

  Future<void> _retry() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      final useCase = ref.read(refreshAssetPriceUseCaseProvider);
      final res = await useCase.refreshLatest(widget.event.relatedId);
      if (!mounted) return;
      if (res.isOk) {
        await ref.read(eventRepositoryProvider).updateHandling(
              id: widget.event.id,
              status: HandlingStatus.handled,
              note: 'retry_success',
            );
        if (!mounted) return;
        nav.pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('重试成功，已刷新最新估值')),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text('重试失败：${errorToMessage(res.errorOrNull)}'),
            backgroundColor: GwpColors.negative,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _busy ? null : _retry,
        icon: _busy
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.refresh, size: 18),
        label: Text(_busy ? '重试中…' : '重试刷新估值'),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Ack bar
// ──────────────────────────────────────────────────────────────

class _AckBar extends ConsumerStatefulWidget {
  const _AckBar({required this.event});
  final DomainEvent event;

  @override
  ConsumerState<_AckBar> createState() => _AckBarState();
}

class _AckBarState extends ConsumerState<_AckBar> {
  bool _busy = false;

  Future<void> _act(bool confirm) async {
    final note = await _askNote(context, confirm: confirm);
    if (note == null) return;
    setState(() => _busy = true);
    final useCase = ref.read(ackEventUseCaseProvider);
    final r = confirm
        ? await useCase.confirm(widget.event.id,
            note: note.isEmpty ? null : note)
        : await useCase.dismiss(widget.event.id,
            note: note.isEmpty ? null : note);
    if (!mounted) return;
    setState(() => _busy = false);
    r.when(
      ok: (_) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(confirm ? '已确认' : '已忽略')),
        );
      },
      err: (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: ${errorToMessage(e)}')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    if (e.ackStatus != AckStatus.pending) {
      final ts = e.ackAt == null ? '' : ' · ${_fmtShort(e.ackAt!)}';
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: GwpColors.surface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: GwpColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(_ackIcon(e.ackStatus),
                size: 18, color: GwpColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${e.ackStatus == AckStatus.confirmed ? '已确认' : '已忽略'}$ts',
                style: const TextStyle(color: GwpColors.textPrimary),
              ),
            ),
          ],
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _busy ? null : () => _act(false),
            icon: const Icon(Icons.do_not_disturb_alt_outlined, size: 18),
            label: const Text('忽略'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: _busy ? null : () => _act(true),
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check, size: 18),
            label: const Text('确认'),
          ),
        ),
      ],
    );
  }

  Future<String?> _askNote(BuildContext context,
      {required bool confirm}) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(confirm ? '确认事件' : '忽略事件'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: '备注（可选）',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, ctrl.text.trim()),
            child: Text(confirm ? '确认' : '忽略'),
          ),
        ],
      ),
    );
  }

  String _fmtShort(DateTime t) {
    final l = t.toLocal();
    String p(int n) => n.toString().padLeft(2, '0');
    return '${l.year}-${p(l.month)}-${p(l.day)} ${p(l.hour)}:${p(l.minute)}';
  }
}
