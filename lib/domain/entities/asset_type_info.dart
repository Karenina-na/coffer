import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'asset_enums.dart';

part 'asset_type_info.freezed.dart';

/// 资产类型专属扩展信息。
///
/// 替代裸 [Map<String, dynamic>] extInfo，按资产类型细分字段。
/// 序列化为 JSON 存入 DB [Asset.extInfo]，向后兼容现有数据。
@freezed
sealed class AssetTypeInfo with _$AssetTypeInfo {
  // ── 固收类：大额存单 / 债券 ──
  const factory AssetTypeInfo.fixedIncome({
    /// 发行机构 / 银行
    String? issuer,
    /// 年化利率小数，如 0.035 表示 3.5%
    Decimal? annualRate,
    /// 计息起始日（缺省用 createdAt）
    DateTime? startDate,
    /// 到期日（到期后停止计息）
    DateTime? maturityDate,
    /// 计息方式：'simple' | 'daily' | 'monthly' | 'annual'
    /// CD 缺省 simple，BOND 缺省 annual
    String? compounding,
    /// 计息基准天数，缺省 365
    int? dayCount,
  }) = FixedIncomeInfo;

  // ── 保险类 ──
  const factory AssetTypeInfo.insurance({
    /// 保险公司
    String? insurer,
    /// 保单号
    String? policyNumber,
    /// 年缴保费
    Decimal? annualPremium,
    /// 保额
    Decimal? coverage,
    /// 生效日期
    DateTime? effectiveDate,
    /// 满期 / 到期日期
    DateTime? maturityDate,
    /// 缴费频率：'monthly' | 'quarterly' | 'semiAnnual' | 'annual' | 'single'
    String? paymentFrequency,
  }) = InsuranceInfo;

  // ── 贵金属类 ──
  const factory AssetTypeInfo.preciousMetal({
    /// 品种：'gold' | 'silver' | 'platinum' | 'palladium'
    String? metalType,
    /// 重量（克）
    Decimal? weight,
    /// 纯度 (0–1)，如 0.9999
    Decimal? purity,
  }) = PreciousMetalInfo;

  // ── 兜底 ──
  const factory AssetTypeInfo.none() = NoExtraInfo;

  factory AssetTypeInfo.fromJson(Map<String, dynamic>? json, AssetType type) {
    if (json == null || json.isEmpty) return _defaultFor(type);
    return switch (type) {
      AssetType.cd || AssetType.bond => _fixedIncomeFromJson(json),
      AssetType.policy => _insuranceFromJson(json),
      AssetType.preciousMetal => _preciousMetalFromJson(json),
      _ => const NoExtraInfo(),
    };
  }

  /// 按资产类型返回合适的默认扩展信息。

  /// 按资产类型返回合适的默认扩展信息。
  static AssetTypeInfo defaultFor(AssetType type) => _defaultFor(type);

  static AssetTypeInfo _defaultFor(AssetType type) {
    return switch (type) {
      AssetType.cd => const FixedIncomeInfo(compounding: 'simple', dayCount: 365),
      AssetType.bond => const FixedIncomeInfo(compounding: 'annual', dayCount: 365),
      AssetType.policy => const InsuranceInfo(),
      AssetType.preciousMetal => const PreciousMetalInfo(),
      _ => const NoExtraInfo(),
    };
  }
}

// ─────────────────────────────────────────────────────────
// JSON helpers
// ─────────────────────────────────────────────────────────

FixedIncomeInfo _fixedIncomeFromJson(Map<String, dynamic> json) {
  return FixedIncomeInfo(
    issuer: _string(json['issuer']),
    annualRate: _dec(json['annualRate']),
    startDate: _dt(json['startDate']),
    maturityDate: _dt(json['maturityDate']),
    compounding: _string(json['compounding']),
    dayCount: _int(json['dayCount']),
  );
}

InsuranceInfo _insuranceFromJson(Map<String, dynamic> json) {
  return InsuranceInfo(
    insurer: _string(json['insurer']),
    policyNumber: _string(json['policyNumber']),
    annualPremium: _dec(json['annualPremium']),
    coverage: _dec(json['coverage']),
    effectiveDate: _dt(json['effectiveDate']),
    maturityDate: _dt(json['maturityDate']),
    paymentFrequency: _string(json['paymentFrequency']),
  );
}

extension AssetTypeInfoJson on AssetTypeInfo {
  Map<String, dynamic> toJson() => map(
        fixedIncome: (v) => {
          if (v.issuer != null) 'issuer': v.issuer,
          if (v.annualRate != null) 'annualRate': v.annualRate.toString(),
          if (v.startDate != null) 'startDate': v.startDate!.toIso8601String(),
          if (v.maturityDate != null)
            'maturityDate': v.maturityDate!.toIso8601String(),
          if (v.compounding != null) 'compounding': v.compounding,
          if (v.dayCount != null) 'dayCount': v.dayCount,
        },
        insurance: (v) => {
          if (v.insurer != null) 'insurer': v.insurer,
          if (v.policyNumber != null) 'policyNumber': v.policyNumber,
          if (v.annualPremium != null)
            'annualPremium': v.annualPremium.toString(),
          if (v.coverage != null) 'coverage': v.coverage.toString(),
          if (v.effectiveDate != null)
            'effectiveDate': v.effectiveDate!.toIso8601String(),
          if (v.maturityDate != null)
            'maturityDate': v.maturityDate!.toIso8601String(),
          if (v.paymentFrequency != null)
            'paymentFrequency': v.paymentFrequency,
        },
        preciousMetal: (v) => {
          if (v.metalType != null) 'metalType': v.metalType,
          if (v.weight != null) 'weight': v.weight.toString(),
          if (v.purity != null) 'purity': v.purity.toString(),
        },
        none: (_) => <String, dynamic>{},
      );
}

PreciousMetalInfo _preciousMetalFromJson(Map<String, dynamic> json) {
  return PreciousMetalInfo(
    metalType: _string(json['metalType']),
    weight: _dec(json['weight']),
    purity: _dec(json['purity']),
  );
}

String? _string(dynamic v) => v is String ? v : null;

int? _int(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

Decimal? _dec(dynamic v) {
  if (v == null) return null;
  if (v is Decimal) return v;
  if (v is num) return Decimal.parse(v.toString());
  if (v is String) {
    final s = v.trim();
    if (s.isEmpty) return null;
    return Decimal.tryParse(s);
  }
  return null;
}

DateTime? _dt(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  return null;
}
