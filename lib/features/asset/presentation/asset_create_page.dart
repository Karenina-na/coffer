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
import '../../../domain/entities/asset_type_info.dart';
import '../../../domain/entities/dict_type.dart';
import '../../account/presentation/account_providers.dart';
import 'asset_providers.dart';

/// 资产创建 / 编辑页。
///
/// - `initial == null`：创建，走 `CreateAssetUseCase`。
/// - `initial != null`：编辑，保留 id / createdAt，调用 `repository.update`。
///   在编辑态归属账户字段置为只读（跨账户迁移不在本页支持）。
class AssetCreatePage extends ConsumerStatefulWidget {
  const AssetCreatePage({
    super.key,
    this.initial,
    this.initialAccountId,
    this.lockAccountSelection = false,
  });

  final Asset? initial;
  final String? initialAccountId;
  final bool lockAccountSelection;

  @override
  ConsumerState<AssetCreatePage> createState() => _AssetCreatePageState();
}

class _AssetCreatePageState extends ConsumerState<AssetCreatePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _costCtrl;
  late final TextEditingController _priceCtrl;

  // Type-specific controllers — always live, values swapped in initState.
  late final TextEditingController _fiIssuerCtrl;
  late final TextEditingController _fiRateCtrl;
  late final TextEditingController _fiStartCtrl;
  late final TextEditingController _fiMaturityCtrl;
  late final TextEditingController _insInsurerCtrl;
  late final TextEditingController _insPolicyNoCtrl;
  late final TextEditingController _insPremiumCtrl;
  late final TextEditingController _insCoverageCtrl;
  late final TextEditingController _insEffDateCtrl;
  late final TextEditingController _insMatDateCtrl;
  late final TextEditingController _pmWeightCtrl;
  late final TextEditingController _pmPurityCtrl;

  late String _currency;
  late AssetType _type;
  String? _accountId;
  bool _submitting = false;

  // Type-specific state (non-text)
  String _fiCompounding = 'simple';
  int _fiDayCount = 365;
  DateTime? _fiStartDate;
  DateTime? _fiMaturityDate;
  String _insPaymentFreq = 'annual';
  DateTime? _insEffDate;
  DateTime? _insMatDate;
  String _pmMetalType = 'gold';

  bool get _isEdit => widget.initial != null;
  bool get _isAccountLocked => _isEdit || widget.lockAccountSelection;

  bool get _showCostPrice => switch (_type) {
        AssetType.cd => false,
        AssetType.policy => false,
        _ => true,
      };

  bool get _showCurrentPrice => switch (_type) {
        AssetType.cd || AssetType.bond => false,
        _ => true,
      };

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
    _accountId = a?.accountId ?? widget.initialAccountId;
    _fiIssuerCtrl = TextEditingController();
    _fiRateCtrl = TextEditingController();
    _fiStartCtrl = TextEditingController();
    _fiMaturityCtrl = TextEditingController();
    _insInsurerCtrl = TextEditingController();
    _insPolicyNoCtrl = TextEditingController();
    _insPremiumCtrl = TextEditingController();
    _insCoverageCtrl = TextEditingController();
    _insEffDateCtrl = TextEditingController();
    _insMatDateCtrl = TextEditingController();
    _pmWeightCtrl = TextEditingController();
    _pmPurityCtrl = TextEditingController();
    _loadTypeInfo(a?.typeInfo);
  }

  void _loadTypeInfo(AssetTypeInfo? info) {
    if (info == null) return;
    if (info is FixedIncomeInfo) {
      _fiIssuerCtrl.text = info.issuer ?? '';
      _fiRateCtrl.text = info.annualRate != null
            ? (info.annualRate! * Decimal.fromInt(100)).toString()
            : '';
      _fiStartDate = info.startDate;
      _fiStartCtrl.text = info.startDate != null ? _fmtDate(info.startDate!) : '';
      _fiMaturityDate = info.maturityDate;
      _fiMaturityCtrl.text = info.maturityDate != null ? _fmtDate(info.maturityDate!) : '';
      _fiCompounding = info.compounding ?? 'simple';
      _fiDayCount = info.dayCount ?? 365;
    } else if (info is InsuranceInfo) {
      _insInsurerCtrl.text = info.insurer ?? '';
      _insPolicyNoCtrl.text = info.policyNumber ?? '';
      _insPremiumCtrl.text = info.annualPremium?.toString() ?? '';
      _insCoverageCtrl.text = info.coverage?.toString() ?? '';
      _insEffDate = info.effectiveDate;
      _insEffDateCtrl.text = info.effectiveDate != null ? _fmtDate(info.effectiveDate!) : '';
      _insMatDate = info.maturityDate;
      _insMatDateCtrl.text = info.maturityDate != null ? _fmtDate(info.maturityDate!) : '';
      _insPaymentFreq = info.paymentFrequency ?? 'annual';
    } else if (info is PreciousMetalInfo) {
      _pmMetalType = info.metalType ?? 'gold';
      _pmWeightCtrl.text = info.weight?.toString() ?? '';
      _pmPurityCtrl.text = info.purity?.toString() ?? '';
    }
  }

  AssetTypeInfo _collectTypeInfo() {
    switch (_type) {
      case AssetType.cd:
      case AssetType.bond:
        final rawRate = _parse(_fiRateCtrl.text);
        return FixedIncomeInfo(
          issuer: _fiIssuerCtrl.text.trim().isEmpty ? null : _fiIssuerCtrl.text.trim(),
          annualRate: rawRate != null
              ? (rawRate / Decimal.fromInt(100)).toDecimal(
                  scaleOnInfinitePrecision: 10,
                )
              : null,
          startDate: _fiStartDate,
          maturityDate: _fiMaturityDate,
          compounding: _fiCompounding,
          dayCount: _fiDayCount,
        );
      case AssetType.policy:
        return InsuranceInfo(
          insurer: _insInsurerCtrl.text.trim().isEmpty ? null : _insInsurerCtrl.text.trim(),
          policyNumber: _insPolicyNoCtrl.text.trim().isEmpty ? null : _insPolicyNoCtrl.text.trim(),
          annualPremium: _parse(_insPremiumCtrl.text),
          coverage: _parse(_insCoverageCtrl.text),
          effectiveDate: _insEffDate,
          maturityDate: _insMatDate,
          paymentFrequency: _insPaymentFreq,
        );
      case AssetType.preciousMetal:
        return PreciousMetalInfo(
          metalType: _pmMetalType,
          weight: _parse(_pmWeightCtrl.text),
          purity: _parse(_pmPurityCtrl.text),
        );
      default:
        return const NoExtraInfo();
    }
  }

  static String _fmtDate(DateTime d) {
    final l = d.toLocal();
    String p(int n) => n.toString().padLeft(2, '0');
    return '${l.year}-${p(l.month)}-${p(l.day)}';
  }

  Future<void> _pickDate(DateTime? current, ValueChanged<DateTime> onPicked) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(2000),
      lastDate: now.add(const Duration(days: 365 * 30)),
    );
    if (picked != null) onPicked(picked);
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _qtyCtrl.dispose();
    _costCtrl.dispose();
    _priceCtrl.dispose();
    _fiIssuerCtrl.dispose();
    _fiRateCtrl.dispose();
    _fiStartCtrl.dispose();
    _fiMaturityCtrl.dispose();
    _insInsurerCtrl.dispose();
    _insPolicyNoCtrl.dispose();
    _insPremiumCtrl.dispose();
    _insCoverageCtrl.dispose();
    _insEffDateCtrl.dispose();
    _insMatDateCtrl.dispose();
    _pmWeightCtrl.dispose();
    _pmPurityCtrl.dispose();
    super.dispose();
  }

  Decimal? _parse(String raw) {
    if (raw.trim().isEmpty) return null;
    return Decimal.tryParse(raw.trim());
  }

  /// 数量字段标签：不同资产含义不同。
  String _qtyLabel() => switch (_type) {
        AssetType.stock || AssetType.equity => '持仓股数',
        AssetType.fund => '持有份额',
        AssetType.crypto => '持仓数量',
        AssetType.perpetual => '持仓张数',
        AssetType.future => '持仓手数',
        AssetType.option || AssetType.warrant => '持仓张数',
        AssetType.cd => '本金',
        AssetType.bond => '面值总额',
        AssetType.policy => '保额',
        AssetType.preciousMetal => '重量（克）',
        AssetType.fxAsset => '持仓金额',
        AssetType.contract => '数量',
      };

  String _qtyHelper() => switch (_type) {
        AssetType.stock || AssetType.equity => '持有的股票股数',
        AssetType.fund => '持有的基金份额',
        AssetType.cd => '存单本金（币种金额）',
        AssetType.bond => '债券面值总额',
        AssetType.policy => '保险赔付金额',
        AssetType.preciousMetal => '实物贵金属总克重',
        AssetType.fxAsset => '外汇持仓的计价金额',
        _ => '',
      };

  String _costLabel() => switch (_type) {
        AssetType.stock || AssetType.equity => '成本价（每股）',
        AssetType.fund => '成本价（每份）',
        AssetType.crypto => '成本价（每币）',
        AssetType.perpetual || AssetType.future => '开仓均价',
        AssetType.option || AssetType.warrant => '权利金（每张）',
        AssetType.preciousMetal => '成本价（每克）',
        AssetType.fxAsset => '建仓汇率',
        _ => '成本价',
      };

  String _priceLabel() => switch (_type) {
        AssetType.stock || AssetType.equity => '当前价（每股）',
        AssetType.fund => '当前净值（每份）',
        AssetType.crypto => '当前价（每币）',
        AssetType.perpetual || AssetType.future => '标记价格',
        AssetType.option || AssetType.warrant => '最新价（每张）',
        AssetType.policy => '现金价值',
        AssetType.preciousMetal => '当前价（每克）',
        AssetType.fxAsset => '当前汇率',
        _ => '当前价',
      };

  String _priceHelper() => switch (_type) {
        AssetType.stock || AssetType.equity || AssetType.fund ||
        AssetType.crypto ||
        AssetType.preciousMetal =>
          '填写后自动计算 market_value = 数量 × 当前价',
        _ => '提供后会自动计算 market_value 快照',
      };

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
    final costPrice = _showCostPrice ? _parse(_costCtrl.text) : null;
    final currentPrice = _showCurrentPrice ? _parse(_priceCtrl.text) : null;
    final ccy = _currency.toUpperCase();
    final typeInfo = _collectTypeInfo();

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
      ).copyWithTypeInfo(typeInfo);
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
              data: (list) {
                final hasSelected = _accountId != null && list.any((a) => a.id == _accountId);
                if (!hasSelected && !_isEdit && widget.initialAccountId != null && _accountId != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() => _accountId = null);
                  });
                }
                return _AccountPicker(
                  accounts: list,
                  selected: hasSelected ? _accountId : null,
                  onChanged: _isAccountLocked
                      ? null
                      : (v) => setState(() => _accountId = v),
                  readOnly: _isAccountLocked && hasSelected,
                  helperText: widget.lockAccountSelection && !hasSelected
                      ? '预选账户不可用，请重新选择'
                      : null,
                );
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AssetType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: '资产类型'),
              items: AssetType.values
                  .map((t) =>
                      DropdownMenuItem(value: t, child: Text(t.labelBilingual)))
                  .toList(),
              onChanged: (v) => setState(() {
                _type = v ?? _type;
                _loadTypeInfo(AssetTypeInfo.defaultFor(_type));
              }),
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
              decoration: InputDecoration(
                labelText: _qtyLabel(),
                helperText: _qtyHelper().isEmpty ? null : _qtyHelper(),
              ),
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
              helperText: _type == AssetType.cd || _type == AssetType.bond
                  ? '本金币种 & 估值币种'
                  : '计价 & 估值币种；可在 设置 → 字典 维护',
              onChanged: (v) => setState(() {
                if (v != null) _currency = v;
              }),
              validator: (v) =>
                  (v == null || v.isEmpty) ? '必选' : null,
            ),
            // ── Fixed income section ──
            if (_type == AssetType.cd || _type == AssetType.bond) ...[
              const SizedBox(height: 16),
              const _SectionHeader(title: '固收信息'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _fiRateCtrl,
                decoration: const InputDecoration(
                  labelText: '年利率 (%)',
                  hintText: '如 3.5 表示年利率 3.5%',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _fiStartCtrl,
                      decoration: const InputDecoration(
                        labelText: '起息日（可选）',
                        hintText: '缺省为创建日期',
                      ),
                      readOnly: true,
                      onTap: () => _pickDate(_fiStartDate, (d) {
                        setState(() {
                          _fiStartDate = d;
                          _fiStartCtrl.text = _fmtDate(d);
                        });
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _fiMaturityCtrl,
                      decoration: const InputDecoration(labelText: '到期日（可选）'),
                      readOnly: true,
                      onTap: () => _pickDate(_fiMaturityDate, (d) {
                        setState(() {
                          _fiMaturityDate = d;
                          _fiMaturityCtrl.text = _fmtDate(d);
                        });
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _fiCompounding,
                      decoration: const InputDecoration(labelText: '计息方式'),
                      items: const [
                        DropdownMenuItem(value: 'simple', child: Text('到期一次性还本付息')),
                        DropdownMenuItem(value: 'daily', child: Text('按日复利')),
                        DropdownMenuItem(value: 'monthly', child: Text('按月复利')),
                        DropdownMenuItem(value: 'annual', child: Text('按年复利')),
                      ],
                      onChanged: (v) => setState(() => _fiCompounding = v ?? 'simple'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _fiDayCount,
                      decoration: const InputDecoration(labelText: '计息基准'),
                      items: const [
                        DropdownMenuItem(value: 365, child: Text('365 天')),
                        DropdownMenuItem(value: 360, child: Text('360 天')),
                      ],
                      onChanged: (v) => setState(() => _fiDayCount = v ?? 365),
                    ),
                  ),
                ],
              ),
            ],
            // ── Insurance section ──
            if (_type == AssetType.policy) ...[
              const SizedBox(height: 16),
              const _SectionHeader(title: '保单信息'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _insInsurerCtrl,
                decoration: const InputDecoration(
                  labelText: '保险公司',
                  hintText: '如 中国人寿',
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _insPolicyNoCtrl,
                decoration: const InputDecoration(
                  labelText: '保单号（可选）',
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _insPremiumCtrl,
                decoration: const InputDecoration(
                  labelText: '年缴保费（可选）',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _insCoverageCtrl,
                decoration: const InputDecoration(
                  labelText: '保额（可选）',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _insEffDateCtrl,
                      decoration: const InputDecoration(labelText: '生效日期（可选）'),
                      readOnly: true,
                      onTap: () => _pickDate(_insEffDate, (d) {
                        setState(() {
                          _insEffDate = d;
                          _insEffDateCtrl.text = _fmtDate(d);
                        });
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _insMatDateCtrl,
                      decoration: const InputDecoration(labelText: '满期日期（可选）'),
                      readOnly: true,
                      onTap: () => _pickDate(_insMatDate, (d) {
                        setState(() {
                          _insMatDate = d;
                          _insMatDateCtrl.text = _fmtDate(d);
                        });
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _insPaymentFreq,
                decoration: const InputDecoration(labelText: '缴费频率'),
                items: const [
                  DropdownMenuItem(value: 'monthly', child: Text('月缴')),
                  DropdownMenuItem(value: 'quarterly', child: Text('季缴')),
                  DropdownMenuItem(value: 'semiAnnual', child: Text('半年缴')),
                  DropdownMenuItem(value: 'annual', child: Text('年缴')),
                  DropdownMenuItem(value: 'single', child: Text('趸缴')),
                ],
                onChanged: (v) => setState(() => _insPaymentFreq = v ?? 'annual'),
              ),
            ],
            // ── Precious metal section ──
            if (_type == AssetType.preciousMetal) ...[
              const SizedBox(height: 16),
              const _SectionHeader(title: '贵金属信息'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _pmMetalType,
                decoration: const InputDecoration(labelText: '品种'),
                items: const [
                  DropdownMenuItem(value: 'gold', child: Text('黄金')),
                  DropdownMenuItem(value: 'silver', child: Text('白银')),
                  DropdownMenuItem(value: 'platinum', child: Text('铂金')),
                  DropdownMenuItem(value: 'palladium', child: Text('钯金')),
                ],
                onChanged: (v) => setState(() => _pmMetalType = v ?? 'gold'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _pmWeightCtrl,
                decoration: const InputDecoration(
                  labelText: '重量（克，可选）',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _pmPurityCtrl,
                decoration: const InputDecoration(
                  labelText: '纯度（可选）',
                  hintText: '如 0.9999',
                  helperText: '0–1 之间，如 99.99% 填 0.9999',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
            // ── 成本价 ──
            if (_showCostPrice) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _costCtrl,
                decoration: InputDecoration(labelText: _costLabel()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final d = Decimal.tryParse(v.trim());
                  if (d == null) return '无效的数字格式';
                  if (d < Decimal.zero) return '不能为负数';
                  return null;
                },
              ),
            ],
            // ── 当前价 ──
            if (_showCurrentPrice) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceCtrl,
                decoration: InputDecoration(
                  labelText: _priceLabel(),
                  helperText: _priceHelper(),
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
            ],
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
    this.helperText,
  });

  final List<Account> accounts;
  final String? selected;
  final ValueChanged<String?>? onChanged;
  final bool readOnly;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return const Text('暂无可选账户，请先创建账户');
    }
    return DropdownButtonFormField<String>(
      initialValue: selected,
      decoration: InputDecoration(
        labelText: '归属账户',
        helperText: helperText ?? (readOnly ? '当前入口已锁定归属账户' : null),
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
