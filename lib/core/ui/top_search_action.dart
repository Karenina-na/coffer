import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 当前页注册到一级 Bar 的「搜索入口」回调。
///
/// - 各 Tab 页在 `initState` / tab 切换时通过
///   `ref.read(topSearchOpenerProvider.notifier).set(opener)` 注册；
///   在 `dispose` 时调用 `set(null)` 清空。
/// - 若当前页面本身没有搜索能力（仪表盘、转账 Tab），保留 `null` 即可，
///   一级 Bar 会自动隐藏搜索按钮。
class TopSearchOpener extends Notifier<VoidCallback?> {
  @override
  VoidCallback? build() => null;

  void set(VoidCallback? opener) => state = opener;
}

final topSearchOpenerProvider =
    NotifierProvider<TopSearchOpener, VoidCallback?>(TopSearchOpener.new);

/// 一级 Bar 右侧常驻的搜索按钮。
///
/// 按钮是否显示由 [topSearchOpenerProvider] 决定：当前页无搜索时会渲染
/// `SizedBox.shrink()`，不挤占布局。
class TopSearchAction extends ConsumerWidget {
  const TopSearchAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opener = ref.watch(topSearchOpenerProvider);
    if (opener == null) return const SizedBox.shrink();
    return IconButton(
      tooltip: '搜索',
      icon: const Icon(Icons.search),
      onPressed: opener,
    );
  }
}
