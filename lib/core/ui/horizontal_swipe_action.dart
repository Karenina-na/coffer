import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum HorizontalSwipeDirection { backward, forward }

typedef HorizontalSwipeHandler = FutureOr<bool> Function(
  HorizontalSwipeDirection direction,
);

class HorizontalSwipeBinding {
  const HorizontalSwipeBinding({required this.owner, required this.handler});

  final Object owner;
  final HorizontalSwipeHandler? handler;
}

/// 当前主页面注册到壳层浮动导航的横向滑动处理器。
///
/// - 返回 `true` 表示当前页面已消费本次滑动（如切换二级 Tab）
/// - 返回 `false` 表示当前页面处于边界，应交由壳层切换主导航
class HorizontalSwipeAction extends Notifier<HorizontalSwipeBinding?> {
  @override
  HorizontalSwipeBinding? build() => null;

  void set(Object owner, HorizontalSwipeHandler? handler) {
    state = HorizontalSwipeBinding(owner: owner, handler: handler);
  }

  void clearLater(Object owner) {
    Future<void>.microtask(() {
      if (!ref.mounted) return;
      if (state?.owner == owner) state = null;
    });
  }
}

final horizontalSwipeActionProvider =
    NotifierProvider<HorizontalSwipeAction, HorizontalSwipeBinding?>(
  HorizontalSwipeAction.new,
);

class MainNavigationSwipeBinding {
  const MainNavigationSwipeBinding({required this.owner, required this.handler});

  final Object owner;
  final HorizontalSwipeHandler? handler;
}

/// 壳层主导航注册给页面使用的横向切换处理器。
class MainNavigationSwipeAction extends Notifier<MainNavigationSwipeBinding?> {
  @override
  MainNavigationSwipeBinding? build() => null;

  void set(Object owner, HorizontalSwipeHandler? handler) {
    state = MainNavigationSwipeBinding(owner: owner, handler: handler);
  }

  void clearLater(Object owner) {
    Future<void>.microtask(() {
      if (!ref.mounted) return;
      if (state?.owner == owner) state = null;
    });
  }
}

final mainNavigationSwipeActionProvider =
    NotifierProvider<MainNavigationSwipeAction, MainNavigationSwipeBinding?>(
  MainNavigationSwipeAction.new,
);
