import 'package:flutter/material.dart';

/// 按发卡组织返回品牌渐变配色，用于钱包卡片面板。
///
/// 未知组织回退到中性深色渐变。
class BrandTheme {
  const BrandTheme({
    required this.gradient,
    required this.onColor,
    required this.label,
  });

  final LinearGradient gradient;
  final Color onColor;
  final String label;

  static BrandTheme of(String organization) {
    final key = organization.trim().toUpperCase();
    return _lookup[key] ?? _fallback;
  }

  static const _fallback = BrandTheme(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2E2E38), Color(0xFF111118)],
    ),
    onColor: Colors.white,
    label: 'CARD',
  );

  static const _lookup = <String, BrandTheme>{
    'VISA': BrandTheme(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1A1F71), Color(0xFF0B0D4A)],
      ),
      onColor: Colors.white,
      label: 'VISA',
    ),
    'MASTERCARD': BrandTheme(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFEB001B), Color(0xFFF79E1B)],
      ),
      onColor: Colors.white,
      label: 'Mastercard',
    ),
    'AMEX': BrandTheme(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2E77BB), Color(0xFF006FCF)],
      ),
      onColor: Colors.white,
      label: 'AMERICAN EXPRESS',
    ),
    'AMERICAN EXPRESS': BrandTheme(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2E77BB), Color(0xFF006FCF)],
      ),
      onColor: Colors.white,
      label: 'AMERICAN EXPRESS',
    ),
    'UNIONPAY': BrandTheme(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE21836), Color(0xFF00447C)],
      ),
      onColor: Colors.white,
      label: '银联',
    ),
    'JCB': BrandTheme(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0E4C92), Color(0xFFC8102E)],
      ),
      onColor: Colors.white,
      label: 'JCB',
    ),
    'DISCOVER': BrandTheme(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF6000), Color(0xFFCC4F00)],
      ),
      onColor: Colors.white,
      label: 'DISCOVER',
    ),
  };
}
