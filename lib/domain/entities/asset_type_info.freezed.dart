// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'asset_type_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AssetTypeInfo {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssetTypeInfo);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AssetTypeInfo()';
}


}

/// @nodoc
class $AssetTypeInfoCopyWith<$Res>  {
$AssetTypeInfoCopyWith(AssetTypeInfo _, $Res Function(AssetTypeInfo) __);
}


/// Adds pattern-matching-related methods to [AssetTypeInfo].
extension AssetTypeInfoPatterns on AssetTypeInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( FixedIncomeInfo value)?  fixedIncome,TResult Function( InsuranceInfo value)?  insurance,TResult Function( PreciousMetalInfo value)?  preciousMetal,TResult Function( NoExtraInfo value)?  none,required TResult orElse(),}){
final _that = this;
switch (_that) {
case FixedIncomeInfo() when fixedIncome != null:
return fixedIncome(_that);case InsuranceInfo() when insurance != null:
return insurance(_that);case PreciousMetalInfo() when preciousMetal != null:
return preciousMetal(_that);case NoExtraInfo() when none != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( FixedIncomeInfo value)  fixedIncome,required TResult Function( InsuranceInfo value)  insurance,required TResult Function( PreciousMetalInfo value)  preciousMetal,required TResult Function( NoExtraInfo value)  none,}){
final _that = this;
switch (_that) {
case FixedIncomeInfo():
return fixedIncome(_that);case InsuranceInfo():
return insurance(_that);case PreciousMetalInfo():
return preciousMetal(_that);case NoExtraInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( FixedIncomeInfo value)?  fixedIncome,TResult? Function( InsuranceInfo value)?  insurance,TResult? Function( PreciousMetalInfo value)?  preciousMetal,TResult? Function( NoExtraInfo value)?  none,}){
final _that = this;
switch (_that) {
case FixedIncomeInfo() when fixedIncome != null:
return fixedIncome(_that);case InsuranceInfo() when insurance != null:
return insurance(_that);case PreciousMetalInfo() when preciousMetal != null:
return preciousMetal(_that);case NoExtraInfo() when none != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String? issuer,  Decimal? annualRate,  DateTime? startDate,  DateTime? maturityDate,  String? compounding,  int? dayCount)?  fixedIncome,TResult Function( String? insurer,  String? policyNumber,  Decimal? annualPremium,  Decimal? coverage,  DateTime? effectiveDate,  DateTime? maturityDate,  String? paymentFrequency)?  insurance,TResult Function( String? metalType,  Decimal? weight,  Decimal? purity)?  preciousMetal,TResult Function()?  none,required TResult orElse(),}) {final _that = this;
switch (_that) {
case FixedIncomeInfo() when fixedIncome != null:
return fixedIncome(_that.issuer,_that.annualRate,_that.startDate,_that.maturityDate,_that.compounding,_that.dayCount);case InsuranceInfo() when insurance != null:
return insurance(_that.insurer,_that.policyNumber,_that.annualPremium,_that.coverage,_that.effectiveDate,_that.maturityDate,_that.paymentFrequency);case PreciousMetalInfo() when preciousMetal != null:
return preciousMetal(_that.metalType,_that.weight,_that.purity);case NoExtraInfo() when none != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String? issuer,  Decimal? annualRate,  DateTime? startDate,  DateTime? maturityDate,  String? compounding,  int? dayCount)  fixedIncome,required TResult Function( String? insurer,  String? policyNumber,  Decimal? annualPremium,  Decimal? coverage,  DateTime? effectiveDate,  DateTime? maturityDate,  String? paymentFrequency)  insurance,required TResult Function( String? metalType,  Decimal? weight,  Decimal? purity)  preciousMetal,required TResult Function()  none,}) {final _that = this;
switch (_that) {
case FixedIncomeInfo():
return fixedIncome(_that.issuer,_that.annualRate,_that.startDate,_that.maturityDate,_that.compounding,_that.dayCount);case InsuranceInfo():
return insurance(_that.insurer,_that.policyNumber,_that.annualPremium,_that.coverage,_that.effectiveDate,_that.maturityDate,_that.paymentFrequency);case PreciousMetalInfo():
return preciousMetal(_that.metalType,_that.weight,_that.purity);case NoExtraInfo():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String? issuer,  Decimal? annualRate,  DateTime? startDate,  DateTime? maturityDate,  String? compounding,  int? dayCount)?  fixedIncome,TResult? Function( String? insurer,  String? policyNumber,  Decimal? annualPremium,  Decimal? coverage,  DateTime? effectiveDate,  DateTime? maturityDate,  String? paymentFrequency)?  insurance,TResult? Function( String? metalType,  Decimal? weight,  Decimal? purity)?  preciousMetal,TResult? Function()?  none,}) {final _that = this;
switch (_that) {
case FixedIncomeInfo() when fixedIncome != null:
return fixedIncome(_that.issuer,_that.annualRate,_that.startDate,_that.maturityDate,_that.compounding,_that.dayCount);case InsuranceInfo() when insurance != null:
return insurance(_that.insurer,_that.policyNumber,_that.annualPremium,_that.coverage,_that.effectiveDate,_that.maturityDate,_that.paymentFrequency);case PreciousMetalInfo() when preciousMetal != null:
return preciousMetal(_that.metalType,_that.weight,_that.purity);case NoExtraInfo() when none != null:
return none();case _:
  return null;

}
}

}

/// @nodoc


class FixedIncomeInfo implements AssetTypeInfo {
  const FixedIncomeInfo({this.issuer, this.annualRate, this.startDate, this.maturityDate, this.compounding, this.dayCount});
  

/// 发行机构 / 银行
 final  String? issuer;
/// 年化利率小数，如 0.035 表示 3.5%
 final  Decimal? annualRate;
/// 计息起始日（缺省用 createdAt）
 final  DateTime? startDate;
/// 到期日（到期后停止计息）
 final  DateTime? maturityDate;
/// 计息方式：'simple' | 'daily' | 'monthly' | 'annual'
/// CD 缺省 simple，BOND 缺省 annual
 final  String? compounding;
/// 计息基准天数，缺省 365
 final  int? dayCount;

/// Create a copy of AssetTypeInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FixedIncomeInfoCopyWith<FixedIncomeInfo> get copyWith => _$FixedIncomeInfoCopyWithImpl<FixedIncomeInfo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FixedIncomeInfo&&(identical(other.issuer, issuer) || other.issuer == issuer)&&(identical(other.annualRate, annualRate) || other.annualRate == annualRate)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.maturityDate, maturityDate) || other.maturityDate == maturityDate)&&(identical(other.compounding, compounding) || other.compounding == compounding)&&(identical(other.dayCount, dayCount) || other.dayCount == dayCount));
}


@override
int get hashCode => Object.hash(runtimeType,issuer,annualRate,startDate,maturityDate,compounding,dayCount);

@override
String toString() {
  return 'AssetTypeInfo.fixedIncome(issuer: $issuer, annualRate: $annualRate, startDate: $startDate, maturityDate: $maturityDate, compounding: $compounding, dayCount: $dayCount)';
}


}

/// @nodoc
abstract mixin class $FixedIncomeInfoCopyWith<$Res> implements $AssetTypeInfoCopyWith<$Res> {
  factory $FixedIncomeInfoCopyWith(FixedIncomeInfo value, $Res Function(FixedIncomeInfo) _then) = _$FixedIncomeInfoCopyWithImpl;
@useResult
$Res call({
 String? issuer, Decimal? annualRate, DateTime? startDate, DateTime? maturityDate, String? compounding, int? dayCount
});




}
/// @nodoc
class _$FixedIncomeInfoCopyWithImpl<$Res>
    implements $FixedIncomeInfoCopyWith<$Res> {
  _$FixedIncomeInfoCopyWithImpl(this._self, this._then);

  final FixedIncomeInfo _self;
  final $Res Function(FixedIncomeInfo) _then;

/// Create a copy of AssetTypeInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? issuer = freezed,Object? annualRate = freezed,Object? startDate = freezed,Object? maturityDate = freezed,Object? compounding = freezed,Object? dayCount = freezed,}) {
  return _then(FixedIncomeInfo(
issuer: freezed == issuer ? _self.issuer : issuer // ignore: cast_nullable_to_non_nullable
as String?,annualRate: freezed == annualRate ? _self.annualRate : annualRate // ignore: cast_nullable_to_non_nullable
as Decimal?,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,maturityDate: freezed == maturityDate ? _self.maturityDate : maturityDate // ignore: cast_nullable_to_non_nullable
as DateTime?,compounding: freezed == compounding ? _self.compounding : compounding // ignore: cast_nullable_to_non_nullable
as String?,dayCount: freezed == dayCount ? _self.dayCount : dayCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc


class InsuranceInfo implements AssetTypeInfo {
  const InsuranceInfo({this.insurer, this.policyNumber, this.annualPremium, this.coverage, this.effectiveDate, this.maturityDate, this.paymentFrequency});
  

/// 保险公司
 final  String? insurer;
/// 保单号
 final  String? policyNumber;
/// 年缴保费
 final  Decimal? annualPremium;
/// 保额
 final  Decimal? coverage;
/// 生效日期
 final  DateTime? effectiveDate;
/// 满期 / 到期日期
 final  DateTime? maturityDate;
/// 缴费频率：'monthly' | 'quarterly' | 'semiAnnual' | 'annual' | 'single'
 final  String? paymentFrequency;

/// Create a copy of AssetTypeInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InsuranceInfoCopyWith<InsuranceInfo> get copyWith => _$InsuranceInfoCopyWithImpl<InsuranceInfo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InsuranceInfo&&(identical(other.insurer, insurer) || other.insurer == insurer)&&(identical(other.policyNumber, policyNumber) || other.policyNumber == policyNumber)&&(identical(other.annualPremium, annualPremium) || other.annualPremium == annualPremium)&&(identical(other.coverage, coverage) || other.coverage == coverage)&&(identical(other.effectiveDate, effectiveDate) || other.effectiveDate == effectiveDate)&&(identical(other.maturityDate, maturityDate) || other.maturityDate == maturityDate)&&(identical(other.paymentFrequency, paymentFrequency) || other.paymentFrequency == paymentFrequency));
}


@override
int get hashCode => Object.hash(runtimeType,insurer,policyNumber,annualPremium,coverage,effectiveDate,maturityDate,paymentFrequency);

@override
String toString() {
  return 'AssetTypeInfo.insurance(insurer: $insurer, policyNumber: $policyNumber, annualPremium: $annualPremium, coverage: $coverage, effectiveDate: $effectiveDate, maturityDate: $maturityDate, paymentFrequency: $paymentFrequency)';
}


}

/// @nodoc
abstract mixin class $InsuranceInfoCopyWith<$Res> implements $AssetTypeInfoCopyWith<$Res> {
  factory $InsuranceInfoCopyWith(InsuranceInfo value, $Res Function(InsuranceInfo) _then) = _$InsuranceInfoCopyWithImpl;
@useResult
$Res call({
 String? insurer, String? policyNumber, Decimal? annualPremium, Decimal? coverage, DateTime? effectiveDate, DateTime? maturityDate, String? paymentFrequency
});




}
/// @nodoc
class _$InsuranceInfoCopyWithImpl<$Res>
    implements $InsuranceInfoCopyWith<$Res> {
  _$InsuranceInfoCopyWithImpl(this._self, this._then);

  final InsuranceInfo _self;
  final $Res Function(InsuranceInfo) _then;

/// Create a copy of AssetTypeInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? insurer = freezed,Object? policyNumber = freezed,Object? annualPremium = freezed,Object? coverage = freezed,Object? effectiveDate = freezed,Object? maturityDate = freezed,Object? paymentFrequency = freezed,}) {
  return _then(InsuranceInfo(
insurer: freezed == insurer ? _self.insurer : insurer // ignore: cast_nullable_to_non_nullable
as String?,policyNumber: freezed == policyNumber ? _self.policyNumber : policyNumber // ignore: cast_nullable_to_non_nullable
as String?,annualPremium: freezed == annualPremium ? _self.annualPremium : annualPremium // ignore: cast_nullable_to_non_nullable
as Decimal?,coverage: freezed == coverage ? _self.coverage : coverage // ignore: cast_nullable_to_non_nullable
as Decimal?,effectiveDate: freezed == effectiveDate ? _self.effectiveDate : effectiveDate // ignore: cast_nullable_to_non_nullable
as DateTime?,maturityDate: freezed == maturityDate ? _self.maturityDate : maturityDate // ignore: cast_nullable_to_non_nullable
as DateTime?,paymentFrequency: freezed == paymentFrequency ? _self.paymentFrequency : paymentFrequency // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class PreciousMetalInfo implements AssetTypeInfo {
  const PreciousMetalInfo({this.metalType, this.weight, this.purity});
  

/// 品种：'gold' | 'silver' | 'platinum' | 'palladium'
 final  String? metalType;
/// 重量（克）
 final  Decimal? weight;
/// 纯度 (0–1)，如 0.9999
 final  Decimal? purity;

/// Create a copy of AssetTypeInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PreciousMetalInfoCopyWith<PreciousMetalInfo> get copyWith => _$PreciousMetalInfoCopyWithImpl<PreciousMetalInfo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PreciousMetalInfo&&(identical(other.metalType, metalType) || other.metalType == metalType)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.purity, purity) || other.purity == purity));
}


@override
int get hashCode => Object.hash(runtimeType,metalType,weight,purity);

@override
String toString() {
  return 'AssetTypeInfo.preciousMetal(metalType: $metalType, weight: $weight, purity: $purity)';
}


}

/// @nodoc
abstract mixin class $PreciousMetalInfoCopyWith<$Res> implements $AssetTypeInfoCopyWith<$Res> {
  factory $PreciousMetalInfoCopyWith(PreciousMetalInfo value, $Res Function(PreciousMetalInfo) _then) = _$PreciousMetalInfoCopyWithImpl;
@useResult
$Res call({
 String? metalType, Decimal? weight, Decimal? purity
});




}
/// @nodoc
class _$PreciousMetalInfoCopyWithImpl<$Res>
    implements $PreciousMetalInfoCopyWith<$Res> {
  _$PreciousMetalInfoCopyWithImpl(this._self, this._then);

  final PreciousMetalInfo _self;
  final $Res Function(PreciousMetalInfo) _then;

/// Create a copy of AssetTypeInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? metalType = freezed,Object? weight = freezed,Object? purity = freezed,}) {
  return _then(PreciousMetalInfo(
metalType: freezed == metalType ? _self.metalType : metalType // ignore: cast_nullable_to_non_nullable
as String?,weight: freezed == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as Decimal?,purity: freezed == purity ? _self.purity : purity // ignore: cast_nullable_to_non_nullable
as Decimal?,
  ));
}


}

/// @nodoc


class NoExtraInfo implements AssetTypeInfo {
  const NoExtraInfo();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NoExtraInfo);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AssetTypeInfo.none()';
}


}




// dart format on
