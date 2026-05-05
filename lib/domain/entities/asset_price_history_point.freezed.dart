// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'asset_price_history_point.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AssetPriceHistoryPoint {

 String get id; String get assetId; Decimal get price; Decimal? get marketValue; String get currency; String get source; String? get batchId; DateTime get triggerTime; String? get sourceKey; String? get rawPayload; DateTime get createdAt;
/// Create a copy of AssetPriceHistoryPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssetPriceHistoryPointCopyWith<AssetPriceHistoryPoint> get copyWith => _$AssetPriceHistoryPointCopyWithImpl<AssetPriceHistoryPoint>(this as AssetPriceHistoryPoint, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssetPriceHistoryPoint&&(identical(other.id, id) || other.id == id)&&(identical(other.assetId, assetId) || other.assetId == assetId)&&(identical(other.price, price) || other.price == price)&&(identical(other.marketValue, marketValue) || other.marketValue == marketValue)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.source, source) || other.source == source)&&(identical(other.batchId, batchId) || other.batchId == batchId)&&(identical(other.triggerTime, triggerTime) || other.triggerTime == triggerTime)&&(identical(other.sourceKey, sourceKey) || other.sourceKey == sourceKey)&&(identical(other.rawPayload, rawPayload) || other.rawPayload == rawPayload)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,assetId,price,marketValue,currency,source,batchId,triggerTime,sourceKey,rawPayload,createdAt);

@override
String toString() {
  return 'AssetPriceHistoryPoint(id: $id, assetId: $assetId, price: $price, marketValue: $marketValue, currency: $currency, source: $source, batchId: $batchId, triggerTime: $triggerTime, sourceKey: $sourceKey, rawPayload: $rawPayload, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $AssetPriceHistoryPointCopyWith<$Res>  {
  factory $AssetPriceHistoryPointCopyWith(AssetPriceHistoryPoint value, $Res Function(AssetPriceHistoryPoint) _then) = _$AssetPriceHistoryPointCopyWithImpl;
@useResult
$Res call({
 String id, String assetId, Decimal price, Decimal? marketValue, String currency, String source, String? batchId, DateTime triggerTime, String? sourceKey, String? rawPayload, DateTime createdAt
});




}
/// @nodoc
class _$AssetPriceHistoryPointCopyWithImpl<$Res>
    implements $AssetPriceHistoryPointCopyWith<$Res> {
  _$AssetPriceHistoryPointCopyWithImpl(this._self, this._then);

  final AssetPriceHistoryPoint _self;
  final $Res Function(AssetPriceHistoryPoint) _then;

/// Create a copy of AssetPriceHistoryPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? assetId = null,Object? price = null,Object? marketValue = freezed,Object? currency = null,Object? source = null,Object? batchId = freezed,Object? triggerTime = null,Object? sourceKey = freezed,Object? rawPayload = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,assetId: null == assetId ? _self.assetId : assetId // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as Decimal,marketValue: freezed == marketValue ? _self.marketValue : marketValue // ignore: cast_nullable_to_non_nullable
as Decimal?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,batchId: freezed == batchId ? _self.batchId : batchId // ignore: cast_nullable_to_non_nullable
as String?,triggerTime: null == triggerTime ? _self.triggerTime : triggerTime // ignore: cast_nullable_to_non_nullable
as DateTime,sourceKey: freezed == sourceKey ? _self.sourceKey : sourceKey // ignore: cast_nullable_to_non_nullable
as String?,rawPayload: freezed == rawPayload ? _self.rawPayload : rawPayload // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [AssetPriceHistoryPoint].
extension AssetPriceHistoryPointPatterns on AssetPriceHistoryPoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AssetPriceHistoryPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AssetPriceHistoryPoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AssetPriceHistoryPoint value)  $default,){
final _that = this;
switch (_that) {
case _AssetPriceHistoryPoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AssetPriceHistoryPoint value)?  $default,){
final _that = this;
switch (_that) {
case _AssetPriceHistoryPoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String assetId,  Decimal price,  Decimal? marketValue,  String currency,  String source,  String? batchId,  DateTime triggerTime,  String? sourceKey,  String? rawPayload,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssetPriceHistoryPoint() when $default != null:
return $default(_that.id,_that.assetId,_that.price,_that.marketValue,_that.currency,_that.source,_that.batchId,_that.triggerTime,_that.sourceKey,_that.rawPayload,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String assetId,  Decimal price,  Decimal? marketValue,  String currency,  String source,  String? batchId,  DateTime triggerTime,  String? sourceKey,  String? rawPayload,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _AssetPriceHistoryPoint():
return $default(_that.id,_that.assetId,_that.price,_that.marketValue,_that.currency,_that.source,_that.batchId,_that.triggerTime,_that.sourceKey,_that.rawPayload,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String assetId,  Decimal price,  Decimal? marketValue,  String currency,  String source,  String? batchId,  DateTime triggerTime,  String? sourceKey,  String? rawPayload,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _AssetPriceHistoryPoint() when $default != null:
return $default(_that.id,_that.assetId,_that.price,_that.marketValue,_that.currency,_that.source,_that.batchId,_that.triggerTime,_that.sourceKey,_that.rawPayload,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _AssetPriceHistoryPoint implements AssetPriceHistoryPoint {
  const _AssetPriceHistoryPoint({required this.id, required this.assetId, required this.price, this.marketValue, required this.currency, required this.source, this.batchId, required this.triggerTime, this.sourceKey, this.rawPayload, required this.createdAt});
  

@override final  String id;
@override final  String assetId;
@override final  Decimal price;
@override final  Decimal? marketValue;
@override final  String currency;
@override final  String source;
@override final  String? batchId;
@override final  DateTime triggerTime;
@override final  String? sourceKey;
@override final  String? rawPayload;
@override final  DateTime createdAt;

/// Create a copy of AssetPriceHistoryPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssetPriceHistoryPointCopyWith<_AssetPriceHistoryPoint> get copyWith => __$AssetPriceHistoryPointCopyWithImpl<_AssetPriceHistoryPoint>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssetPriceHistoryPoint&&(identical(other.id, id) || other.id == id)&&(identical(other.assetId, assetId) || other.assetId == assetId)&&(identical(other.price, price) || other.price == price)&&(identical(other.marketValue, marketValue) || other.marketValue == marketValue)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.source, source) || other.source == source)&&(identical(other.batchId, batchId) || other.batchId == batchId)&&(identical(other.triggerTime, triggerTime) || other.triggerTime == triggerTime)&&(identical(other.sourceKey, sourceKey) || other.sourceKey == sourceKey)&&(identical(other.rawPayload, rawPayload) || other.rawPayload == rawPayload)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,assetId,price,marketValue,currency,source,batchId,triggerTime,sourceKey,rawPayload,createdAt);

@override
String toString() {
  return 'AssetPriceHistoryPoint(id: $id, assetId: $assetId, price: $price, marketValue: $marketValue, currency: $currency, source: $source, batchId: $batchId, triggerTime: $triggerTime, sourceKey: $sourceKey, rawPayload: $rawPayload, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$AssetPriceHistoryPointCopyWith<$Res> implements $AssetPriceHistoryPointCopyWith<$Res> {
  factory _$AssetPriceHistoryPointCopyWith(_AssetPriceHistoryPoint value, $Res Function(_AssetPriceHistoryPoint) _then) = __$AssetPriceHistoryPointCopyWithImpl;
@override @useResult
$Res call({
 String id, String assetId, Decimal price, Decimal? marketValue, String currency, String source, String? batchId, DateTime triggerTime, String? sourceKey, String? rawPayload, DateTime createdAt
});




}
/// @nodoc
class __$AssetPriceHistoryPointCopyWithImpl<$Res>
    implements _$AssetPriceHistoryPointCopyWith<$Res> {
  __$AssetPriceHistoryPointCopyWithImpl(this._self, this._then);

  final _AssetPriceHistoryPoint _self;
  final $Res Function(_AssetPriceHistoryPoint) _then;

/// Create a copy of AssetPriceHistoryPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? assetId = null,Object? price = null,Object? marketValue = freezed,Object? currency = null,Object? source = null,Object? batchId = freezed,Object? triggerTime = null,Object? sourceKey = freezed,Object? rawPayload = freezed,Object? createdAt = null,}) {
  return _then(_AssetPriceHistoryPoint(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,assetId: null == assetId ? _self.assetId : assetId // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as Decimal,marketValue: freezed == marketValue ? _self.marketValue : marketValue // ignore: cast_nullable_to_non_nullable
as Decimal?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,batchId: freezed == batchId ? _self.batchId : batchId // ignore: cast_nullable_to_non_nullable
as String?,triggerTime: null == triggerTime ? _self.triggerTime : triggerTime // ignore: cast_nullable_to_non_nullable
as DateTime,sourceKey: freezed == sourceKey ? _self.sourceKey : sourceKey // ignore: cast_nullable_to_non_nullable
as String?,rawPayload: freezed == rawPayload ? _self.rawPayload : rawPayload // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
