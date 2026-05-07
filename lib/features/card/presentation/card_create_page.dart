import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/dict_picker_field.dart';
import '../../../core/ui/enum_labels.dart';
import '../../../core/ui/error_localizer.dart';
import '../../../domain/entities/account.dart';
import '../../../domain/entities/card.dart';
import '../../../domain/entities/card_enums.dart';
import '../../../domain/entities/dict_type.dart';
import '../../account/presentation/account_providers.dart';
import 'card_providers.dart';

/// 银行卡创建 / 编辑页。
///
/// - `initial == null`：走 [CreateCardUseCase] 生成新卡。
/// - `initial != null`：编辑已有卡；id / createdAt / 归属账户保持不变。
///   - 卡号字段留空 = 保留原有加密卡号；输入新卡号则重新加密并刷新 masked。
///   - CVV 字段留空 = 保留原有（可能为空）。
class CardCreatePage extends ConsumerStatefulWidget {
  const CardCreatePage({super.key, this.initial});

  final BankCard? initial;

  @override
  ConsumerState<CardCreatePage> createState() => _CardCreatePageState();
}

class _CardCreatePageState extends ConsumerState<CardCreatePage> {
  static const _currencyPresets = <String>[
    'CNY',
    'USD',
    'HKD',
    'EUR',
    'JPY',
    'SGD',
    'GBP',
    'AUD',
  ];

  final _formKey = GlobalKey<FormState>();
  CardOrganization? _organization;
  late final TextEditingController _issuerCtrl;
  late final TextEditingController _cardNoCtrl;
  late final TextEditingController _cvvCtrl;
  late final TextEditingController _mmCtrl;
  late final TextEditingController _yyyyCtrl;
  late final TextEditingController _billingAddressCtrl;
  final _customCcyCtrl = TextEditingController();

  late CardType _type;
  String? _accountId;
  String? _primaryCurrency;
  late bool _supportsAll;
  final Set<String> _extraCurrencies = <String>{};
  bool _submitting = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final c = widget.initial;
    _organization = CardOrganization.tryFromCode(c?.cardOrganization) ??
        CardOrganization.visa;
    _issuerCtrl = TextEditingController(text: c?.issuerName ?? '');
    _cardNoCtrl = TextEditingController();
    _cvvCtrl = TextEditingController();
    _mmCtrl = TextEditingController(
      text: c == null ? '' : c.expireMonth.toString().padLeft(2, '0'),
    );
    _yyyyCtrl = TextEditingController(
      text: c == null ? '' : c.expireYear.toString(),
    );
    _billingAddressCtrl = TextEditingController(text: c?.billingAddress ?? '');
    _type = c?.cardType ?? CardType.credit;
    _accountId = c?.accountId;
    _primaryCurrency = c?.currency ?? 'CNY';
    _supportsAll = c?.supportsAllCurrencies ?? false;
    if (c != null) _extraCurrencies.addAll(c.supportedCurrencies);
  }

  @override
  void dispose() {
    _issuerCtrl.dispose();
    _cardNoCtrl.dispose();
    _cvvCtrl.dispose();
    _mmCtrl.dispose();
    _yyyyCtrl.dispose();
    _billingAddressCtrl.dispose();
    _customCcyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_accountId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请选择归属账户')));
      return;
    }
    setState(() => _submitting = true);
    try {
      final supported = _supportsAll
          ? const <String>[]
          : _extraCurrencies.toList(growable: false);
      final billingAddress = _billingAddressCtrl.text.trim().isEmpty
          ? null
          : _billingAddressCtrl.text.trim();
      final plainCvv =
          _cvvCtrl.text.trim().isEmpty ? null : _cvvCtrl.text.trim();

      if (_isEdit) {
        final prev = widget.initial!;
        final plainCardNo =
            _cardNoCtrl.text.trim().isEmpty ? null : _cardNoCtrl.text.trim();
        final r = await ref.read(saveCardUseCaseProvider).update(
              prev: prev,
              cardOrganization: _organization!.code,
              plainCardNo: plainCardNo,
              cardType: _type,
              expireMonth: int.parse(_mmCtrl.text),
              expireYear: int.parse(_yyyyCtrl.text),
              issuerName: _issuerCtrl.text.trim(),
              plainCvv: plainCvv,
              currency: _primaryCurrency,
              supportsAllCurrencies: _supportsAll,
              supportedCurrencies: supported,
              billingAddress: billingAddress,
            );
        if (!mounted) return;
        r.when(
          ok: (_) => context.pop(),
          err: (e) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('更新失败: ${errorToMessage(e)}')),
          ),
        );
        return;
      }

      final r = await ref.read(saveCardUseCaseProvider).create(
        accountId: _accountId!,
        cardOrganization: _organization!.code,
        plainCardNo: _cardNoCtrl.text,
        cardType: _type,
        expireMonth: int.parse(_mmCtrl.text),
        expireYear: int.parse(_yyyyCtrl.text),
        issuerName: _issuerCtrl.text.trim(),
        plainCvv: plainCvv,
        currency: _primaryCurrency,
        supportsAllCurrencies: _supportsAll,
        supportedCurrencies: supported,
        billingAddress: billingAddress,
      );
      if (!mounted) return;
      r.when(
        ok: (_) => context.pop(),
        err: (e) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建失败: ${errorToMessage(e)}')),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失败: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _addCustomCurrency() {
    final raw = _customCcyCtrl.text.trim().toUpperCase();
    if (raw.isEmpty) return;
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(raw)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('币种需为 3 位字母的 ISO-4217 代码')),
      );
      return;
    }
    setState(() {
      _extraCurrencies.add(raw);
      _customCcyCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountListProvider);
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? '编辑卡片' : '新建卡片')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            accounts.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('账户加载失败: ${errorToMessage(e)}'),
              data: (list) => _AccountPicker(
                accounts: list,
                selected: _accountId,
                onChanged:
                    _isEdit ? null : (v) => setState(() => _accountId = v),
                readOnly: _isEdit,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CardType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: '卡类型'),
              items: CardType.values
                  .map((t) =>
                      DropdownMenuItem(value: t, child: Text(t.labelBilingual)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CardOrganization>(
              initialValue: _organization,
              decoration: const InputDecoration(labelText: '发卡组织'),
              items: CardOrganization.values
                  .map((o) => DropdownMenuItem(
                        value: o,
                        child: Text(o.labelBilingual),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _organization = v),
              validator: (v) => v == null ? '请选择发卡组织' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _issuerCtrl,
              decoration: const InputDecoration(labelText: '发卡行'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '必填' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cardNoCtrl,
              decoration: InputDecoration(
                labelText: _isEdit ? '新卡号（留空则保留原号）' : '卡号',
                helperText: _isEdit
                    ? '原卡号：${widget.initial!.cardNoMasked}；输入新号会重新加密并更新掩码'
                    : '明文仅用于加密存储，不会落盘',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                final digits = (v ?? '').replaceAll(RegExp(r'\s+'), '');
                if (_isEdit && digits.isEmpty) return null;
                if (digits.length < 12) return '卡号过短';
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _mmCtrl,
                    decoration: const InputDecoration(labelText: '有效期月 MM'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 1 || n > 12) return '1-12';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _yyyyCtrl,
                    decoration: const InputDecoration(labelText: '有效期年 YYYY'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 2000 || n > 2100) return '2000-2100';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cvvCtrl,
              decoration: InputDecoration(
                labelText: _isEdit ? 'CVV（留空则保留原值）' : 'CVV（可选）',
                helperText: _isEdit
                    ? (widget.initial!.cvvCiphertext != null
                        ? '原 CVV 已加密保存；输入新值会覆盖'
                        : '当前未设置 CVV，可在此补充')
                    : '仅加密后以密文存储',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              obscureText: true,
            ),
            const SizedBox(height: 20),
            _buildCurrencySection(context),
            const SizedBox(height: 12),
            TextFormField(
              controller: _billingAddressCtrl,
              decoration: const InputDecoration(
                labelText: '账单地址（可选）',
                helperText: '信用卡授权 / 线上支付常用',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              textInputAction: TextInputAction.newline,
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

  Widget _buildCurrencySection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.language, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                '支持币种',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DictPickerField(
            type: DictType.currency,
            value: _primaryCurrency,
            label: '主记账币种',
            helperText: '用于信用额度 / 账单计价；可在 设置 → 字典 扩展',
            onChanged: (v) => setState(() => _primaryCurrency = v),
            validator: (v) =>
                (v == null || v.isEmpty) ? '必选' : null,
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('支持全币种'),
            subtitle: const Text('勾选后该卡可消费任意币种，下方多选失效'),
            value: _supportsAll,
            onChanged: (v) => setState(() => _supportsAll = v),
          ),
          if (!_supportsAll) ...[
            const SizedBox(height: 4),
            Text(
              '可消费的其他币种（主币种自动包含）',
              style: TextStyle(
                fontSize: 11,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final ccy in <String>{
                  ..._currencyPresets,
                  ..._extraCurrencies,
                })
                  if (ccy != _primaryCurrency)
                    FilterChip(
                      label: Text(ccy),
                      selected: _extraCurrencies.contains(ccy),
                      onSelected: (sel) => setState(() {
                        if (sel) {
                          _extraCurrencies.add(ccy);
                        } else {
                          _extraCurrencies.remove(ccy);
                        }
                      }),
                    ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customCcyCtrl,
                    decoration: const InputDecoration(
                      labelText: '自定义 ISO 代码',
                      hintText: '例如 CHF',
                      isDense: true,
                    ),
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(3),
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
                    ],
                    onSubmitted: (_) => _addCustomCurrency(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: _addCustomCurrency,
                  child: const Text('添加'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AccountPicker extends StatelessWidget {
  const _AccountPicker({
    required this.accounts,
    required this.selected,
    required this.onChanged,
    this.readOnly = false,
  });

  final List<Account> accounts;
  final String? selected;
  final ValueChanged<String?>? onChanged;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (accounts.isEmpty) {
      return Card(
        elevation: 0,
        color: scheme.errorContainer,
        child: ListTile(
          leading: Icon(Icons.account_balance_outlined,
              color: scheme.onErrorContainer),
          title: Text('暂无可选账户',
              style: TextStyle(color: scheme.onErrorContainer)),
          subtitle: Text('卡片必须绑定账户，请先创建账户',
              style: TextStyle(color: scheme.onErrorContainer)),
          trailing: Icon(Icons.chevron_right, color: scheme.onErrorContainer),
          onTap: () => GoRouter.of(context).push('/accounts/new'),
        ),
      );
    }
    return DropdownButtonFormField<String>(
      initialValue: selected,
      decoration: InputDecoration(
        labelText: '归属账户 *',
        prefixIcon: const Icon(Icons.account_balance_outlined),
        border: const OutlineInputBorder(),
        helperText: readOnly ? '编辑时不可迁移账户' : '卡片必须绑定到一个账户',
      ),
      validator: (v) => v == null ? '请选择归属账户' : null,
      items: accounts
          .map((a) => DropdownMenuItem(
                value: a.id,
                child: Text(
                  a.accountNo == null
                      ? '${a.institutionName} · ${a.accountType.labelZh}'
                      : '${a.institutionName} · ${a.accountType.labelZh} · ${a.accountNo}',
                ),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}
