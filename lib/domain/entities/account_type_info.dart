import 'package:freezed_annotation/freezed_annotation.dart';

import 'account_enums.dart';

part 'account_type_info.freezed.dart';

/// 账户类型专属扩展信息。
///
/// 替代裸 [Map<String, dynamic>] extInfo，按账户类型细分字段。
/// 序列化为 JSON 存入 DB [Account.extInfo]，向后兼容。
@freezed
sealed class AccountTypeInfo with _$AccountTypeInfo {
  // ── 银行账户 ──
  const factory AccountTypeInfo.bank({
    /// SWIFT / BIC 代码
    String? swiftBic,
    /// IBAN
    String? iban,
    /// 分行名称
    String? branchName,
    /// 账户子类型：checking / savings / timeDeposit
    String? accountSubtype,
  }) = BankAccountInfo;

  // ── 券商账户 ──
  const factory AccountTypeInfo.broker({
    /// 账户子类型：margin / cash / retirement / education
    String? accountSubtype,
    /// 基础结算币种
    String? baseCurrency,
    /// 是否开通保证金
    @Default(false) bool marginEnabled,
  }) = BrokerAccountInfo;

  // ── 保险账户 ──
  const factory AccountTypeInfo.insurance({
    /// 保单类型：life / health / property / annuity
    String? policyType,
    /// 保险机构注册号
    String? registrationNo,
  }) = InsuranceAccountInfo;

  // ── 支付账户 ──
  const factory AccountTypeInfo.payment({
    /// 平台名：alipay / wechat / paypal / stripe
    String? platform,
    /// 关联银行账户 ID（本系统内）
    String? linkedAccountId,
  }) = PaymentAccountInfo;

  // ── 托管账户 ──
  const factory AccountTypeInfo.custody({
    /// 托管机构名（可不同于 institutionName）
    String? custodianName,
    /// 账户结构：segregated / omnibus
    String? accountStructure,
  }) = CustodyAccountInfo;

  // ── 加密交易所 ──
  const factory AccountTypeInfo.cryptoExchange({
    /// 是否已配置 API Key（仅标记，不存密钥）
    @Default(false) bool hasApiKey,
    /// 支持的链网络，逗号分隔：ERC20,TRC20,BEP20
    String? supportedNetworks,
  }) = CryptoExchangeInfo;

  // ── 加密钱包 ──
  const factory AccountTypeInfo.cryptoWallet({
    /// 钱包类型：hot / cold / hardware / multisig
    String? walletType,
    /// 链网络：Bitcoin / Ethereum / Solana
    String? chain,
  }) = CryptoWalletInfo;

  // ── 兜底 ──
  const factory AccountTypeInfo.none() = AccountNoExtraInfo;

  factory AccountTypeInfo.fromJson(
      Map<String, dynamic>? json, AccountType type) {
    if (json == null || json.isEmpty) return _defaultFor(type);
    return switch (type) {
      AccountType.bank => _bankFromJson(json),
      AccountType.broker => _brokerFromJson(json),
      AccountType.insurance => _insuranceFromJson(json),
      AccountType.payment => _paymentFromJson(json),
      AccountType.custody => _custodyFromJson(json),
      AccountType.cryptoExchange => _cryptoExchangeFromJson(json),
      AccountType.cryptoWallet => _cryptoWalletFromJson(json),
    };
  }

  static AccountTypeInfo defaultFor(AccountType type) => _defaultFor(type);

  static AccountTypeInfo _defaultFor(AccountType type) {
    return switch (type) {
      AccountType.bank => const BankAccountInfo(),
      AccountType.broker => const BrokerAccountInfo(),
      AccountType.insurance => const InsuranceAccountInfo(),
      AccountType.payment => const PaymentAccountInfo(),
      AccountType.custody => const CustodyAccountInfo(),
      AccountType.cryptoExchange => const CryptoExchangeInfo(),
      AccountType.cryptoWallet => const CryptoWalletInfo(),
    };
  }
}

// ── JSON serialization extension ──

extension AccountTypeInfoJson on AccountTypeInfo {
  Map<String, dynamic> toJson() => map(
        bank: (v) => {
          if (v.swiftBic != null) 'swiftBic': v.swiftBic,
          if (v.iban != null) 'iban': v.iban,
          if (v.branchName != null) 'branchName': v.branchName,
          if (v.accountSubtype != null) 'accountSubtype': v.accountSubtype,
        },
        broker: (v) => {
          if (v.accountSubtype != null) 'accountSubtype': v.accountSubtype,
          if (v.baseCurrency != null) 'baseCurrency': v.baseCurrency,
          if (v.marginEnabled) 'marginEnabled': v.marginEnabled,
        },
        insurance: (v) => {
          if (v.policyType != null) 'policyType': v.policyType,
          if (v.registrationNo != null) 'registrationNo': v.registrationNo,
        },
        payment: (v) => {
          if (v.platform != null) 'platform': v.platform,
          if (v.linkedAccountId != null) 'linkedAccountId': v.linkedAccountId,
        },
        custody: (v) => {
          if (v.custodianName != null) 'custodianName': v.custodianName,
          if (v.accountStructure != null)
            'accountStructure': v.accountStructure,
        },
        cryptoExchange: (v) => {
          if (v.hasApiKey) 'hasApiKey': v.hasApiKey,
          if (v.supportedNetworks != null)
            'supportedNetworks': v.supportedNetworks,
        },
        cryptoWallet: (v) => {
          if (v.walletType != null) 'walletType': v.walletType,
          if (v.chain != null) 'chain': v.chain,
        },
        none: (_) => <String, dynamic>{},
      );
}

// ── fromJson helpers ──

BankAccountInfo _bankFromJson(Map<String, dynamic> json) {
  return BankAccountInfo(
    swiftBic: json['swiftBic'] as String?,
    iban: json['iban'] as String?,
    branchName: json['branchName'] as String?,
    accountSubtype: json['accountSubtype'] as String?,
  );
}

BrokerAccountInfo _brokerFromJson(Map<String, dynamic> json) {
  return BrokerAccountInfo(
    accountSubtype: json['accountSubtype'] as String?,
    baseCurrency: json['baseCurrency'] as String?,
    marginEnabled: json['marginEnabled'] == true,
  );
}

InsuranceAccountInfo _insuranceFromJson(Map<String, dynamic> json) {
  return InsuranceAccountInfo(
    policyType: json['policyType'] as String?,
    registrationNo: json['registrationNo'] as String?,
  );
}

PaymentAccountInfo _paymentFromJson(Map<String, dynamic> json) {
  return PaymentAccountInfo(
    platform: json['platform'] as String?,
    linkedAccountId: json['linkedAccountId'] as String?,
  );
}

CustodyAccountInfo _custodyFromJson(Map<String, dynamic> json) {
  return CustodyAccountInfo(
    custodianName: json['custodianName'] as String?,
    accountStructure: json['accountStructure'] as String?,
  );
}

CryptoExchangeInfo _cryptoExchangeFromJson(Map<String, dynamic> json) {
  return CryptoExchangeInfo(
    hasApiKey: json['hasApiKey'] == true,
    supportedNetworks: json['supportedNetworks'] as String?,
  );
}

CryptoWalletInfo _cryptoWalletFromJson(Map<String, dynamic> json) {
  return CryptoWalletInfo(
    walletType: json['walletType'] as String?,
    chain: json['chain'] as String?,
  );
}
