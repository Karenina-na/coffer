import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/dict_picker_field.dart';
import '../../../core/ui/enum_labels.dart';
import '../../../core/ui/error_localizer.dart';
import '../../../domain/entities/account.dart';
import '../../../domain/entities/asset.dart';
import '../../../domain/entities/asset_enums.dart';
import '../../../domain/entities/dict_type.dart';
import '../../account/presentation/account_providers.dart';
import 'asset_providers.dart';

/// 资产创建 / 编辑页。
///
/// - `initial == null`：创建，走 `CreateAssetUseCase`。
/// - `initial != null`：编辑，保留 id / createdAt，调用 `repository.update`。
///   在编辑态归属账户字段置为只读（跨账户迁移不在本页支持）。
class AssetCreatePage extends ConsumerStatefulWidget {
  const AssetCreatePage({super.key, this.initial});

  final Asset? initial;

  @override
  ConsumerState<AssetCreatePage> createState() => _AssetCreatePageState();
}

class _AssetCreatePageState extends ConsumerState<AssetCreatePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _costCtrl;
  late final TextEditingController _priceCtrl;

  late String _currency;
  late AssetType _type;
  String? _accountId;
  bool _submitting = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final a = widget.initial;
    _codeCtrl = TextEditingController(text: a?.assetCode ?? '');
    _qtyCtrl = TextEditingController(text: a?.quantity.toString() ?? '');
    _costCtrl = TextEditingController(text: a?.costPrice?.toString() ?? '');
    _priceCtrl = TextEditingController(text: a?.currentPrice?.toString() ?? '');
    _currency = a?.currency ?? 'CNY';
    _type = a?.assetType ?? AssetType.stock;
    _accountId = a?.accountId;
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _qtyCtrl.dispose();
    _costCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Decimal? _parse(String raw) {
    if (raw.trim().isEmpty) return null;
    return Decimal.tryParse(raw.trim());
  }

  /// 各类资产代码的示例（占位符）。
  static String _codeHintFor(AssetType type) {
    switch (type) {
      case AssetType.stock:
      case AssetType.equity:
        return '如 0700.HK / 600519.SS / AAPL';
      case AssetType.fund:
        return '如 510300.SS / 001186';
      case AssetType.bond:
        return '如 113008.SS / 128036.SZ';
      case AssetType.crypto:
        return '如 BTC-USD / ETH-USDT';
      case AssetType.perpetual:
        return '如 BTCUSDT / ETHUSDT';
      case AssetType.preciousMetal:
        return '如 XAU / GC=F / AU9999.SS';
      case AssetType.fxAsset:
        return '如 USD / EUR / JPY';
      case AssetType.future:
        return '如 CL=F / GC=F';
      case AssetType.option:
      case AssetType.warrant:
        return '如 AAPL240621C00180000';
      case AssetType.cd:
      case AssetType.policy:
      case AssetType.contract:
        return '自定义编号，不参与行情同步';
    }
  }

  /// 各类资产代码的书写规则说明（helperText，可折行）。
  static String _codeHelperFor(AssetType type) {
    switch (type) {
      case AssetType.stock:
      case AssetType.equity:
        return '港股加 .HK（4-5 位数字）；A股沪市 .SS 或 .SH，深市 .SZ；'
            '美股纯字母代码即可（如 AAPL、MSFT）；英/日/韩/新可用 .L / .T / .KS / .SI';
      case AssetType.fund:
        return '场内 ETF 用交易所代码（.SS / .SZ / .HK）；'
            '场外公募基金填 6 位基金代码（目前仅人工维护净值）';
      case AssetType.bond:
        return '交易所可转债 / 国债用 .SS / .SZ 后缀（如沪可转债 11XXXX.SS，深可转债 12XXXX.SZ）';
      case AssetType.crypto:
        return '推荐使用 {BASE}-{QUOTE}（如 BTC-USD），兜底走 Yahoo Finance 加密频道';
      case AssetType.perpetual:
        return '币安永续合约符号（无分隔，如 BTCUSDT、ETHUSDT）';
      case AssetType.preciousMetal:
        return 'Yahoo 期货代码（GC=F 金 / SI=F 银）或上交所现货（AU9999.SS）';
      case AssetType.fxAsset:
        return '3 位 ISO 币种代码，估值走 Frankfurter 汇率（以账户币种为计量）';
      case AssetType.future:
        return 'Yahoo 期货代码，形如 CL=F（原油）、GC=F（黄金）、NQ=F（纳指）';
      case AssetType.option:
      case AssetType.warrant:
        return 'OCC 标准代码：标的+到期(YYMMDD)+C/P+行权价(×1000, 8 位)';
      case AssetType.cd:
      case AssetType.policy:
      case AssetType.contract:
        return '此类资产不走外部行情，代码仅作记录用。价格请在「当前价」手动维护';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_accountId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请选择账户')));
      return;
    }
    final qty = _parse(_qtyCtrl.text);
    if (qty == null) return;

    setState(() => _submitting = true);
    final code =
        _codeCtrl.text.trim().isEmpty ? null : _codeCtrl.text.trim();
    final costPrice = _parse(_costCtrl.text);
    final currentPrice = _parse(_priceCtrl.text);
    final ccy = _currency.toUpperCase();

    if (_isEdit) {
      final prev = widget.initial!;
      final now = DateTime.now();
      final marketValue =
          currentPrice != null ? currentPrice * qty : prev.marketValue;
      final valuationTime = currentPrice != null ? now : prev.valuationTime;
      final updated = prev.copyWith(
        assetType: _type,
        assetCode: code,
        quantity: qty,
        costPrice: costPrice,
        currentPrice: currentPrice,
        currency: ccy,
        marketValue: marketValue,
        valuationTime: valuationTime,
        updatedAt: now,
      );
      final result = await ref
          .read(updateAssetUseCaseProvider)
          .call(prev: prev, next: updated);
      if (!mounted) return;
      setState(() => _submitting = false);
      result.when(
        ok: (_) => context.pop(),
        err: (e) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失败: ${errorToMessage(e)}')),
        ),
      );
    } else {
      final result = await ref.read(createAssetUseCaseProvider)(
        accountId: _accountId!,
        assetType: _type,
        quantity: qty,
        currency: ccy,
        assetCode: code,
        costPrice: costPrice,
        currentPrice: currentPrice,
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
    final accounts = ref.watch(accountListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? '编辑资产' : '新建资产')),
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
                onChanged: _isEdit
                    ? null
                    : (v) => setState(() => _accountId = v),
                readOnly: _isEdit,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AssetType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: '资产类型'),
              items: AssetType.values
                  .map((t) =>
                      DropdownMenuItem(value: t, child: Text(t.labelBilingual)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _codeCtrl,
              decoration: InputDecoration(
                labelText: '资产代码（可选）',
                hintText: _codeHintFor(_type),
                helperText: _codeHelperFor(_type),
                helperMaxLines: 4,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _qtyCtrl,
              decoration: const InputDecoration(labelText: '数量'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                final d = _parse(v ?? '');
                if (d == null) return '请输入有效数字';
                if (d < Decimal.zero) return '必须 ≥ 0';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DictPickerField(
              type: DictType.currency,
              value: _currency,
              label: '币种',
              helperText: '估值币种；可在 设置 → 字典 维护',
              onChanged: (v) => setState(() {
                if (v != null) _currency = v;
              }),
              validator: (v) =>
                  (v == null || v.isEmpty) ? '必选' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _costCtrl,
              decoration: const InputDecoration(labelText: '成本价（可选）'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final d = Decimal.tryParse(v.trim());
                if (d == null) return '无效的数字格式';
                if (d < Decimal.zero) return '不能为负数';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceCtrl,
              decoration: const InputDecoration(
                labelText: '当前价（可选）',
                helperText: '提供后会自动计算 market_value 快照',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final d = Decimal.tryParse(v.trim());
                if (d == null) return '无效的数字格式';
                if (d < Decimal.zero) return '不能为负数';
                return null;
              },
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
    if (accounts.isEmpty) {
      return const Text('暂无可选账户，请先创建账户');
    }
    return DropdownButtonFormField<String>(
      initialValue: selected,
      decoration: InputDecoration(
        labelText: '归属账户',
        helperText: readOnly ? '编辑时不可迁移账户' : null,
      ),
      items: accounts
          .map((a) => DropdownMenuItem(
                value: a.id,
                child: Text('${a.institutionName} · ${a.accountType.labelZh}'),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}
