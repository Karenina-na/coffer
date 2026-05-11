import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/providers/dict_providers.dart';
import '../../../core/ui/dict_picker_field.dart';
import '../../../core/ui/error_localizer.dart';
import '../../../domain/entities/channel.dart';
import '../../../domain/entities/channel_enums.dart';
import '../../../domain/entities/dict_entry.dart';
import '../../../domain/entities/dict_type.dart';
import 'channel_providers.dart';

/// 可复用的通道表单；同时服务于新建与编辑场景。
///
/// 新建：[initial] 为空，提交生成新 id；
/// 编辑：传入已有 [Channel]，表单预填并保留 id / createdAt。
class ChannelForm extends ConsumerStatefulWidget {
  const ChannelForm({
    super.key,
    this.initial,
    this.onSaved,
  });

  final Channel? initial;
  final VoidCallback? onSaved;

  @override
  ConsumerState<ChannelForm> createState() => _ChannelFormState();
}

class _ChannelFormState extends ConsumerState<ChannelForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _feeRateCtrl;
  late final TextEditingController _fixedFeeCtrl;
  late final TextEditingController _singleLimitCtrl;
  late final TextEditingController _dailyLimitCtrl;

  late String _protocol; // 转账协议 code（来自 dict_entries）
  String? _currencyCode; // 限额币种（可空）
  late bool _requireSameRegion;
  late List<String> _allowedRegions;
  late List<String> _blockedRegions;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final c = widget.initial;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _feeRateCtrl = TextEditingController(text: c?.feeRate?.toString() ?? '');
    _fixedFeeCtrl = TextEditingController(text: c?.fixedFee?.toString() ?? '');
    _currencyCode = c?.limitCurrency;
    _singleLimitCtrl =
        TextEditingController(text: c?.singleLimit?.toString() ?? '');
    _dailyLimitCtrl =
        TextEditingController(text: c?.dailyLimit?.toString() ?? '');
    final rule = c?.sovereigntyRegionRule ?? const <String, dynamic>{};
    _allowedRegions = _normalizeRegions(rule['allowedRegions']);
    _blockedRegions = _normalizeRegions(rule['blockedRegions']);
    _protocol = c?.transferProtocol ?? 'SWIFT';
    _requireSameRegion = rule['requireSameRegion'] == true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _feeRateCtrl.dispose();
    _fixedFeeCtrl.dispose();
    _singleLimitCtrl.dispose();
    _dailyLimitCtrl.dispose();
    super.dispose();
  }

  Decimal? _parse(TextEditingController c) {
    final s = c.text.trim();
    if (s.isEmpty) return null;
    return Decimal.tryParse(s);
  }

  String? _validateDecimal(String? v, {bool mustBePositive = false}) {
    if (v == null || v.trim().isEmpty) return null;
    final d = Decimal.tryParse(v.trim());
    if (d == null) return '无效的数字格式';
    if (d < Decimal.zero) return '不能为负数';
    if (mustBePositive && d == Decimal.zero) return '必须大于 0';
    return null;
  }

  List<String> _normalizeRegions(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<String>()
        .map((e) => e.trim().toUpperCase())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final now = DateTime.now();
    final rule = <String, dynamic>{
      if (_allowedRegions.isNotEmpty) 'allowedRegions': _allowedRegions,
      if (_blockedRegions.isNotEmpty) 'blockedRegions': _blockedRegions,
      if (_requireSameRegion) 'requireSameRegion': true,
    };
    final prev = widget.initial;
    final channel = Channel(
      id: prev?.id ?? const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      transferProtocol: _protocol,
      isBuiltin: prev?.isBuiltin ?? false,
      feeRate: _parse(_feeRateCtrl),
      fixedFee: _parse(_fixedFeeCtrl),
      sovereigntyRegionRule: rule.isEmpty ? null : rule,
      limitCurrency: _currencyCode,
      singleLimit: _parse(_singleLimitCtrl),
      dailyLimit: _parse(_dailyLimitCtrl),
      status: prev?.status ?? ChannelStatus.enabled,
      effectiveFrom: prev?.effectiveFrom,
      effectiveTo: prev?.effectiveTo,
      createdAt: prev?.createdAt ?? now,
      updatedAt: now,
    );
    final result = await ref.read(saveChannelUseCaseProvider)(channel);
    if (!mounted) return;
    setState(() => _submitting = false);
    result.when(
      ok: (_) => widget.onSaved?.call(),
      err: (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: ${errorToMessage(e)}')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: '通道名称',
              helperText: '如 SWIFT、微信支付、ACH 等，面向账户声明支持',
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? '名称不能为空' : null,
          ),
          const SizedBox(height: 12),
          DictPickerField(
            type: DictType.transferProtocol,
            value: _protocol,
            label: '转账协议',
            onChanged: (v) => setState(() {
              if (v != null) _protocol = v;
            }),
            validator: (v) => (v == null || v.isEmpty) ? '必选' : null,
          ),
          const Divider(height: 32),
          DictPickerField(
            type: DictType.currency,
            value: _currencyCode,
            label: '限额币种（可选）',
            helperText: '若非空，则 Channel 仅接受此币种转账',
            onChanged: (v) => setState(() => _currencyCode = v),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _feeRateCtrl,
                decoration:
                    const InputDecoration(labelText: '费率（如 0.003）'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                validator: _validateDecimal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _fixedFeeCtrl,
                decoration: const InputDecoration(labelText: '固定费用'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                validator: _validateDecimal,
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _singleLimitCtrl,
                decoration: const InputDecoration(labelText: '单笔上限'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                validator: (v) =>
                    _validateDecimal(v, mustBePositive: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _dailyLimitCtrl,
                decoration: const InputDecoration(labelText: '日累计上限'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                validator: (v) =>
                    _validateDecimal(v, mustBePositive: true),
              ),
            ),
          ]),
          const Divider(height: 32),
          _RegionMultiSelectField(
            fieldKey: const Key('channel-allowed-regions-field'),
            label: '允许区域（可选）',
            helperText: '仅允许所选区域之间转账',
            selectedCodes: _allowedRegions,
            onChanged: (value) => setState(() => _allowedRegions = value),
          ),
          const SizedBox(height: 12),
          _RegionMultiSelectField(
            fieldKey: const Key('channel-blocked-regions-field'),
            label: '禁止区域（可选）',
            helperText: '命中任一源/目标区域即禁止转账',
            selectedCodes: _blockedRegions,
            onChanged: (value) => setState(() => _blockedRegions = value),
          ),
          SwitchListTile(
            key: const Key('channel-require-same-region-switch'),
            value: _requireSameRegion,
            onChanged: (v) => setState(() => _requireSameRegion = v),
            title: const Text('要求源/目的在同一区域'),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
    );
  }
}

class _RegionMultiSelectField extends ConsumerWidget {
  const _RegionMultiSelectField({
    required this.fieldKey,
    required this.label,
    required this.helperText,
    required this.selectedCodes,
    required this.onChanged,
  });

  final Key fieldKey;
  final String label;
  final String helperText;
  final List<String> selectedCodes;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dictEntriesProvider(DictType.sovereigntyRegion));
    return async.when(
      loading: () => InputDecorator(
        decoration: InputDecoration(labelText: label, helperText: helperText),
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
      data: (entries) {
        final knownCodes = entries.map((e) => e.code).toSet();
        final effectiveEntries = [
          ...entries,
          for (final code in selectedCodes.where((e) => !knownCodes.contains(e)))
            _expiredEntry(code),
        ];
        return InkWell(
          key: fieldKey,
          onTap: () async {
            final picked = await showModalBottomSheet<List<String>>(
              context: context,
              isScrollControlled: true,
              useRootNavigator: true,
              builder: (_) => _RegionMultiSelectSheet(
                label: label,
                entries: effectiveEntries,
                initialCodes: selectedCodes,
              ),
            );
            if (picked != null) onChanged(picked);
          },
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              helperText: helperText,
              suffixIcon: const Icon(Icons.arrow_drop_down),
            ),
            child: selectedCodes.isEmpty
                ? const Text('未选择')
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final code in selectedCodes)
                        InputChip(label: Text(_labelFor(effectiveEntries, code))),
                    ],
                  ),
          ),
        );
      },
    );
  }

  DictEntry _expiredEntry(String code) => DictEntry(
        id: -code.hashCode,
        type: DictType.sovereigntyRegion,
        code: code,
        name: '$code（已失效）',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
      );

  String _labelFor(List<DictEntry> entries, String code) {
    final matches = entries.where((e) => e.code == code);
    if (matches.isEmpty) return code;
    final match = matches.first;
    return '${match.name}（${match.code}）';
  }
}

class _RegionMultiSelectSheet extends StatefulWidget {
  const _RegionMultiSelectSheet({
    required this.label,
    required this.entries,
    required this.initialCodes,
  });

  final String label;
  final List<DictEntry> entries;
  final List<String> initialCodes;

  @override
  State<_RegionMultiSelectSheet> createState() => _RegionMultiSelectSheetState();
}

class _RegionMultiSelectSheetState extends State<_RegionMultiSelectSheet> {
  late final TextEditingController _queryCtrl;
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _queryCtrl = TextEditingController();
    _selected = {...widget.initialCodes};
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _queryCtrl.text.trim().toLowerCase();
    final filtered = widget.entries.where((entry) {
      if (query.isEmpty) return true;
      return entry.code.toLowerCase().contains(query) ||
          entry.name.toLowerCase().contains(query) ||
          (entry.nameEn?.toLowerCase().contains(query) ?? false);
    }).toList()
      ..sort((a, b) => a.code.compareTo(b.code));
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
        child: SizedBox(
          height: 520,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(_selected.clear),
                    child: const Text('清空'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      final picked = _selected.toList()..sort();
                      Navigator.of(context).pop(picked);
                    },
                    child: const Text('完成'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _queryCtrl,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: '搜索区域',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final entry = filtered[index];
                    final selected = _selected.contains(entry.code);
                    return CheckboxListTile(
                      value: selected,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(entry.name),
                      subtitle: Text(entry.code),
                      onChanged: (_) => setState(() {
                        if (selected) {
                          _selected.remove(entry.code);
                        } else {
                          _selected.add(entry.code);
                        }
                      }),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
