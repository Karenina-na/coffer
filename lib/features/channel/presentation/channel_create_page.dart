import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/channel.dart';
import 'channel_form.dart';

/// 通道创建 / 编辑页。
///
/// `initial == null` 为新建；否则编辑（`ChannelForm` 内部根据 `initial` 判断）。
class ChannelCreatePage extends StatelessWidget {
  const ChannelCreatePage({super.key, this.initial});

  final Channel? initial;

  @override
  Widget build(BuildContext context) {
    final isEdit = initial != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? '编辑通道' : '新建通道')),
      body: ChannelForm(
        initial: initial,
        onSaved: () => context.pop(),
      ),
    );
  }
}
