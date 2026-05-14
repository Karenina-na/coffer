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

  late String _region;
  late AccountType _type;
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
        text: (a?.fxSpreadPercent ?? 0).toStringAsFixed(2));
    _type = a?.accountType ?? AccountType.bank;
  }

  @override
  void dispose() {
    _institutionCtrl.dispose();
    _accountNoCtrl.dispose();
    _fxSpreadCtrl.dispose();
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
        fxSpreadPercent: double.tryParse(_fxSpreadCtrl.text) ?? 0,
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
        fxSpreadPercent: double.tryParse(_fxSpreadCtrl.text) ?? 0,
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
            TextFormField(
              controller: _fxSpreadCtrl,
              decoration: const InputDecoration(
                labelText: '换汇损耗 (%)',
                helperText: '0 = 不支持换汇；例如 0.3 表示内部换汇损耗 0.3%',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
            ),
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
