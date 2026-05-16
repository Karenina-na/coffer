// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account_type_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AccountTypeInfo {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountTypeInfo);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AccountTypeInfo()';
}


}

/// @nodoc
class $AccountTypeInfoCopyWith<$Res>  {
$AccountTypeInfoCopyWith(AccountTypeInfo _, $Res Function(AccountTypeInfo) __);
}


/// Adds pattern-matching-related methods to [AccountTypeInfo].
extension AccountTypeInfoPatterns on AccountTypeInfo {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( BankAccountInfo value)?  bank,TResult Function( BrokerAccountInfo value)?  broker,TResult Function( InsuranceAccountInfo value)?  insurance,TResult Function( PaymentAccountInfo value)?  payment,TResult Function( CustodyAccountInfo value)?  custody,TResult Function( CryptoExchangeInfo value)?  cryptoExchange,TResult Function( CryptoWalletInfo value)?  cryptoWallet,TResult Function( AccountNoExtraInfo value)?  none,required TResult orElse(),}){
final _that = this;
switch (_that) {
case BankAccountInfo() when bank != null:
return bank(_that);case BrokerAccountInfo() when broker != null:
return broker(_that);case InsuranceAccountInfo() when insurance != null:
return insurance(_that);case PaymentAccountInfo() when payment != null:
return payment(_that);case CustodyAccountInfo() when custody != null:
return custody(_that);case CryptoExchangeInfo() when cryptoExchange != null:
return cryptoExchange(_that);case CryptoWalletInfo() when cryptoWallet != null:
return cryptoWallet(_that);case AccountNoExtraInfo() when none != null:
return none(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( BankAccountInfo value)  bank,required TResult Function( BrokerAccountInfo value)  broker,required TResult Function( InsuranceAccountInfo value)  insurance,required TResult Function( PaymentAccountInfo value)  payment,required TResult Function( CustodyAccountInfo value)  custody,required TResult Function( CryptoExchangeInfo value)  cryptoExchange,required TResult Function( CryptoWalletInfo value)  cryptoWallet,required TResult Function( AccountNoExtraInfo value)  none,}){
final _that = this;
switch (_that) {
case BankAccountInfo():
return bank(_that);case BrokerAccountInfo():
return broker(_that);case InsuranceAccountInfo():
return insurance(_that);case PaymentAccountInfo():
return payment(_that);case CustodyAccountInfo():
return custody(_that);case CryptoExchangeInfo():
return cryptoExchange(_that);case CryptoWalletInfo():
return cryptoWallet(_that);case AccountNoExtraInfo():
return none(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( BankAccountInfo value)?  bank,TResult? Function( BrokerAccountInfo value)?  broker,TResult? Function( InsuranceAccountInfo value)?  insurance,TResult? Function( PaymentAccountInfo value)?  payment,TResult? Function( CustodyAccountInfo value)?  custody,TResult? Function( CryptoExchangeInfo value)?  cryptoExchange,TResult? Function( CryptoWalletInfo value)?  cryptoWallet,TResult? Function( AccountNoExtraInfo value)?  none,}){
final _that = this;
switch (_that) {
case BankAccountInfo() when bank != null:
return bank(_that);case BrokerAccountInfo() when broker != null:
return broker(_that);case InsuranceAccountInfo() when insurance != null:
return insurance(_that);case PaymentAccountInfo() when payment != null:
return payment(_that);case CustodyAccountInfo() when custody != null:
return custody(_that);case CryptoExchangeInfo() when cryptoExchange != null:
return cryptoExchange(_that);case CryptoWalletInfo() when cryptoWallet != null:
return cryptoWallet(_that);case AccountNoExtraInfo() when none != null:
return none(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String? swiftBic,  String? iban,  String? branchName,  String? accountSubtype)?  bank,TResult Function( String? accountSubtype,  String? baseCurrency,  bool marginEnabled)?  broker,TResult Function( String? policyType,  String? registrationNo)?  insurance,TResult Function( String? platform,  String? linkedAccountId)?  payment,TResult Function( String? custodianName,  String? accountStructure)?  custody,TResult Function( bool hasApiKey,  String? supportedNetworks)?  cryptoExchange,TResult Function( String? walletType,  String? chain)?  cryptoWallet,TResult Function()?  none,required TResult orElse(),}) {final _that = this;
switch (_that) {
case BankAccountInfo() when bank != null:
return bank(_that.swiftBic,_that.iban,_that.branchName,_that.accountSubtype);case BrokerAccountInfo() when broker != null:
return broker(_that.accountSubtype,_that.baseCurrency,_that.marginEnabled);case InsuranceAccountInfo() when insurance != null:
return insurance(_that.policyType,_that.registrationNo);case PaymentAccountInfo() when payment != null:
return payment(_that.platform,_that.linkedAccountId);case CustodyAccountInfo() when custody != null:
return custody(_that.custodianName,_that.accountStructure);case CryptoExchangeInfo() when cryptoExchange != null:
return cryptoExchange(_that.hasApiKey,_that.supportedNetworks);case CryptoWalletInfo() when cryptoWallet != null:
return cryptoWallet(_that.walletType,_that.chain);case AccountNoExtraInfo() when none != null:
return none();case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String? swiftBic,  String? iban,  String? branchName,  String? accountSubtype)  bank,required TResult Function( String? accountSubtype,  String? baseCurrency,  bool marginEnabled)  broker,required TResult Function( String? policyType,  String? registrationNo)  insurance,required TResult Function( String? platform,  String? linkedAccountId)  payment,required TResult Function( String? custodianName,  String? accountStructure)  custody,required TResult Function( bool hasApiKey,  String? supportedNetworks)  cryptoExchange,required TResult Function( String? walletType,  String? chain)  cryptoWallet,required TResult Function()  none,}) {final _that = this;
switch (_that) {
case BankAccountInfo():
return bank(_that.swiftBic,_that.iban,_that.branchName,_that.accountSubtype);case BrokerAccountInfo():
return broker(_that.accountSubtype,_that.baseCurrency,_that.marginEnabled);case InsuranceAccountInfo():
return insurance(_that.policyType,_that.registrationNo);case PaymentAccountInfo():
return payment(_that.platform,_that.linkedAccountId);case CustodyAccountInfo():
return custody(_that.custodianName,_that.accountStructure);case CryptoExchangeInfo():
return cryptoExchange(_that.hasApiKey,_that.supportedNetworks);case CryptoWalletInfo():
return cryptoWallet(_that.walletType,_that.chain);case AccountNoExtraInfo():
return none();}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String? swiftBic,  String? iban,  String? branchName,  String? accountSubtype)?  bank,TResult? Function( String? accountSubtype,  String? baseCurrency,  bool marginEnabled)?  broker,TResult? Function( String? policyType,  String? registrationNo)?  insurance,TResult? Function( String? platform,  String? linkedAccountId)?  payment,TResult? Function( String? custodianName,  String? accountStructure)?  custody,TResult? Function( bool hasApiKey,  String? supportedNetworks)?  cryptoExchange,TResult? Function( String? walletType,  String? chain)?  cryptoWallet,TResult? Function()?  none,}) {final _that = this;
switch (_that) {
case BankAccountInfo() when bank != null:
return bank(_that.swiftBic,_that.iban,_that.branchName,_that.accountSubtype);case BrokerAccountInfo() when broker != null:
return broker(_that.accountSubtype,_that.baseCurrency,_that.marginEnabled);case InsuranceAccountInfo() when insurance != null:
return insurance(_that.policyType,_that.registrationNo);case PaymentAccountInfo() when payment != null:
return payment(_that.platform,_that.linkedAccountId);case CustodyAccountInfo() when custody != null:
return custody(_that.custodianName,_that.accountStructure);case CryptoExchangeInfo() when cryptoExchange != null:
return cryptoExchange(_that.hasApiKey,_that.supportedNetworks);case CryptoWalletInfo() when cryptoWallet != null:
return cryptoWallet(_that.walletType,_that.chain);case AccountNoExtraInfo() when none != null:
return none();case _:
  return null;

}
}

}

/// @nodoc


class BankAccountInfo implements AccountTypeInfo {
  const BankAccountInfo({this.swiftBic, this.iban, this.branchName, this.accountSubtype});
  

/// SWIFT / BIC 代码
 final  String? swiftBic;
/// IBAN
 final  String? iban;
/// 分行名称
 final  String? branchName;
/// 账户子类型：checking / savings / timeDeposit
 final  String? accountSubtype;

/// Create a copy of AccountTypeInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BankAccountInfoCopyWith<BankAccountInfo> get copyWith => _$BankAccountInfoCopyWithImpl<BankAccountInfo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BankAccountInfo&&(identical(other.swiftBic, swiftBic) || other.swiftBic == swiftBic)&&(identical(other.iban, iban) || other.iban == iban)&&(identical(other.branchName, branchName) || other.branchName == branchName)&&(identical(other.accountSubtype, accountSubtype) || other.accountSubtype == accountSubtype));
}


@override
int get hashCode => Object.hash(runtimeType,swiftBic,iban,branchName,accountSubtype);

@override
String toString() {
  return 'AccountTypeInfo.bank(swiftBic: $swiftBic, iban: $iban, branchName: $branchName, accountSubtype: $accountSubtype)';
}


}

/// @nodoc
abstract mixin class $BankAccountInfoCopyWith<$Res> implements $AccountTypeInfoCopyWith<$Res> {
  factory $BankAccountInfoCopyWith(BankAccountInfo value, $Res Function(BankAccountInfo) _then) = _$BankAccountInfoCopyWithImpl;
@useResult
$Res call({
 String? swiftBic, String? iban, String? branchName, String? accountSubtype
});




}
/// @nodoc
class _$BankAccountInfoCopyWithImpl<$Res>
    implements $BankAccountInfoCopyWith<$Res> {
  _$BankAccountInfoCopyWithImpl(this._self, this._then);

  final BankAccountInfo _self;
  final $Res Function(BankAccountInfo) _then;

/// Create a copy of AccountTypeInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? swiftBic = freezed,Object? iban = freezed,Object? branchName = freezed,Object? accountSubtype = freezed,}) {
  return _then(BankAccountInfo(
swiftBic: freezed == swiftBic ? _self.swiftBic : swiftBic // ignore: cast_nullable_to_non_nullable
as String?,iban: freezed == iban ? _self.iban : iban // ignore: cast_nullable_to_non_nullable
as String?,branchName: freezed == branchName ? _self.branchName : branchName // ignore: cast_nullable_to_non_nullable
as String?,accountSubtype: freezed == accountSubtype ? _self.accountSubtype : accountSubtype // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class BrokerAccountInfo implements AccountTypeInfo {
  const BrokerAccountInfo({this.accountSubtype, this.baseCurrency, this.marginEnabled = false});
  

/// 账户子类型：margin / cash / retirement / education
 final  String? accountSubtype;
/// 基础结算币种
 final  String? baseCurrency;
/// 是否开通保证金
@JsonKey() final  bool marginEnabled;

/// Create a copy of AccountTypeInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BrokerAccountInfoCopyWith<BrokerAccountInfo> get copyWith => _$BrokerAccountInfoCopyWithImpl<BrokerAccountInfo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BrokerAccountInfo&&(identical(other.accountSubtype, accountSubtype) || other.accountSubtype == accountSubtype)&&(identical(other.baseCurrency, baseCurrency) || other.baseCurrency == baseCurrency)&&(identical(other.marginEnabled, marginEnabled) || other.marginEnabled == marginEnabled));
}


@override
int get hashCode => Object.hash(runtimeType,accountSubtype,baseCurrency,marginEnabled);

@override
String toString() {
  return 'AccountTypeInfo.broker(accountSubtype: $accountSubtype, baseCurrency: $baseCurrency, marginEnabled: $marginEnabled)';
}


}

/// @nodoc
abstract mixin class $BrokerAccountInfoCopyWith<$Res> implements $AccountTypeInfoCopyWith<$Res> {
  factory $BrokerAccountInfoCopyWith(BrokerAccountInfo value, $Res Function(BrokerAccountInfo) _then) = _$BrokerAccountInfoCopyWithImpl;
@useResult
$Res call({
 String? accountSubtype, String? baseCurrency, bool marginEnabled
});




}
/// @nodoc
class _$BrokerAccountInfoCopyWithImpl<$Res>
    implements $BrokerAccountInfoCopyWith<$Res> {
  _$BrokerAccountInfoCopyWithImpl(this._self, this._then);

  final BrokerAccountInfo _self;
  final $Res Function(BrokerAccountInfo) _then;

/// Create a copy of AccountTypeInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? accountSubtype = freezed,Object? baseCurrency = freezed,Object? marginEnabled = null,}) {
  return _then(BrokerAccountInfo(
accountSubtype: freezed == accountSubtype ? _self.accountSubtype : accountSubtype // ignore: cast_nullable_to_non_nullable
as String?,baseCurrency: freezed == baseCurrency ? _self.baseCurrency : baseCurrency // ignore: cast_nullable_to_non_nullable
as String?,marginEnabled: null == marginEnabled ? _self.marginEnabled : marginEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class InsuranceAccountInfo implements AccountTypeInfo {
  const InsuranceAccountInfo({this.policyType, this.registrationNo});
  

/// 保单类型：life / health / property / annuity
 final  String? policyType;
/// 保险机构注册号
 final  String? registrationNo;

/// Create a copy of AccountTypeInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InsuranceAccountInfoCopyWith<InsuranceAccountInfo> get copyWith => _$InsuranceAccountInfoCopyWithImpl<InsuranceAccountInfo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InsuranceAccountInfo&&(identical(other.policyType, policyType) || other.policyType == policyType)&&(identical(other.registrationNo, registrationNo) || other.registrationNo == registrationNo));
}


@override
int get hashCode => Object.hash(runtimeType,policyType,registrationNo);

@override
String toString() {
  return 'AccountTypeInfo.insurance(policyType: $policyType, registrationNo: $registrationNo)';
}


}

/// @nodoc
abstract mixin class $InsuranceAccountInfoCopyWith<$Res> implements $AccountTypeInfoCopyWith<$Res> {
  factory $InsuranceAccountInfoCopyWith(InsuranceAccountInfo value, $Res Function(InsuranceAccountInfo) _then) = _$InsuranceAccountInfoCopyWithImpl;
@useResult
$Res call({
 String? policyType, String? registrationNo
});




}
/// @nodoc
class _$InsuranceAccountInfoCopyWithImpl<$Res>
    implements $InsuranceAccountInfoCopyWith<$Res> {
  _$InsuranceAccountInfoCopyWithImpl(this._self, this._then);

  final InsuranceAccountInfo _self;
  final $Res Function(InsuranceAccountInfo) _then;

/// Create a copy of AccountTypeInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? policyType = freezed,Object? registrationNo = freezed,}) {
  return _then(InsuranceAccountInfo(
policyType: freezed == policyType ? _self.policyType : policyType // ignore: cast_nullable_to_non_nullable
as String?,registrationNo: freezed == registrationNo ? _self.registrationNo : registrationNo // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class PaymentAccountInfo implements AccountTypeInfo {
  const PaymentAccountInfo({this.platform, this.linkedAccountId});
  

/// 平台名：alipay / wechat / paypal / stripe
 final  String? platform;
/// 关联银行账户 ID（本系统内）
 final  String? linkedAccountId;

/// Create a copy of AccountTypeInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentAccountInfoCopyWith<PaymentAccountInfo> get copyWith => _$PaymentAccountInfoCopyWithImpl<PaymentAccountInfo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentAccountInfo&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.linkedAccountId, linkedAccountId) || other.linkedAccountId == linkedAccountId));
}


@override
int get hashCode => Object.hash(runtimeType,platform,linkedAccountId);

@override
String toString() {
  return 'AccountTypeInfo.payment(platform: $platform, linkedAccountId: $linkedAccountId)';
}


}

/// @nodoc
abstract mixin class $PaymentAccountInfoCopyWith<$Res> implements $AccountTypeInfoCopyWith<$Res> {
  factory $PaymentAccountInfoCopyWith(PaymentAccountInfo value, $Res Function(PaymentAccountInfo) _then) = _$PaymentAccountInfoCopyWithImpl;
@useResult
$Res call({
 String? platform, String? linkedAccountId
});




}
/// @nodoc
class _$PaymentAccountInfoCopyWithImpl<$Res>
    implements $PaymentAccountInfoCopyWith<$Res> {
  _$PaymentAccountInfoCopyWithImpl(this._self, this._then);

  final PaymentAccountInfo _self;
  final $Res Function(PaymentAccountInfo) _then;

/// Create a copy of AccountTypeInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? platform = freezed,Object? linkedAccountId = freezed,}) {
  return _then(PaymentAccountInfo(
platform: freezed == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String?,linkedAccountId: freezed == linkedAccountId ? _self.linkedAccountId : linkedAccountId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class CustodyAccountInfo implements AccountTypeInfo {
  const CustodyAccountInfo({this.custodianName, this.accountStructure});
  

/// 托管机构名（可不同于 institutionName）
 final  String? custodianName;
/// 账户结构：segregated / omnibus
 final  String? accountStructure;

/// Create a copy of AccountTypeInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustodyAccountInfoCopyWith<CustodyAccountInfo> get copyWith => _$CustodyAccountInfoCopyWithImpl<CustodyAccountInfo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustodyAccountInfo&&(identical(other.custodianName, custodianName) || other.custodianName == custodianName)&&(identical(other.accountStructure, accountStructure) || other.accountStructure == accountStructure));
}


@override
int get hashCode => Object.hash(runtimeType,custodianName,accountStructure);

@override
String toString() {
  return 'AccountTypeInfo.custody(custodianName: $custodianName, accountStructure: $accountStructure)';
}


}

/// @nodoc
abstract mixin class $CustodyAccountInfoCopyWith<$Res> implements $AccountTypeInfoCopyWith<$Res> {
  factory $CustodyAccountInfoCopyWith(CustodyAccountInfo value, $Res Function(CustodyAccountInfo) _then) = _$CustodyAccountInfoCopyWithImpl;
@useResult
$Res call({
 String? custodianName, String? accountStructure
});




}
/// @nodoc
class _$CustodyAccountInfoCopyWithImpl<$Res>
    implements $CustodyAccountInfoCopyWith<$Res> {
  _$CustodyAccountInfoCopyWithImpl(this._self, this._then);

  final CustodyAccountInfo _self;
  final $Res Function(CustodyAccountInfo) _then;

/// Create a copy of AccountTypeInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? custodianName = freezed,Object? accountStructure = freezed,}) {
  return _then(CustodyAccountInfo(
custodianName: freezed == custodianName ? _self.custodianName : custodianName // ignore: cast_nullable_to_non_nullable
as String?,accountStructure: freezed == accountStructure ? _self.accountStructure : accountStructure // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class CryptoExchangeInfo implements AccountTypeInfo {
  const CryptoExchangeInfo({this.hasApiKey = false, this.supportedNetworks});
  

/// 是否已配置 API Key（仅标记，不存密钥）
@JsonKey() final  bool hasApiKey;
/// 支持的链网络，逗号分隔：ERC20,TRC20,BEP20
 final  String? supportedNetworks;

/// Create a copy of AccountTypeInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CryptoExchangeInfoCopyWith<CryptoExchangeInfo> get copyWith => _$CryptoExchangeInfoCopyWithImpl<CryptoExchangeInfo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CryptoExchangeInfo&&(identical(other.hasApiKey, hasApiKey) || other.hasApiKey == hasApiKey)&&(identical(other.supportedNetworks, supportedNetworks) || other.supportedNetworks == supportedNetworks));
}


@override
int get hashCode => Object.hash(runtimeType,hasApiKey,supportedNetworks);

@override
String toString() {
  return 'AccountTypeInfo.cryptoExchange(hasApiKey: $hasApiKey, supportedNetworks: $supportedNetworks)';
}


}

/// @nodoc
abstract mixin class $CryptoExchangeInfoCopyWith<$Res> implements $AccountTypeInfoCopyWith<$Res> {
  factory $CryptoExchangeInfoCopyWith(CryptoExchangeInfo value, $Res Function(CryptoExchangeInfo) _then) = _$CryptoExchangeInfoCopyWithImpl;
@useResult
$Res call({
 bool hasApiKey, String? supportedNetworks
});




}
/// @nodoc
class _$CryptoExchangeInfoCopyWithImpl<$Res>
    implements $CryptoExchangeInfoCopyWith<$Res> {
  _$CryptoExchangeInfoCopyWithImpl(this._self, this._then);

  final CryptoExchangeInfo _self;
  final $Res Function(CryptoExchangeInfo) _then;

/// Create a copy of AccountTypeInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? hasApiKey = null,Object? supportedNetworks = freezed,}) {
  return _then(CryptoExchangeInfo(
hasApiKey: null == hasApiKey ? _self.hasApiKey : hasApiKey // ignore: cast_nullable_to_non_nullable
as bool,supportedNetworks: freezed == supportedNetworks ? _self.supportedNetworks : supportedNetworks // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class CryptoWalletInfo implements AccountTypeInfo {
  const CryptoWalletInfo({this.walletType, this.chain});
  

/// 钱包类型：hot / cold / hardware / multisig
 final  String? walletType;
/// 链网络：Bitcoin / Ethereum / Solana
 final  String? chain;

/// Create a copy of AccountTypeInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CryptoWalletInfoCopyWith<CryptoWalletInfo> get copyWith => _$CryptoWalletInfoCopyWithImpl<CryptoWalletInfo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CryptoWalletInfo&&(identical(other.walletType, walletType) || other.walletType == walletType)&&(identical(other.chain, chain) || other.chain == chain));
}


@override
int get hashCode => Object.hash(runtimeType,walletType,chain);

@override
String toString() {
  return 'AccountTypeInfo.cryptoWallet(walletType: $walletType, chain: $chain)';
}


}

/// @nodoc
abstract mixin class $CryptoWalletInfoCopyWith<$Res> implements $AccountTypeInfoCopyWith<$Res> {
  factory $CryptoWalletInfoCopyWith(CryptoWalletInfo value, $Res Function(CryptoWalletInfo) _then) = _$CryptoWalletInfoCopyWithImpl;
@useResult
$Res call({
 String? walletType, String? chain
});




}
/// @nodoc
class _$CryptoWalletInfoCopyWithImpl<$Res>
    implements $CryptoWalletInfoCopyWith<$Res> {
  _$CryptoWalletInfoCopyWithImpl(this._self, this._then);

  final CryptoWalletInfo _self;
  final $Res Function(CryptoWalletInfo) _then;

/// Create a copy of AccountTypeInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? walletType = freezed,Object? chain = freezed,}) {
  return _then(CryptoWalletInfo(
walletType: freezed == walletType ? _self.walletType : walletType // ignore: cast_nullable_to_non_nullable
as String?,chain: freezed == chain ? _self.chain : chain // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class AccountNoExtraInfo implements AccountTypeInfo {
  const AccountNoExtraInfo();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountNoExtraInfo);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AccountTypeInfo.none()';
}


}




// dart format on
