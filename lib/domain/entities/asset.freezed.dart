// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'asset.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Asset {

 String get id; String get accountId; AssetType get assetType; String? get assetCode; Decimal get quantity; Decimal? get costPrice; Decimal? get currentPrice; String get currency; Decimal? get marketValue; DateTime? get valuationTime; AssetStatus get status; Map<String, dynamic>? get extInfo; DateTime get createdAt; DateTime get updatedAt; bool get isDeleted;
/// Create a copy of Asset
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssetCopyWith<Asset> get copyWith => _$AssetCopyWithImpl<Asset>(this as Asset, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Asset&&(identical(other.id, id) || other.id == id)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.assetType, assetType) || other.assetType == assetType)&&(identical(other.assetCode, assetCode) || other.assetCode == assetCode)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.costPrice, costPrice) || other.costPrice == costPrice)&&(identical(other.currentPrice, currentPrice) || other.currentPrice == currentPrice)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.marketValue, marketValue) || other.marketValue == marketValue)&&(identical(other.valuationTime, valuationTime) || other.valuationTime == valuationTime)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.extInfo, extInfo)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted));
}


@override
int get hashCode => Object.hash(runtimeType,id,accountId,assetType,assetCode,quantity,costPrice,currentPrice,currency,marketValue,valuationTime,status,const DeepCollectionEquality().hash(extInfo),createdAt,updatedAt,isDeleted);

@override
String toString() {
  return 'Asset(id: $id, accountId: $accountId, assetType: $assetType, assetCode: $assetCode, quantity: $quantity, costPrice: $costPrice, currentPrice: $currentPrice, currency: $currency, marketValue: $marketValue, valuationTime: $valuationTime, status: $status, extInfo: $extInfo, createdAt: $createdAt, updatedAt: $updatedAt, isDeleted: $isDeleted)';
}


}

/// @nodoc
abstract mixin class $AssetCopyWith<$Res>  {
  factory $AssetCopyWith(Asset value, $Res Function(Asset) _then) = _$AssetCopyWithImpl;
@useResult
$Res call({
 String id, String accountId, AssetType assetType, String? assetCode, Decimal quantity, Decimal? costPrice, Decimal? currentPrice, String currency, Decimal? marketValue, DateTime? valuationTime, AssetStatus status, Map<String, dynamic>? extInfo, DateTime createdAt, DateTime updatedAt, bool isDeleted
});




}
/// @nodoc
class _$AssetCopyWithImpl<$Res>
    implements $AssetCopyWith<$Res> {
  _$AssetCopyWithImpl(this._self, this._then);

  final Asset _self;
  final $Res Function(Asset) _then;

/// Create a copy of Asset
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? accountId = null,Object? assetType = null,Object? assetCode = freezed,Object? quantity = null,Object? costPrice = freezed,Object? currentPrice = freezed,Object? currency = null,Object? marketValue = freezed,Object? valuationTime = freezed,Object? status = null,Object? extInfo = freezed,Object? createdAt = null,Object? updatedAt = null,Object? isDeleted = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,assetType: null == assetType ? _self.assetType : assetType // ignore: cast_nullable_to_non_nullable
as AssetType,assetCode: freezed == assetCode ? _self.assetCode : assetCode // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as Decimal,costPrice: freezed == costPrice ? _self.costPrice : costPrice // ignore: cast_nullable_to_non_nullable
as Decimal?,currentPrice: freezed == currentPrice ? _self.currentPrice : currentPrice // ignore: cast_nullable_to_non_nullable
as Decimal?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,marketValue: freezed == marketValue ? _self.marketValue : marketValue // ignore: cast_nullable_to_non_nullable
as Decimal?,valuationTime: freezed == valuationTime ? _self.valuationTime : valuationTime // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AssetStatus,extInfo: freezed == extInfo ? _self.extInfo : extInfo // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Asset].
extension AssetPatterns on Asset {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Asset value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Asset() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Asset value)  $default,){
final _that = this;
switch (_that) {
case _Asset():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Asset value)?  $default,){
final _that = this;
switch (_that) {
case _Asset() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String accountId,  AssetType assetType,  String? assetCode,  Decimal quantity,  Decimal? costPrice,  Decimal? currentPrice,  String currency,  Decimal? marketValue,  DateTime? valuationTime,  AssetStatus status,  Map<String, dynamic>? extInfo,  DateTime createdAt,  DateTime updatedAt,  bool isDeleted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Asset() when $default != null:
return $default(_that.id,_that.accountId,_that.assetType,_that.assetCode,_that.quantity,_that.costPrice,_that.currentPrice,_that.currency,_that.marketValue,_that.valuationTime,_that.status,_that.extInfo,_that.createdAt,_that.updatedAt,_that.isDeleted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String accountId,  AssetType assetType,  String? assetCode,  Decimal quantity,  Decimal? costPrice,  Decimal? currentPrice,  String currency,  Decimal? marketValue,  DateTime? valuationTime,  AssetStatus status,  Map<String, dynamic>? extInfo,  DateTime createdAt,  DateTime updatedAt,  bool isDeleted)  $default,) {final _that = this;
switch (_that) {
case _Asset():
return $default(_that.id,_that.accountId,_that.assetType,_that.assetCode,_that.quantity,_that.costPrice,_that.currentPrice,_that.currency,_that.marketValue,_that.valuationTime,_that.status,_that.extInfo,_that.createdAt,_that.updatedAt,_that.isDeleted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String accountId,  AssetType assetType,  String? assetCode,  Decimal quantity,  Decimal? costPrice,  Decimal? currentPrice,  String currency,  Decimal? marketValue,  DateTime? valuationTime,  AssetStatus status,  Map<String, dynamic>? extInfo,  DateTime createdAt,  DateTime updatedAt,  bool isDeleted)?  $default,) {final _that = this;
switch (_that) {
case _Asset() when $default != null:
return $default(_that.id,_that.accountId,_that.assetType,_that.assetCode,_that.quantity,_that.costPrice,_that.currentPrice,_that.currency,_that.marketValue,_that.valuationTime,_that.status,_that.extInfo,_that.createdAt,_that.updatedAt,_that.isDeleted);case _:
  return null;

}
}

}

/// @nodoc


class _Asset implements Asset {
  const _Asset({required this.id, required this.accountId, required this.assetType, this.assetCode, required this.quantity, this.costPrice, this.currentPrice, required this.currency, this.marketValue, this.valuationTime, required this.status, final  Map<String, dynamic>? extInfo, required this.createdAt, required this.updatedAt, this.isDeleted = false}): _extInfo = extInfo;
  

@override final  String id;
@override final  String accountId;
@override final  AssetType assetType;
@override final  String? assetCode;
@override final  Decimal quantity;
@override final  Decimal? costPrice;
@override final  Decimal? currentPrice;
@override final  String currency;
@override final  Decimal? marketValue;
@override final  DateTime? valuationTime;
@override final  AssetStatus status;
 final  Map<String, dynamic>? _extInfo;
@override Map<String, dynamic>? get extInfo {
  final value = _extInfo;
  if (value == null) return null;
  if (_extInfo is EqualUnmodifiableMapView) return _extInfo;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override@JsonKey() final  bool isDeleted;

/// Create a copy of Asset
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssetCopyWith<_Asset> get copyWith => __$AssetCopyWithImpl<_Asset>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Asset&&(identical(other.id, id) || other.id == id)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.assetType, assetType) || other.assetType == assetType)&&(identical(other.assetCode, assetCode) || other.assetCode == assetCode)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.costPrice, costPrice) || other.costPrice == costPrice)&&(identical(other.currentPrice, currentPrice) || other.currentPrice == currentPrice)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.marketValue, marketValue) || other.marketValue == marketValue)&&(identical(other.valuationTime, valuationTime) || other.valuationTime == valuationTime)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._extInfo, _extInfo)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted));
}


@override
int get hashCode => Object.hash(runtimeType,id,accountId,assetType,assetCode,quantity,costPrice,currentPrice,currency,marketValue,valuationTime,status,const DeepCollectionEquality().hash(_extInfo),createdAt,updatedAt,isDeleted);

@override
String toString() {
  return 'Asset(id: $id, accountId: $accountId, assetType: $assetType, assetCode: $assetCode, quantity: $quantity, costPrice: $costPrice, currentPrice: $currentPrice, currency: $currency, marketValue: $marketValue, valuationTime: $valuationTime, status: $status, extInfo: $extInfo, createdAt: $createdAt, updatedAt: $updatedAt, isDeleted: $isDeleted)';
}


}

/// @nodoc
abstract mixin class _$AssetCopyWith<$Res> implements $AssetCopyWith<$Res> {
  factory _$AssetCopyWith(_Asset value, $Res Function(_Asset) _then) = __$AssetCopyWithImpl;
@override @useResult
$Res call({
 String id, String accountId, AssetType assetType, String? assetCode, Decimal quantity, Decimal? costPrice, Decimal? currentPrice, String currency, Decimal? marketValue, DateTime? valuationTime, AssetStatus status, Map<String, dynamic>? extInfo, DateTime createdAt, DateTime updatedAt, bool isDeleted
});




}
/// @nodoc
class __$AssetCopyWithImpl<$Res>
    implements _$AssetCopyWith<$Res> {
  __$AssetCopyWithImpl(this._self, this._then);

  final _Asset _self;
  final $Res Function(_Asset) _then;

/// Create a copy of Asset
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? accountId = null,Object? assetType = null,Object? assetCode = freezed,Object? quantity = null,Object? costPrice = freezed,Object? currentPrice = freezed,Object? currency = null,Object? marketValue = freezed,Object? valuationTime = freezed,Object? status = null,Object? extInfo = freezed,Object? createdAt = null,Object? updatedAt = null,Object? isDeleted = null,}) {
  return _then(_Asset(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,assetType: null == assetType ? _self.assetType : assetType // ignore: cast_nullable_to_non_nullable
as AssetType,assetCode: freezed == assetCode ? _self.assetCode : assetCode // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as Decimal,costPrice: freezed == costPrice ? _self.costPrice : costPrice // ignore: cast_nullable_to_non_nullable
as Decimal?,currentPrice: freezed == currentPrice ? _self.currentPrice : currentPrice // ignore: cast_nullable_to_non_nullable
as Decimal?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,marketValue: freezed == marketValue ? _self.marketValue : marketValue // ignore: cast_nullable_to_non_nullable
as Decimal?,valuationTime: freezed == valuationTime ? _self.valuationTime : valuationTime // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AssetStatus,extInfo: freezed == extInfo ? _self._extInfo : extInfo // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
