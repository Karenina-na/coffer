import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/dict_providers.dart';
import '../../domain/entities/dict_entry.dart';
import '../../domain/entities/dict_type.dart';

/// 通用字典下拉选择器。
///
/// - 以 [DictType] 订阅对应字典流；加载期显示 disabled 占位；为空时显示只读提示
/// - 将字典 `code` 作为对外值；显示文案使用 `name（code）`
/// - 若当前 [value] 在字典中不存在（历史数据或条目已被删除），会追加一条 fallback
///   以保留原值，避免 FormField 抛 "value not in items" 断言
class DictPickerField extends ConsumerWidget {
  const DictPickerField({
    super.key,
    required this.type,
    required this.value,
    required this.onChanged,
    this.label,
    this.helperText,
    this.validator,
    this.allowEmpty = false,
    this.emptyLabel = '未选择',
    this.textStyle,
  });

  final DictType type;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String? label;
  final String? helperText;
  final FormFieldValidator<String>? validator;
  final bool allowEmpty;
  final String emptyLabel;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dictEntriesProvider(type));
    return async.when(
      loading: () => InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
        ),
        child: const SizedBox(
          height: 20,
          child: LinearProgressIndicator(minHeight: 2),
        ),
      ),
      error: (e, _) => InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          errorText: '字典加载失败：$e',
        ),
        child: const SizedBox(height: 20),
      ),
      data: (entries) => _buildDropdown(entries),
    );
  }

  Widget _buildDropdown(List<DictEntry> entries) {
    final items = <DropdownMenuItem<String>>[
      if (allowEmpty)
        DropdownMenuItem(
          value: '',
          child: Text(
            emptyLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          ),
        ),
      for (final e in entries)
        DropdownMenuItem(
          value: e.code,
          child: Text(
            '${e.name}（${e.code}）',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          ),
        ),
    ];
    // 兼容历史 / 已删除数据：若当前值不在字典内，补一条 fallback
    if (value != null &&
        value!.isNotEmpty &&
        !entries.any((e) => e.code == value)) {
      items.add(DropdownMenuItem(
        value: value,
        child: Text(
          '${value!}（已失效）',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textStyle,
        ),
      ));
    }
    return DropdownButtonFormField<String>(
      initialValue: (value == null || value!.isEmpty) && allowEmpty ? '' : value,
      items: items,
      onChanged: (v) => onChanged(allowEmpty && (v == null || v.isEmpty) ? null : v),
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
      ),
      style: textStyle,
      validator: validator,
      isExpanded: true,
    );
  }
}
