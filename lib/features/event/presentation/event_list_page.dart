import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/widgets/app_top_bar.dart';
import '../../../core/ui/design_tokens.dart';
import '../../../core/ui/enum_labels.dart';
import '../../../core/ui/error_localizer.dart';
import '../../../core/ui/floating_nav_layout.dart';
import '../../search/presentation/global_search_delegate.dart';
import '../../../core/ui/coffer_empty_state.dart';
import '../../../core/ui/coffer_status_badge.dart';
import '../../../core/ui/horizontal_gesture_guard.dart';
import '../../../core/ui/horizontal_swipe_action.dart';
import '../../../core/ui/top_search_action.dart';
import '../../../domain/entities/domain_event.dart';
import '../../../domain/entities/event_enums.dart';
import '../../../domain/events/event_bus.dart';
import '../../account/presentation/account_providers.dart';
import '../../asset/presentation/asset_providers.dart';
import '../../card/presentation/card_detail_sheet.dart';
import '../../card/presentation/card_providers.dart';
import '../../exchange_rate/presentation/pair_detail_page.dart';
import 'event_providers.dart';

part 'event_calendar_tab.dart';

class EventListPage extends ConsumerStatefulWidget {
  const EventListPage({super.key});

  @override
  ConsumerState<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends ConsumerState<EventListPage> {
  late final HorizontalSwipeAction _horizontalSwipeAction;
  late final TopSearchOpener _topSearchOpener;

  @override
  void initState() {
    super.initState();
    _horizontalSwipeAction = ref.read(horizontalSwipeActionProvider.notifier);
    _topSearchOpener = ref.read(topSearchOpenerProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // No internal tabs — let shell swipe handle horizontal navigation.
      _horizontalSwipeAction.set(this, null);
      _topSearchOpener.set(this, _openSearch);
      unawaited(() async {
        try {
          await ref.read(checkAssetSyncOutdatedUseCaseProvider).call();
        } catch (e, st) {
          debugPrint('[event_list] checkAssetSyncOutdated failed: $e\n$st');
        }
      }());
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
      current: SearchFeature.events,
      override: buildEventsConfig(
        ref: ref,
        onTap: (e) {
          final t = e.triggerTime.toLocal();
          _calendarKey.currentState?.jumpTo(t);
        },
      ),
    );
  }

  final GlobalKey<_CalendarTabState> _calendarKey =
      GlobalKey<_CalendarTabState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: const Text('事件'), showAppIcon: true),
      body: RepaintBoundary(child: _CalendarTab(key: _calendarKey)),
    );
  }
}
