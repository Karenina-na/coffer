// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exchange_rate.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ExchangeRate {

 String get id; String get pairKey; String get baseCurrency; String get quoteCurrency; Decimal get rate; DateTime get asOfTime; DateTime get updatedAt; String get source; SnapshotType get snapshotType; String? get rawPayload;
/// Create a copy of ExchangeRate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExchangeRateCopyWith<ExchangeRate> get copyWith => _$ExchangeRateCopyWithImpl<ExchangeRate>(this as ExchangeRate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExchangeRate&&(identical(other.id, id) || other.id == id)&&(identical(other.pairKey, pairKey) || other.pairKey == pairKey)&&(identical(other.baseCurrency, baseCurrency) || other.baseCurrency == baseCurrency)&&(identical(other.quoteCurrency, quoteCurrency) || other.quoteCurrency == quoteCurrency)&&(identical(other.rate, rate) || other.rate == rate)&&(identical(other.asOfTime, asOfTime) || other.asOfTime == asOfTime)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.source, source) || other.source == source)&&(identical(other.snapshotType, snapshotType) || other.snapshotType == snapshotType)&&(identical(other.rawPayload, rawPayload) || other.rawPayload == rawPayload));
}


@override
int get hashCode => Object.hash(runtimeType,id,pairKey,baseCurrency,quoteCurrency,rate,asOfTime,updatedAt,source,snapshotType,rawPayload);



}

/// @nodoc
abstract mixin class $ExchangeRateCopyWith<$Res>  {
  factory $ExchangeRateCopyWith(ExchangeRate value, $Res Function(ExchangeRate) _then) = _$ExchangeRateCopyWithImpl;
@useResult
$Res call({
 String id, String pairKey, String baseCurrency, String quoteCurrency, Decimal rate, DateTime asOfTime, DateTime updatedAt, String source, SnapshotType snapshotType, String? rawPayload
});




}
/// @nodoc
class _$ExchangeRateCopyWithImpl<$Res>
    implements $ExchangeRateCopyWith<$Res> {
  _$ExchangeRateCopyWithImpl(this._self, this._then);

  final ExchangeRate _self;
  final $Res Function(ExchangeRate) _then;

/// Create a copy of ExchangeRate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? pairKey = null,Object? baseCurrency = null,Object? quoteCurrency = null,Object? rate = null,Object? asOfTime = null,Object? updatedAt = null,Object? source = null,Object? snapshotType = null,Object? rawPayload = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,pairKey: null == pairKey ? _self.pairKey : pairKey // ignore: cast_nullable_to_non_nullable
as String,baseCurrency: null == baseCurrency ? _self.baseCurrency : baseCurrency // ignore: cast_nullable_to_non_nullable
as String,quoteCurrency: null == quoteCurrency ? _self.quoteCurrency : quoteCurrency // ignore: cast_nullable_to_non_nullable
as String,rate: null == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as Decimal,asOfTime: null == asOfTime ? _self.asOfTime : asOfTime // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,snapshotType: null == snapshotType ? _self.snapshotType : snapshotType // ignore: cast_nullable_to_non_nullable
as SnapshotType,rawPayload: freezed == rawPayload ? _self.rawPayload : rawPayload // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ExchangeRate].
extension ExchangeRatePatterns on ExchangeRate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExchangeRate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExchangeRate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExchangeRate value)  $default,){
final _that = this;
switch (_that) {
case _ExchangeRate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExchangeRate value)?  $default,){
final _that = this;
switch (_that) {
case _ExchangeRate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String pairKey,  String baseCurrency,  String quoteCurrency,  Decimal rate,  DateTime asOfTime,  DateTime updatedAt,  String source,  SnapshotType snapshotType,  String? rawPayload)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExchangeRate() when $default != null:
return $default(_that.id,_that.pairKey,_that.baseCurrency,_that.quoteCurrency,_that.rate,_that.asOfTime,_that.updatedAt,_that.source,_that.snapshotType,_that.rawPayload);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String pairKey,  String baseCurrency,  String quoteCurrency,  Decimal rate,  DateTime asOfTime,  DateTime updatedAt,  String source,  SnapshotType snapshotType,  String? rawPayload)  $default,) {final _that = this;
switch (_that) {
case _ExchangeRate():
return $default(_that.id,_that.pairKey,_that.baseCurrency,_that.quoteCurrency,_that.rate,_that.asOfTime,_that.updatedAt,_that.source,_that.snapshotType,_that.rawPayload);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String pairKey,  String baseCurrency,  String quoteCurrency,  Decimal rate,  DateTime asOfTime,  DateTime updatedAt,  String source,  SnapshotType snapshotType,  String? rawPayload)?  $default,) {final _that = this;
switch (_that) {
case _ExchangeRate() when $default != null:
return $default(_that.id,_that.pairKey,_that.baseCurrency,_that.quoteCurrency,_that.rate,_that.asOfTime,_that.updatedAt,_that.source,_that.snapshotType,_that.rawPayload);case _:
  return null;

}
}

}

/// @nodoc


class _ExchangeRate extends ExchangeRate {
  const _ExchangeRate({required this.id, required this.pairKey, required this.baseCurrency, required this.quoteCurrency, required this.rate, required this.asOfTime, required this.updatedAt, required this.source, required this.snapshotType, this.rawPayload}): super._();
  

@override final  String id;
@override final  String pairKey;
@override final  String baseCurrency;
@override final  String quoteCurrency;
@override final  Decimal rate;
@override final  DateTime asOfTime;
@override final  DateTime updatedAt;
@override final  String source;
@override final  SnapshotType snapshotType;
@override final  String? rawPayload;

/// Create a copy of ExchangeRate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExchangeRateCopyWith<_ExchangeRate> get copyWith => __$ExchangeRateCopyWithImpl<_ExchangeRate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExchangeRate&&(identical(other.id, id) || other.id == id)&&(identical(other.pairKey, pairKey) || other.pairKey == pairKey)&&(identical(other.baseCurrency, baseCurrency) || other.baseCurrency == baseCurrency)&&(identical(other.quoteCurrency, quoteCurrency) || other.quoteCurrency == quoteCurrency)&&(identical(other.rate, rate) || other.rate == rate)&&(identical(other.asOfTime, asOfTime) || other.asOfTime == asOfTime)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.source, source) || other.source == source)&&(identical(other.snapshotType, snapshotType) || other.snapshotType == snapshotType)&&(identical(other.rawPayload, rawPayload) || other.rawPayload == rawPayload));
}


@override
int get hashCode => Object.hash(runtimeType,id,pairKey,baseCurrency,quoteCurrency,rate,asOfTime,updatedAt,source,snapshotType,rawPayload);



}

/// @nodoc
abstract mixin class _$ExchangeRateCopyWith<$Res> implements $ExchangeRateCopyWith<$Res> {
  factory _$ExchangeRateCopyWith(_ExchangeRate value, $Res Function(_ExchangeRate) _then) = __$ExchangeRateCopyWithImpl;
@override @useResult
$Res call({
 String id, String pairKey, String baseCurrency, String quoteCurrency, Decimal rate, DateTime asOfTime, DateTime updatedAt, String source, SnapshotType snapshotType, String? rawPayload
});




}
/// @nodoc
class __$ExchangeRateCopyWithImpl<$Res>
    implements _$ExchangeRateCopyWith<$Res> {
  __$ExchangeRateCopyWithImpl(this._self, this._then);

  final _ExchangeRate _self;
  final $Res Function(_ExchangeRate) _then;

/// Create a copy of ExchangeRate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? pairKey = null,Object? baseCurrency = null,Object? quoteCurrency = null,Object? rate = null,Object? asOfTime = null,Object? updatedAt = null,Object? source = null,Object? snapshotType = null,Object? rawPayload = freezed,}) {
  return _then(_ExchangeRate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,pairKey: null == pairKey ? _self.pairKey : pairKey // ignore: cast_nullable_to_non_nullable
as String,baseCurrency: null == baseCurrency ? _self.baseCurrency : baseCurrency // ignore: cast_nullable_to_non_nullable
as String,quoteCurrency: null == quoteCurrency ? _self.quoteCurrency : quoteCurrency // ignore: cast_nullable_to_non_nullable
as String,rate: null == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as Decimal,asOfTime: null == asOfTime ? _self.asOfTime : asOfTime // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,snapshotType: null == snapshotType ? _self.snapshotType : snapshotType // ignore: cast_nullable_to_non_nullable
as SnapshotType,rawPayload: freezed == rawPayload ? _self.rawPayload : rawPayload // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
