import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/ui/dict_picker_field.dart';
import '../../../core/ui/error_localizer.dart';
import '../../../domain/entities/channel.dart';
import '../../../domain/entities/channel_enums.dart';
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
  late final TextEditingController _allowedCtrl;
  late final TextEditingController _blockedCtrl;

  late String _protocol; // 转账协议 code（来自 dict_entries）
  String? _currencyCode; // 限额币种（可空）
  late bool _requireSameRegion;
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
    _allowedCtrl = TextEditingController(
      text: (rule['allowedRegions'] as List?)?.join(', ') ?? '',
    );
    _blockedCtrl = TextEditingController(
      text: (rule['blockedRegions'] as List?)?.join(', ') ?? '',
    );
    _protocol = c?.transferProtocol ?? 'INTERNAL';
    _requireSameRegion = rule['requireSameRegion'] == true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _feeRateCtrl.dispose();
    _fixedFeeCtrl.dispose();
    _singleLimitCtrl.dispose();
    _dailyLimitCtrl.dispose();
    _allowedCtrl.dispose();
    _blockedCtrl.dispose();
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

  List<String> _splitRegions(String s) => s
      .split(RegExp(r'[,\s]+'))
      .where((e) => e.trim().isNotEmpty)
      .map((e) => e.trim().toUpperCase())
      .toList();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final now = DateTime.now();
    final allowed = _splitRegions(_allowedCtrl.text);
    final blocked = _splitRegions(_blockedCtrl.text);
    final rule = <String, dynamic>{
      if (allowed.isNotEmpty) 'allowedRegions': allowed,
      if (blocked.isNotEmpty) 'blockedRegions': blocked,
      if (_requireSameRegion) 'requireSameRegion': true,
    };
    final prev = widget.initial;
    final channel = Channel(
      id: prev?.id ?? const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      transferProtocol: _protocol,
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
    final result = await ref.read(channelRepositoryProvider).upsert(channel);
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
          TextFormField(
            controller: _allowedCtrl,
            decoration: const InputDecoration(
              labelText: '允许区域（逗号分隔，可选）',
              helperText: '如 CN, HK, SG',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _blockedCtrl,
            decoration: const InputDecoration(
              labelText: '禁止区域（逗号分隔，可选）',
              helperText: '如 KP, IR',
            ),
          ),
          SwitchListTile(
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
