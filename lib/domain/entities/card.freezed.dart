// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'card.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BankCard {

 String get id; String get accountId; String get cardOrganization; String get cardNoMasked; String? get cardNoCiphertext; CardType get cardType; int get expireMonth; int get expireYear; String? get cvvCiphertext; String get issuerName; String? get currency; bool get supportsAllCurrencies; List<String> get supportedCurrencies; Decimal? get creditLimit; Decimal? get availableCredit; int? get billingCycleDay; int? get paymentDueDay; String? get billingAddress; bool get isVirtual; CardStatus get status; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of BankCard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BankCardCopyWith<BankCard> get copyWith => _$BankCardCopyWithImpl<BankCard>(this as BankCard, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BankCard&&(identical(other.id, id) || other.id == id)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.cardOrganization, cardOrganization) || other.cardOrganization == cardOrganization)&&(identical(other.cardNoMasked, cardNoMasked) || other.cardNoMasked == cardNoMasked)&&(identical(other.cardNoCiphertext, cardNoCiphertext) || other.cardNoCiphertext == cardNoCiphertext)&&(identical(other.cardType, cardType) || other.cardType == cardType)&&(identical(other.expireMonth, expireMonth) || other.expireMonth == expireMonth)&&(identical(other.expireYear, expireYear) || other.expireYear == expireYear)&&(identical(other.cvvCiphertext, cvvCiphertext) || other.cvvCiphertext == cvvCiphertext)&&(identical(other.issuerName, issuerName) || other.issuerName == issuerName)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.supportsAllCurrencies, supportsAllCurrencies) || other.supportsAllCurrencies == supportsAllCurrencies)&&const DeepCollectionEquality().equals(other.supportedCurrencies, supportedCurrencies)&&(identical(other.creditLimit, creditLimit) || other.creditLimit == creditLimit)&&(identical(other.availableCredit, availableCredit) || other.availableCredit == availableCredit)&&(identical(other.billingCycleDay, billingCycleDay) || other.billingCycleDay == billingCycleDay)&&(identical(other.paymentDueDay, paymentDueDay) || other.paymentDueDay == paymentDueDay)&&(identical(other.billingAddress, billingAddress) || other.billingAddress == billingAddress)&&(identical(other.isVirtual, isVirtual) || other.isVirtual == isVirtual)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,accountId,cardOrganization,cardNoMasked,cardNoCiphertext,cardType,expireMonth,expireYear,cvvCiphertext,issuerName,currency,supportsAllCurrencies,const DeepCollectionEquality().hash(supportedCurrencies),creditLimit,availableCredit,billingCycleDay,paymentDueDay,billingAddress,isVirtual,status,createdAt,updatedAt]);



}

/// @nodoc
abstract mixin class $BankCardCopyWith<$Res>  {
  factory $BankCardCopyWith(BankCard value, $Res Function(BankCard) _then) = _$BankCardCopyWithImpl;
@useResult
$Res call({
 String id, String accountId, String cardOrganization, String cardNoMasked, String? cardNoCiphertext, CardType cardType, int expireMonth, int expireYear, String? cvvCiphertext, String issuerName, String? currency, bool supportsAllCurrencies, List<String> supportedCurrencies, Decimal? creditLimit, Decimal? availableCredit, int? billingCycleDay, int? paymentDueDay, String? billingAddress, bool isVirtual, CardStatus status, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$BankCardCopyWithImpl<$Res>
    implements $BankCardCopyWith<$Res> {
  _$BankCardCopyWithImpl(this._self, this._then);

  final BankCard _self;
  final $Res Function(BankCard) _then;

/// Create a copy of BankCard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? accountId = null,Object? cardOrganization = null,Object? cardNoMasked = null,Object? cardNoCiphertext = freezed,Object? cardType = null,Object? expireMonth = null,Object? expireYear = null,Object? cvvCiphertext = freezed,Object? issuerName = null,Object? currency = freezed,Object? supportsAllCurrencies = null,Object? supportedCurrencies = null,Object? creditLimit = freezed,Object? availableCredit = freezed,Object? billingCycleDay = freezed,Object? paymentDueDay = freezed,Object? billingAddress = freezed,Object? isVirtual = null,Object? status = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,cardOrganization: null == cardOrganization ? _self.cardOrganization : cardOrganization // ignore: cast_nullable_to_non_nullable
as String,cardNoMasked: null == cardNoMasked ? _self.cardNoMasked : cardNoMasked // ignore: cast_nullable_to_non_nullable
as String,cardNoCiphertext: freezed == cardNoCiphertext ? _self.cardNoCiphertext : cardNoCiphertext // ignore: cast_nullable_to_non_nullable
as String?,cardType: null == cardType ? _self.cardType : cardType // ignore: cast_nullable_to_non_nullable
as CardType,expireMonth: null == expireMonth ? _self.expireMonth : expireMonth // ignore: cast_nullable_to_non_nullable
as int,expireYear: null == expireYear ? _self.expireYear : expireYear // ignore: cast_nullable_to_non_nullable
as int,cvvCiphertext: freezed == cvvCiphertext ? _self.cvvCiphertext : cvvCiphertext // ignore: cast_nullable_to_non_nullable
as String?,issuerName: null == issuerName ? _self.issuerName : issuerName // ignore: cast_nullable_to_non_nullable
as String,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String?,supportsAllCurrencies: null == supportsAllCurrencies ? _self.supportsAllCurrencies : supportsAllCurrencies // ignore: cast_nullable_to_non_nullable
as bool,supportedCurrencies: null == supportedCurrencies ? _self.supportedCurrencies : supportedCurrencies // ignore: cast_nullable_to_non_nullable
as List<String>,creditLimit: freezed == creditLimit ? _self.creditLimit : creditLimit // ignore: cast_nullable_to_non_nullable
as Decimal?,availableCredit: freezed == availableCredit ? _self.availableCredit : availableCredit // ignore: cast_nullable_to_non_nullable
as Decimal?,billingCycleDay: freezed == billingCycleDay ? _self.billingCycleDay : billingCycleDay // ignore: cast_nullable_to_non_nullable
as int?,paymentDueDay: freezed == paymentDueDay ? _self.paymentDueDay : paymentDueDay // ignore: cast_nullable_to_non_nullable
as int?,billingAddress: freezed == billingAddress ? _self.billingAddress : billingAddress // ignore: cast_nullable_to_non_nullable
as String?,isVirtual: null == isVirtual ? _self.isVirtual : isVirtual // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CardStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [BankCard].
extension BankCardPatterns on BankCard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BankCard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BankCard() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BankCard value)  $default,){
final _that = this;
switch (_that) {
case _BankCard():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BankCard value)?  $default,){
final _that = this;
switch (_that) {
case _BankCard() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String accountId,  String cardOrganization,  String cardNoMasked,  String? cardNoCiphertext,  CardType cardType,  int expireMonth,  int expireYear,  String? cvvCiphertext,  String issuerName,  String? currency,  bool supportsAllCurrencies,  List<String> supportedCurrencies,  Decimal? creditLimit,  Decimal? availableCredit,  int? billingCycleDay,  int? paymentDueDay,  String? billingAddress,  bool isVirtual,  CardStatus status,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BankCard() when $default != null:
return $default(_that.id,_that.accountId,_that.cardOrganization,_that.cardNoMasked,_that.cardNoCiphertext,_that.cardType,_that.expireMonth,_that.expireYear,_that.cvvCiphertext,_that.issuerName,_that.currency,_that.supportsAllCurrencies,_that.supportedCurrencies,_that.creditLimit,_that.availableCredit,_that.billingCycleDay,_that.paymentDueDay,_that.billingAddress,_that.isVirtual,_that.status,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String accountId,  String cardOrganization,  String cardNoMasked,  String? cardNoCiphertext,  CardType cardType,  int expireMonth,  int expireYear,  String? cvvCiphertext,  String issuerName,  String? currency,  bool supportsAllCurrencies,  List<String> supportedCurrencies,  Decimal? creditLimit,  Decimal? availableCredit,  int? billingCycleDay,  int? paymentDueDay,  String? billingAddress,  bool isVirtual,  CardStatus status,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _BankCard():
return $default(_that.id,_that.accountId,_that.cardOrganization,_that.cardNoMasked,_that.cardNoCiphertext,_that.cardType,_that.expireMonth,_that.expireYear,_that.cvvCiphertext,_that.issuerName,_that.currency,_that.supportsAllCurrencies,_that.supportedCurrencies,_that.creditLimit,_that.availableCredit,_that.billingCycleDay,_that.paymentDueDay,_that.billingAddress,_that.isVirtual,_that.status,_that.createdAt,_that.updatedAt);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String accountId,  String cardOrganization,  String cardNoMasked,  String? cardNoCiphertext,  CardType cardType,  int expireMonth,  int expireYear,  String? cvvCiphertext,  String issuerName,  String? currency,  bool supportsAllCurrencies,  List<String> supportedCurrencies,  Decimal? creditLimit,  Decimal? availableCredit,  int? billingCycleDay,  int? paymentDueDay,  String? billingAddress,  bool isVirtual,  CardStatus status,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _BankCard() when $default != null:
return $default(_that.id,_that.accountId,_that.cardOrganization,_that.cardNoMasked,_that.cardNoCiphertext,_that.cardType,_that.expireMonth,_that.expireYear,_that.cvvCiphertext,_that.issuerName,_that.currency,_that.supportsAllCurrencies,_that.supportedCurrencies,_that.creditLimit,_that.availableCredit,_that.billingCycleDay,_that.paymentDueDay,_that.billingAddress,_that.isVirtual,_that.status,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _BankCard extends BankCard {
  const _BankCard({required this.id, required this.accountId, required this.cardOrganization, required this.cardNoMasked, this.cardNoCiphertext, required this.cardType, required this.expireMonth, required this.expireYear, this.cvvCiphertext, required this.issuerName, this.currency, this.supportsAllCurrencies = false, final  List<String> supportedCurrencies = const <String>[], this.creditLimit, this.availableCredit, this.billingCycleDay, this.paymentDueDay, this.billingAddress, this.isVirtual = false, required this.status, required this.createdAt, required this.updatedAt}): _supportedCurrencies = supportedCurrencies,super._();
  

@override final  String id;
@override final  String accountId;
@override final  String cardOrganization;
@override final  String cardNoMasked;
@override final  String? cardNoCiphertext;
@override final  CardType cardType;
@override final  int expireMonth;
@override final  int expireYear;
@override final  String? cvvCiphertext;
@override final  String issuerName;
@override final  String? currency;
@override@JsonKey() final  bool supportsAllCurrencies;
 final  List<String> _supportedCurrencies;
@override@JsonKey() List<String> get supportedCurrencies {
  if (_supportedCurrencies is EqualUnmodifiableListView) return _supportedCurrencies;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_supportedCurrencies);
}

@override final  Decimal? creditLimit;
@override final  Decimal? availableCredit;
@override final  int? billingCycleDay;
@override final  int? paymentDueDay;
@override final  String? billingAddress;
@override@JsonKey() final  bool isVirtual;
@override final  CardStatus status;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of BankCard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BankCardCopyWith<_BankCard> get copyWith => __$BankCardCopyWithImpl<_BankCard>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BankCard&&(identical(other.id, id) || other.id == id)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.cardOrganization, cardOrganization) || other.cardOrganization == cardOrganization)&&(identical(other.cardNoMasked, cardNoMasked) || other.cardNoMasked == cardNoMasked)&&(identical(other.cardNoCiphertext, cardNoCiphertext) || other.cardNoCiphertext == cardNoCiphertext)&&(identical(other.cardType, cardType) || other.cardType == cardType)&&(identical(other.expireMonth, expireMonth) || other.expireMonth == expireMonth)&&(identical(other.expireYear, expireYear) || other.expireYear == expireYear)&&(identical(other.cvvCiphertext, cvvCiphertext) || other.cvvCiphertext == cvvCiphertext)&&(identical(other.issuerName, issuerName) || other.issuerName == issuerName)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.supportsAllCurrencies, supportsAllCurrencies) || other.supportsAllCurrencies == supportsAllCurrencies)&&const DeepCollectionEquality().equals(other._supportedCurrencies, _supportedCurrencies)&&(identical(other.creditLimit, creditLimit) || other.creditLimit == creditLimit)&&(identical(other.availableCredit, availableCredit) || other.availableCredit == availableCredit)&&(identical(other.billingCycleDay, billingCycleDay) || other.billingCycleDay == billingCycleDay)&&(identical(other.paymentDueDay, paymentDueDay) || other.paymentDueDay == paymentDueDay)&&(identical(other.billingAddress, billingAddress) || other.billingAddress == billingAddress)&&(identical(other.isVirtual, isVirtual) || other.isVirtual == isVirtual)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,accountId,cardOrganization,cardNoMasked,cardNoCiphertext,cardType,expireMonth,expireYear,cvvCiphertext,issuerName,currency,supportsAllCurrencies,const DeepCollectionEquality().hash(_supportedCurrencies),creditLimit,availableCredit,billingCycleDay,paymentDueDay,billingAddress,isVirtual,status,createdAt,updatedAt]);



}

/// @nodoc
abstract mixin class _$BankCardCopyWith<$Res> implements $BankCardCopyWith<$Res> {
  factory _$BankCardCopyWith(_BankCard value, $Res Function(_BankCard) _then) = __$BankCardCopyWithImpl;
@override @useResult
$Res call({
 String id, String accountId, String cardOrganization, String cardNoMasked, String? cardNoCiphertext, CardType cardType, int expireMonth, int expireYear, String? cvvCiphertext, String issuerName, String? currency, bool supportsAllCurrencies, List<String> supportedCurrencies, Decimal? creditLimit, Decimal? availableCredit, int? billingCycleDay, int? paymentDueDay, String? billingAddress, bool isVirtual, CardStatus status, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$BankCardCopyWithImpl<$Res>
    implements _$BankCardCopyWith<$Res> {
  __$BankCardCopyWithImpl(this._self, this._then);

  final _BankCard _self;
  final $Res Function(_BankCard) _then;

/// Create a copy of BankCard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? accountId = null,Object? cardOrganization = null,Object? cardNoMasked = null,Object? cardNoCiphertext = freezed,Object? cardType = null,Object? expireMonth = null,Object? expireYear = null,Object? cvvCiphertext = freezed,Object? issuerName = null,Object? currency = freezed,Object? supportsAllCurrencies = null,Object? supportedCurrencies = null,Object? creditLimit = freezed,Object? availableCredit = freezed,Object? billingCycleDay = freezed,Object? paymentDueDay = freezed,Object? billingAddress = freezed,Object? isVirtual = null,Object? status = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_BankCard(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,cardOrganization: null == cardOrganization ? _self.cardOrganization : cardOrganization // ignore: cast_nullable_to_non_nullable
as String,cardNoMasked: null == cardNoMasked ? _self.cardNoMasked : cardNoMasked // ignore: cast_nullable_to_non_nullable
as String,cardNoCiphertext: freezed == cardNoCiphertext ? _self.cardNoCiphertext : cardNoCiphertext // ignore: cast_nullable_to_non_nullable
as String?,cardType: null == cardType ? _self.cardType : cardType // ignore: cast_nullable_to_non_nullable
as CardType,expireMonth: null == expireMonth ? _self.expireMonth : expireMonth // ignore: cast_nullable_to_non_nullable
as int,expireYear: null == expireYear ? _self.expireYear : expireYear // ignore: cast_nullable_to_non_nullable
as int,cvvCiphertext: freezed == cvvCiphertext ? _self.cvvCiphertext : cvvCiphertext // ignore: cast_nullable_to_non_nullable
as String?,issuerName: null == issuerName ? _self.issuerName : issuerName // ignore: cast_nullable_to_non_nullable
as String,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String?,supportsAllCurrencies: null == supportsAllCurrencies ? _self.supportsAllCurrencies : supportsAllCurrencies // ignore: cast_nullable_to_non_nullable
as bool,supportedCurrencies: null == supportedCurrencies ? _self._supportedCurrencies : supportedCurrencies // ignore: cast_nullable_to_non_nullable
as List<String>,creditLimit: freezed == creditLimit ? _self.creditLimit : creditLimit // ignore: cast_nullable_to_non_nullable
as Decimal?,availableCredit: freezed == availableCredit ? _self.availableCredit : availableCredit // ignore: cast_nullable_to_non_nullable
as Decimal?,billingCycleDay: freezed == billingCycleDay ? _self.billingCycleDay : billingCycleDay // ignore: cast_nullable_to_non_nullable
as int?,paymentDueDay: freezed == paymentDueDay ? _self.paymentDueDay : paymentDueDay // ignore: cast_nullable_to_non_nullable
as int?,billingAddress: freezed == billingAddress ? _self.billingAddress : billingAddress // ignore: cast_nullable_to_non_nullable
as String?,isVirtual: null == isVirtual ? _self.isVirtual : isVirtual // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CardStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
