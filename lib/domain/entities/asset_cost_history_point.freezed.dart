// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'asset_cost_history_point.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AssetCostHistoryPoint {

 String get id; String get assetId; Decimal? get costPrice; Decimal get quantity; String get currency; String get source; String? get reason; DateTime get triggerTime; String? get sourceKey; DateTime get createdAt;
/// Create a copy of AssetCostHistoryPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssetCostHistoryPointCopyWith<AssetCostHistoryPoint> get copyWith => _$AssetCostHistoryPointCopyWithImpl<AssetCostHistoryPoint>(this as AssetCostHistoryPoint, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssetCostHistoryPoint&&(identical(other.id, id) || other.id == id)&&(identical(other.assetId, assetId) || other.assetId == assetId)&&(identical(other.costPrice, costPrice) || other.costPrice == costPrice)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.source, source) || other.source == source)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.triggerTime, triggerTime) || other.triggerTime == triggerTime)&&(identical(other.sourceKey, sourceKey) || other.sourceKey == sourceKey)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,assetId,costPrice,quantity,currency,source,reason,triggerTime,sourceKey,createdAt);

@override
String toString() {
  return 'AssetCostHistoryPoint(id: $id, assetId: $assetId, costPrice: $costPrice, quantity: $quantity, currency: $currency, source: $source, reason: $reason, triggerTime: $triggerTime, sourceKey: $sourceKey, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $AssetCostHistoryPointCopyWith<$Res>  {
  factory $AssetCostHistoryPointCopyWith(AssetCostHistoryPoint value, $Res Function(AssetCostHistoryPoint) _then) = _$AssetCostHistoryPointCopyWithImpl;
@useResult
$Res call({
 String id, String assetId, Decimal? costPrice, Decimal quantity, String currency, String source, String? reason, DateTime triggerTime, String? sourceKey, DateTime createdAt
});




}
/// @nodoc
class _$AssetCostHistoryPointCopyWithImpl<$Res>
    implements $AssetCostHistoryPointCopyWith<$Res> {
  _$AssetCostHistoryPointCopyWithImpl(this._self, this._then);

  final AssetCostHistoryPoint _self;
  final $Res Function(AssetCostHistoryPoint) _then;

/// Create a copy of AssetCostHistoryPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? assetId = null,Object? costPrice = freezed,Object? quantity = null,Object? currency = null,Object? source = null,Object? reason = freezed,Object? triggerTime = null,Object? sourceKey = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,assetId: null == assetId ? _self.assetId : assetId // ignore: cast_nullable_to_non_nullable
as String,costPrice: freezed == costPrice ? _self.costPrice : costPrice // ignore: cast_nullable_to_non_nullable
as Decimal?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as Decimal,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,triggerTime: null == triggerTime ? _self.triggerTime : triggerTime // ignore: cast_nullable_to_non_nullable
as DateTime,sourceKey: freezed == sourceKey ? _self.sourceKey : sourceKey // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [AssetCostHistoryPoint].
extension AssetCostHistoryPointPatterns on AssetCostHistoryPoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AssetCostHistoryPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AssetCostHistoryPoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AssetCostHistoryPoint value)  $default,){
final _that = this;
switch (_that) {
case _AssetCostHistoryPoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AssetCostHistoryPoint value)?  $default,){
final _that = this;
switch (_that) {
case _AssetCostHistoryPoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String assetId,  Decimal? costPrice,  Decimal quantity,  String currency,  String source,  String? reason,  DateTime triggerTime,  String? sourceKey,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssetCostHistoryPoint() when $default != null:
return $default(_that.id,_that.assetId,_that.costPrice,_that.quantity,_that.currency,_that.source,_that.reason,_that.triggerTime,_that.sourceKey,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String assetId,  Decimal? costPrice,  Decimal quantity,  String currency,  String source,  String? reason,  DateTime triggerTime,  String? sourceKey,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _AssetCostHistoryPoint():
return $default(_that.id,_that.assetId,_that.costPrice,_that.quantity,_that.currency,_that.source,_that.reason,_that.triggerTime,_that.sourceKey,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String assetId,  Decimal? costPrice,  Decimal quantity,  String currency,  String source,  String? reason,  DateTime triggerTime,  String? sourceKey,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _AssetCostHistoryPoint() when $default != null:
return $default(_that.id,_that.assetId,_that.costPrice,_that.quantity,_that.currency,_that.source,_that.reason,_that.triggerTime,_that.sourceKey,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _AssetCostHistoryPoint implements AssetCostHistoryPoint {
  const _AssetCostHistoryPoint({required this.id, required this.assetId, this.costPrice, required this.quantity, required this.currency, required this.source, this.reason, required this.triggerTime, this.sourceKey, required this.createdAt});
  

@override final  String id;
@override final  String assetId;
@override final  Decimal? costPrice;
@override final  Decimal quantity;
@override final  String currency;
@override final  String source;
@override final  String? reason;
@override final  DateTime triggerTime;
@override final  String? sourceKey;
@override final  DateTime createdAt;

/// Create a copy of AssetCostHistoryPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssetCostHistoryPointCopyWith<_AssetCostHistoryPoint> get copyWith => __$AssetCostHistoryPointCopyWithImpl<_AssetCostHistoryPoint>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssetCostHistoryPoint&&(identical(other.id, id) || other.id == id)&&(identical(other.assetId, assetId) || other.assetId == assetId)&&(identical(other.costPrice, costPrice) || other.costPrice == costPrice)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.source, source) || other.source == source)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.triggerTime, triggerTime) || other.triggerTime == triggerTime)&&(identical(other.sourceKey, sourceKey) || other.sourceKey == sourceKey)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,assetId,costPrice,quantity,currency,source,reason,triggerTime,sourceKey,createdAt);

@override
String toString() {
  return 'AssetCostHistoryPoint(id: $id, assetId: $assetId, costPrice: $costPrice, quantity: $quantity, currency: $currency, source: $source, reason: $reason, triggerTime: $triggerTime, sourceKey: $sourceKey, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$AssetCostHistoryPointCopyWith<$Res> implements $AssetCostHistoryPointCopyWith<$Res> {
  factory _$AssetCostHistoryPointCopyWith(_AssetCostHistoryPoint value, $Res Function(_AssetCostHistoryPoint) _then) = __$AssetCostHistoryPointCopyWithImpl;
@override @useResult
$Res call({
 String id, String assetId, Decimal? costPrice, Decimal quantity, String currency, String source, String? reason, DateTime triggerTime, String? sourceKey, DateTime createdAt
});




}
/// @nodoc
class __$AssetCostHistoryPointCopyWithImpl<$Res>
    implements _$AssetCostHistoryPointCopyWith<$Res> {
  __$AssetCostHistoryPointCopyWithImpl(this._self, this._then);

  final _AssetCostHistoryPoint _self;
  final $Res Function(_AssetCostHistoryPoint) _then;

/// Create a copy of AssetCostHistoryPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? assetId = null,Object? costPrice = freezed,Object? quantity = null,Object? currency = null,Object? source = null,Object? reason = freezed,Object? triggerTime = null,Object? sourceKey = freezed,Object? createdAt = null,}) {
  return _then(_AssetCostHistoryPoint(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,assetId: null == assetId ? _self.assetId : assetId // ignore: cast_nullable_to_non_nullable
as String,costPrice: freezed == costPrice ? _self.costPrice : costPrice // ignore: cast_nullable_to_non_nullable
as Decimal?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as Decimal,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,triggerTime: null == triggerTime ? _self.triggerTime : triggerTime // ignore: cast_nullable_to_non_nullable
as DateTime,sourceKey: freezed == sourceKey ? _self.sourceKey : sourceKey // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
