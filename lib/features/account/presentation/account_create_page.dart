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
import '../../../domain/entities/account_type_info.dart';
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

  // Type-specific controllers
  late final TextEditingController _bankSwiftCtrl;
  late final TextEditingController _bankIbanCtrl;
  late final TextEditingController _bankBranchCtrl;
  late final TextEditingController _brokerBaseCcyCtrl;
  late final TextEditingController _insRegNoCtrl;
  late final TextEditingController _payPlatformCtrl;
  late final TextEditingController _custCustodianCtrl;
  late final TextEditingController _cexNetworksCtrl;
  late final TextEditingController _walletChainCtrl;

  late String _region;
  late AccountType _type;
  late AccountStatus _status;
  DateTime? _openedAt;
  bool _supportsFx = false;
  bool _submitting = false;

  // Type-specific state (non-text)
  String _bankSubtype = 'checking';
  String _brokerSubtype = 'cash';
  bool _brokerMargin = false;
  String _insPolicyType = 'life';
  String _payLinkedAccountId = '';
  String _custStructure = 'segregated';
  bool _cexHasApi = false;
  String _walletType = 'hot';

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
        text: ((a?.fxFixedFee) != null ? a!.fxFixedFee.toString() : ''));
    _supportsFx = (a?.fxSpreadPercent ?? 0) > 0;
    _type = a?.accountType ?? AccountType.bank;
    _status = a?.status ?? AccountStatus.active;
    _openedAt = a?.openedAt;

    // Type-specific init
    _bankSwiftCtrl = TextEditingController();
    _bankIbanCtrl = TextEditingController();
    _bankBranchCtrl = TextEditingController();
    _brokerBaseCcyCtrl = TextEditingController();
    _insRegNoCtrl = TextEditingController();
    _payPlatformCtrl = TextEditingController();
    _custCustodianCtrl = TextEditingController();
    _cexNetworksCtrl = TextEditingController();
    _walletChainCtrl = TextEditingController();
    _loadTypeInfo(a?.typeInfo);
  }

  void _loadTypeInfo(AccountTypeInfo? info) {
    if (info == null) return;
    if (info is BankAccountInfo) {
      _bankSwiftCtrl.text = info.swiftBic ?? '';
      _bankIbanCtrl.text = info.iban ?? '';
      _bankBranchCtrl.text = info.branchName ?? '';
      _bankSubtype = info.accountSubtype ?? 'checking';
    } else if (info is BrokerAccountInfo) {
      _brokerSubtype = info.accountSubtype ?? 'cash';
      _brokerBaseCcyCtrl.text = info.baseCurrency ?? '';
      _brokerMargin = info.marginEnabled;
    } else if (info is InsuranceAccountInfo) {
      _insPolicyType = info.policyType ?? 'life';
      _insRegNoCtrl.text = info.registrationNo ?? '';
    } else if (info is PaymentAccountInfo) {
      _payPlatformCtrl.text = info.platform ?? '';
      _payLinkedAccountId = info.linkedAccountId ?? '';
    } else if (info is CustodyAccountInfo) {
      _custCustodianCtrl.text = info.custodianName ?? '';
      _custStructure = info.accountStructure ?? 'segregated';
    } else if (info is CryptoExchangeInfo) {
      _cexHasApi = info.hasApiKey;
      _cexNetworksCtrl.text = info.supportedNetworks ?? '';
    } else if (info is CryptoWalletInfo) {
      _walletType = info.walletType ?? 'hot';
      _walletChainCtrl.text = info.chain ?? '';
    }
  }

  AccountTypeInfo _collectTypeInfo() {
    switch (_type) {
      case AccountType.bank:
        return BankAccountInfo(
          swiftBic: _bankSwiftCtrl.text.trim().isEmpty
              ? null
              : _bankSwiftCtrl.text.trim(),
          iban:
              _bankIbanCtrl.text.trim().isEmpty ? null : _bankIbanCtrl.text.trim(),
          branchName: _bankBranchCtrl.text.trim().isEmpty
              ? null
              : _bankBranchCtrl.text.trim(),
          accountSubtype: _bankSubtype,
        );
      case AccountType.broker:
        return BrokerAccountInfo(
          accountSubtype: _brokerSubtype,
          baseCurrency: _brokerBaseCcyCtrl.text.trim().isEmpty
              ? null
              : _brokerBaseCcyCtrl.text.trim().toUpperCase(),
          marginEnabled: _brokerMargin,
        );
      case AccountType.insurance:
        return InsuranceAccountInfo(
          policyType: _insPolicyType,
          registrationNo: _insRegNoCtrl.text.trim().isEmpty
              ? null
              : _insRegNoCtrl.text.trim(),
        );
      case AccountType.payment:
        return PaymentAccountInfo(
          platform: _payPlatformCtrl.text.trim().isEmpty
              ? null
              : _payPlatformCtrl.text.trim(),
          linkedAccountId: _payLinkedAccountId.isEmpty
              ? null
              : _payLinkedAccountId,
        );
      case AccountType.custody:
        return CustodyAccountInfo(
          custodianName: _custCustodianCtrl.text.trim().isEmpty
              ? null
              : _custCustodianCtrl.text.trim(),
          accountStructure: _custStructure,
        );
      case AccountType.cryptoExchange:
        return CryptoExchangeInfo(
          hasApiKey: _cexHasApi,
          supportedNetworks: _cexNetworksCtrl.text.trim().isEmpty
              ? null
              : _cexNetworksCtrl.text.trim(),
        );
      case AccountType.cryptoWallet:
        return CryptoWalletInfo(
          walletType: _walletType,
          chain: _walletChainCtrl.text.trim().isEmpty
              ? null
              : _walletChainCtrl.text.trim(),
        );
    }
  }

  @override
  void dispose() {
    _institutionCtrl.dispose();
    _accountNoCtrl.dispose();
    _fxSpreadCtrl.dispose();
    _fxFixedFeeCtrl.dispose();
    _bankSwiftCtrl.dispose();
    _bankIbanCtrl.dispose();
    _bankBranchCtrl.dispose();
    _brokerBaseCcyCtrl.dispose();
    _insRegNoCtrl.dispose();
    _payPlatformCtrl.dispose();
    _custCustodianCtrl.dispose();
    _cexNetworksCtrl.dispose();
    _walletChainCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final accountNo =
        _accountNoCtrl.text.trim().isEmpty ? null : _accountNoCtrl.text.trim();
    final typeInfo = _collectTypeInfo();
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
      ).copyWithTypeInfo(typeInfo);
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
        typeInfo: typeInfo,
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
              onChanged: (v) => setState(() {
                _type = v ?? _type;
                _loadTypeInfo(AccountTypeInfo.defaultFor(_type));
              }),
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

            // ── Bank section ──
            if (_type == AccountType.bank) ...[
              const SizedBox(height: 16),
              const _SectionHeader(title: '银行信息'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bankSwiftCtrl,
                decoration: const InputDecoration(
                  labelText: 'SWIFT / BIC（可选）',
                  hintText: '如 ICBKCNBJ',
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bankIbanCtrl,
                decoration: const InputDecoration(
                  labelText: 'IBAN（可选）',
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bankBranchCtrl,
                decoration: const InputDecoration(
                  labelText: '分行名称（可选）',
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _bankSubtype,
                decoration: const InputDecoration(labelText: '账户子类型'),
                items: const [
                  DropdownMenuItem(value: 'checking', child: Text('活期 (Checking)')),
                  DropdownMenuItem(value: 'savings', child: Text('储蓄 (Savings)')),
                  DropdownMenuItem(
                      value: 'timeDeposit', child: Text('定期 (Time Deposit)')),
                ],
                onChanged: (v) => setState(() => _bankSubtype = v ?? 'checking'),
              ),
            ],

            // ── Broker section ──
            if (_type == AccountType.broker) ...[
              const SizedBox(height: 16),
              const _SectionHeader(title: '券商信息'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _brokerSubtype,
                decoration: const InputDecoration(labelText: '账户子类型'),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('现金账户 (Cash)')),
                  DropdownMenuItem(value: 'margin', child: Text('保证金账户 (Margin)')),
                  DropdownMenuItem(
                      value: 'retirement', child: Text('退休账户 (Retirement)')),
                  DropdownMenuItem(
                      value: 'education', child: Text('教育账户 (Education)')),
                ],
                onChanged: (v) => setState(() => _brokerSubtype = v ?? 'cash'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _brokerBaseCcyCtrl,
                decoration: const InputDecoration(
                  labelText: '基础币种（可选）',
                  hintText: '如 USD',
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                title: const Text('开通保证金'),
                value: _brokerMargin,
                onChanged: (v) => setState(() => _brokerMargin = v),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ],

            // ── Insurance section ──
            if (_type == AccountType.insurance) ...[
              const SizedBox(height: 16),
              const _SectionHeader(title: '保险信息'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _insPolicyType,
                decoration: const InputDecoration(labelText: '保单类型'),
                items: const [
                  DropdownMenuItem(value: 'life', child: Text('寿险')),
                  DropdownMenuItem(value: 'health', child: Text('健康险')),
                  DropdownMenuItem(value: 'property', child: Text('财产险')),
                  DropdownMenuItem(value: 'annuity', child: Text('年金')),
                ],
                onChanged: (v) => setState(() => _insPolicyType = v ?? 'life'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _insRegNoCtrl,
                decoration: const InputDecoration(
                  labelText: '保险机构注册号（可选）',
                ),
              ),
            ],

            // ── Payment section ──
            if (_type == AccountType.payment) ...[
              const SizedBox(height: 16),
              const _SectionHeader(title: '支付平台信息'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _payPlatformCtrl,
                decoration: const InputDecoration(
                  labelText: '平台名',
                  hintText: '如 alipay / wechat / paypal',
                ),
              ),
            ],

            // ── Custody section ──
            if (_type == AccountType.custody) ...[
              const SizedBox(height: 16),
              const _SectionHeader(title: '托管信息'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _custCustodianCtrl,
                decoration: const InputDecoration(
                  labelText: '托管机构名（可选）',
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _custStructure,
                decoration: const InputDecoration(labelText: '账户结构'),
                items: const [
                  DropdownMenuItem(
                      value: 'segregated', child: Text('分离账户 (Segregated)')),
                  DropdownMenuItem(
                      value: 'omnibus', child: Text('综合账户 (Omnibus)')),
                ],
                onChanged: (v) =>
                    setState(() => _custStructure = v ?? 'segregated'),
              ),
            ],

            // ── Crypto Exchange section ──
            if (_type == AccountType.cryptoExchange) ...[
              const SizedBox(height: 16),
              const _SectionHeader(title: '交易所信息'),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                title: const Text('已配置 API Key'),
                subtitle: const Text('仅标记，不存储密钥'),
                value: _cexHasApi,
                onChanged: (v) => setState(() => _cexHasApi = v),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _cexNetworksCtrl,
                decoration: const InputDecoration(
                  labelText: '支持的网络（可选）',
                  hintText: '如 ERC20, TRC20, BEP20',
                ),
              ),
            ],

            // ── Crypto Wallet section ──
            if (_type == AccountType.cryptoWallet) ...[
              const SizedBox(height: 16),
              const _SectionHeader(title: '钱包信息'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _walletType,
                decoration: const InputDecoration(labelText: '钱包类型'),
                items: const [
                  DropdownMenuItem(value: 'hot', child: Text('热钱包 (Hot)')),
                  DropdownMenuItem(value: 'cold', child: Text('冷钱包 (Cold)')),
                  DropdownMenuItem(
                      value: 'hardware', child: Text('硬件钱包 (Hardware)')),
                  DropdownMenuItem(
                      value: 'multisig', child: Text('多签钱包 (Multisig)')),
                ],
                onChanged: (v) => setState(() => _walletType = v ?? 'hot'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _walletChainCtrl,
                decoration: const InputDecoration(
                  labelText: '链网络（可选）',
                  hintText: '如 Bitcoin / Ethereum / Solana',
                ),
              ),
            ],

            // ── FX section ──
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

// ── Date picker tile ──

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.label,
    required this.date,
    required this.onChanged,
  });
  final String label;
  final DateTime? date;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: TextButton(
        onPressed: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date ?? DateTime.now(),
            firstDate: DateTime(1970),
            lastDate: DateTime.now(),
          );
          if (picked != null) onChanged(picked);
        },
        child: Text(date != null ? _fmt(date!) : '选择日期'),
      ),
    );
  }

  String _fmt(DateTime d) {
    final l = d.toLocal();
    String p(int n) => n.toString().padLeft(2, '0');
    return '${l.year}-${p(l.month)}-${p(l.day)}';
  }
}

// ── Section header ──

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Expanded(child: Divider()),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            )),
      ),
      const Expanded(child: Divider()),
    ]);
  }
}
