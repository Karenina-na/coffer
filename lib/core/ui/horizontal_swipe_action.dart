import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum HorizontalSwipeDirection { backward, forward }

typedef HorizontalSwipeHandler = FutureOr<bool> Function(
  HorizontalSwipeDirection direction,
);

/// 当前主页面注册到壳层浮动导航的横向滑动处理器。
///
/// - 返回 `true` 表示当前页面已消费本次滑动（如切换二级 Tab）
/// - 返回 `false` 表示当前页面处于边界，应交由壳层切换主导航
class HorizontalSwipeAction extends Notifier<HorizontalSwipeHandler?> {
  @override
  HorizontalSwipeHandler? build() => null;

  void set(HorizontalSwipeHandler? handler) => state = handler;

  void clearLater() {
    Future<void>.microtask(() {
      if (ref.mounted) state = null;
    });
  }
}

final horizontalSwipeActionProvider =
    NotifierProvider<HorizontalSwipeAction, HorizontalSwipeHandler?>(
  HorizontalSwipeAction.new,
);

/// 壳层主导航注册给页面使用的横向切换处理器。
class MainNavigationSwipeAction extends Notifier<HorizontalSwipeHandler?> {
  @override
  HorizontalSwipeHandler? build() => null;

  void set(HorizontalSwipeHandler? handler) => state = handler;

  void clearLater() {
    Future<void>.microtask(() {
      if (ref.mounted) state = null;
    });
  }
}

final mainNavigationSwipeActionProvider =
    NotifierProvider<MainNavigationSwipeAction, HorizontalSwipeHandler?>(
  MainNavigationSwipeAction.new,
);
