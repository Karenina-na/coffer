import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 常驻在每个主页 AppBar 最右侧的「设置」入口。
///
/// 按钮点击跳转 `/settings`。AppBar 的 `actions` 列表把本 widget
/// 放在最后即可实现「永远在最右」。
class SettingsAction extends StatelessWidget {
  const SettingsAction({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: '设置',
      icon: const Icon(Icons.settings_outlined),
      onPressed: () => context.push('/settings'),
    );
  }
}
