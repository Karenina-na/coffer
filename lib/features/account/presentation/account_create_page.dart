import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/dict_picker_field.dart';
import '../../../core/ui/enum_labels.dart';
import '../../../core/ui/error_localizer.dart';
import '../../../domain/entities/account.dart';
import '../../../domain/entities/account_enums.dart';
import '../../../domain/entities/dict_type.dart';
import 'account_providers.dart';

/// 账户创建 / 编辑页。
///
/// - `initial == null`：创建模式，走 `CreateAccountUseCase` 生成新 id。
/// - `initial != null`：编辑模式，保留原 id / createdAt，调用 `repository.update`。
class AccountCreatePage extends ConsumerStatefulWidget {
  const AccountCreatePage({super.key, this.initial});

  final Account? initial;

  @override
  ConsumerState<AccountCreatePage> createState() => _AccountCreatePageState();
}

class _AccountCreatePageState extends ConsumerState<AccountCreatePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _institutionCtrl;
  late final TextEditingController _accountNoCtrl;
  late final TextEditingController _fxSpreadCtrl;
  late final TextEditingController _fxFixedFeeCtrl;

  late String _region;
  late AccountType _type;
  late AccountStatus _status;
  DateTime? _openedAt;
  bool _supportsFx = false;
  bool _submitting = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final a = widget.initial;
    _institutionCtrl = TextEditingController(text: a?.institutionName ?? '');
    _region = a?.sovereigntyRegion ?? 'CN';
    _accountNoCtrl = TextEditingController(text: a?.accountNo ?? '');
    _fxSpreadCtrl = TextEditingController(
        text: ((a?.fxSpreadPercent ?? 0) > 0
            ? a!.fxSpreadPercent.toStringAsFixed(2)
            : '0.30'));
    _fxFixedFeeCtrl = TextEditingController(
        text: ((a?.fxFixedFee) != null
            ? a!.fxFixedFee.toString()
            : ''));
    _supportsFx = (a?.fxSpreadPercent ?? 0) > 0;
    _type = a?.accountType ?? AccountType.bank;
    _status = a?.status ?? AccountStatus.active;
    _openedAt = a?.openedAt;
  }

  @override
  void dispose() {
    _institutionCtrl.dispose();
    _accountNoCtrl.dispose();
    _fxSpreadCtrl.dispose();
    _fxFixedFeeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final accountNo =
        _accountNoCtrl.text.trim().isEmpty ? null : _accountNoCtrl.text.trim();
    if (_isEdit) {
      final now = DateTime.now();
      final updated = widget.initial!.copyWith(
        accountType: _type,
        sovereigntyRegion: _region,
        institutionName: _institutionCtrl.text.trim(),
        accountNo: accountNo,
        status: _status,
        openedAt: _openedAt,
        fxSpreadPercent:
            _supportsFx ? (double.tryParse(_fxSpreadCtrl.text) ?? 0.3) : 0,
        fxFixedFee: _supportsFx
            ? Decimal.tryParse(_fxFixedFeeCtrl.text)
            : null,
        updatedAt: now,
      );
      final result =
          await ref.read(accountRepositoryProvider).update(updated);
      if (!mounted) return;
      setState(() => _submitting = false);
      result.when(
        ok: (_) => context.pop(),
        err: (e) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失败: ${errorToMessage(e)}')),
        ),
      );
    } else {
      final usecase = ref.read(createAccountUseCaseProvider);
      final result = await usecase(
        accountType: _type,
        sovereigntyRegion: _region,
        institutionName: _institutionCtrl.text,
        accountNo: accountNo,
        status: _status,
        openedAt: _openedAt,
        fxSpreadPercent:
            _supportsFx ? (double.tryParse(_fxSpreadCtrl.text) ?? 0.3) : 0,
        fxFixedFee: _supportsFx
            ? Decimal.tryParse(_fxFixedFeeCtrl.text)
            : null,
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      result.when(
        ok: (_) => context.pop(),
        err: (e) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建失败: ${errorToMessage(e)}')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? '编辑账户' : '新建账户')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<AccountType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: '账户类型'),
              items: AccountType.values
                  .map((t) =>
                      DropdownMenuItem(value: t, child: Text(t.labelBilingual)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _institutionCtrl,
              decoration: const InputDecoration(labelText: '开户机构'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '必填' : null,
            ),
            const SizedBox(height: 12),
            DictPickerField(
              type: DictType.sovereigntyRegion,
              value: _region,
              label: '主权地区',
              helperText: 'ISO 国家 / 地区代码；可在 设置 → 字典 维护',
              onChanged: (v) => setState(() {
                if (v != null) _region = v;
              }),
              validator: (v) =>
                  (v == null || v.isEmpty) ? '必选' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _accountNoCtrl,
              decoration: const InputDecoration(labelText: '账户编号（可选）'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AccountStatus>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: '账户状态'),
              items: AccountStatus.values
                  .map((s) =>
                      DropdownMenuItem(value: s, child: Text(s.labelBilingual)))
                  .toList(),
              onChanged: (v) => setState(() => _status = v ?? _status),
            ),
            const SizedBox(height: 12),
            _DatePickerTile(
              label: '开户时间（可选）',
              date: _openedAt,
              onChanged: (d) => setState(() => _openedAt = d),
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              title: const Text('支持换汇'),
              subtitle: const Text('账户内部可进行币种转换'),
              value: _supportsFx,
              onChanged: (v) => setState(() => _supportsFx = v),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            if (_supportsFx) ...[
              const SizedBox(height: 4),
              TextFormField(
                controller: _fxSpreadCtrl,
                decoration: const InputDecoration(
                  labelText: '换汇损耗 (%)',
                  helperText: '例如 0.3 表示内部换汇时有 0.3% 的摩擦损耗',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fxFixedFeeCtrl,
                decoration: const InputDecoration(
                  labelText: '换汇固定费用（可选）',
                  helperText: '每笔换汇额外收取的固定金额',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueGrey.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blueGrey.withValues(alpha: 0.12),
                  width: 0.5,
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.swap_horiz_outlined, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '转账通道与账户级手续费覆盖请在保存后到账户详情页配置。',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
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
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({required this.label, required this.date, required this.onChanged});

  final String label;
  final DateTime? date;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(1970),
          lastDate: DateTime(2100),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: date != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => onChanged(null),
                )
              : const Icon(Icons.calendar_today_outlined, size: 20),
        ),
        child: Text(
          date != null
              ? '${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}'
              : '未设置',
        ),
      ),
    );
  }
}
