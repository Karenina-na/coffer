// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'watched_pair.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WatchedPair {

 String get pairKey; String get baseCurrency; String get quoteCurrency; DateTime get createdAt; int get sortOrder;/// 绝对值上沿：最新汇率 ≥ 此值触发 RATE_ALERT（kind=high）。
 Decimal? get thresholdHigh;/// 绝对值下沿：最新汇率 ≤ 此值触发 RATE_ALERT（kind=low）。
 Decimal? get thresholdLow;/// 相对波动百分比阈值（正数，如 3.0 表示 ±3%）：若最近两天汇率绝对变动
/// 超过此百分比，触发 RATE_ALERT（kind=change）。
 Decimal? get alertChangePct;
/// Create a copy of WatchedPair
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WatchedPairCopyWith<WatchedPair> get copyWith => _$WatchedPairCopyWithImpl<WatchedPair>(this as WatchedPair, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WatchedPair&&(identical(other.pairKey, pairKey) || other.pairKey == pairKey)&&(identical(other.baseCurrency, baseCurrency) || other.baseCurrency == baseCurrency)&&(identical(other.quoteCurrency, quoteCurrency) || other.quoteCurrency == quoteCurrency)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.thresholdHigh, thresholdHigh) || other.thresholdHigh == thresholdHigh)&&(identical(other.thresholdLow, thresholdLow) || other.thresholdLow == thresholdLow)&&(identical(other.alertChangePct, alertChangePct) || other.alertChangePct == alertChangePct));
}


@override
int get hashCode => Object.hash(runtimeType,pairKey,baseCurrency,quoteCurrency,createdAt,sortOrder,thresholdHigh,thresholdLow,alertChangePct);

@override
String toString() {
  return 'WatchedPair(pairKey: $pairKey, baseCurrency: $baseCurrency, quoteCurrency: $quoteCurrency, createdAt: $createdAt, sortOrder: $sortOrder, thresholdHigh: $thresholdHigh, thresholdLow: $thresholdLow, alertChangePct: $alertChangePct)';
}


}

/// @nodoc
abstract mixin class $WatchedPairCopyWith<$Res>  {
  factory $WatchedPairCopyWith(WatchedPair value, $Res Function(WatchedPair) _then) = _$WatchedPairCopyWithImpl;
@useResult
$Res call({
 String pairKey, String baseCurrency, String quoteCurrency, DateTime createdAt, int sortOrder, Decimal? thresholdHigh, Decimal? thresholdLow, Decimal? alertChangePct
});




}
/// @nodoc
class _$WatchedPairCopyWithImpl<$Res>
    implements $WatchedPairCopyWith<$Res> {
  _$WatchedPairCopyWithImpl(this._self, this._then);

  final WatchedPair _self;
  final $Res Function(WatchedPair) _then;

/// Create a copy of WatchedPair
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pairKey = null,Object? baseCurrency = null,Object? quoteCurrency = null,Object? createdAt = null,Object? sortOrder = null,Object? thresholdHigh = freezed,Object? thresholdLow = freezed,Object? alertChangePct = freezed,}) {
  return _then(_self.copyWith(
pairKey: null == pairKey ? _self.pairKey : pairKey // ignore: cast_nullable_to_non_nullable
as String,baseCurrency: null == baseCurrency ? _self.baseCurrency : baseCurrency // ignore: cast_nullable_to_non_nullable
as String,quoteCurrency: null == quoteCurrency ? _self.quoteCurrency : quoteCurrency // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,thresholdHigh: freezed == thresholdHigh ? _self.thresholdHigh : thresholdHigh // ignore: cast_nullable_to_non_nullable
as Decimal?,thresholdLow: freezed == thresholdLow ? _self.thresholdLow : thresholdLow // ignore: cast_nullable_to_non_nullable
as Decimal?,alertChangePct: freezed == alertChangePct ? _self.alertChangePct : alertChangePct // ignore: cast_nullable_to_non_nullable
as Decimal?,
  ));
}

}


/// Adds pattern-matching-related methods to [WatchedPair].
extension WatchedPairPatterns on WatchedPair {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WatchedPair value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WatchedPair() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WatchedPair value)  $default,){
final _that = this;
switch (_that) {
case _WatchedPair():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WatchedPair value)?  $default,){
final _that = this;
switch (_that) {
case _WatchedPair() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String pairKey,  String baseCurrency,  String quoteCurrency,  DateTime createdAt,  int sortOrder,  Decimal? thresholdHigh,  Decimal? thresholdLow,  Decimal? alertChangePct)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WatchedPair() when $default != null:
return $default(_that.pairKey,_that.baseCurrency,_that.quoteCurrency,_that.createdAt,_that.sortOrder,_that.thresholdHigh,_that.thresholdLow,_that.alertChangePct);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String pairKey,  String baseCurrency,  String quoteCurrency,  DateTime createdAt,  int sortOrder,  Decimal? thresholdHigh,  Decimal? thresholdLow,  Decimal? alertChangePct)  $default,) {final _that = this;
switch (_that) {
case _WatchedPair():
return $default(_that.pairKey,_that.baseCurrency,_that.quoteCurrency,_that.createdAt,_that.sortOrder,_that.thresholdHigh,_that.thresholdLow,_that.alertChangePct);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String pairKey,  String baseCurrency,  String quoteCurrency,  DateTime createdAt,  int sortOrder,  Decimal? thresholdHigh,  Decimal? thresholdLow,  Decimal? alertChangePct)?  $default,) {final _that = this;
switch (_that) {
case _WatchedPair() when $default != null:
return $default(_that.pairKey,_that.baseCurrency,_that.quoteCurrency,_that.createdAt,_that.sortOrder,_that.thresholdHigh,_that.thresholdLow,_that.alertChangePct);case _:
  return null;

}
}

}

/// @nodoc


class _WatchedPair extends WatchedPair {
  const _WatchedPair({required this.pairKey, required this.baseCurrency, required this.quoteCurrency, required this.createdAt, this.sortOrder = 1000, this.thresholdHigh, this.thresholdLow, this.alertChangePct}): super._();
  

@override final  String pairKey;
@override final  String baseCurrency;
@override final  String quoteCurrency;
@override final  DateTime createdAt;
@override@JsonKey() final  int sortOrder;
/// 绝对值上沿：最新汇率 ≥ 此值触发 RATE_ALERT（kind=high）。
@override final  Decimal? thresholdHigh;
/// 绝对值下沿：最新汇率 ≤ 此值触发 RATE_ALERT（kind=low）。
@override final  Decimal? thresholdLow;
/// 相对波动百分比阈值（正数，如 3.0 表示 ±3%）：若最近两天汇率绝对变动
/// 超过此百分比，触发 RATE_ALERT（kind=change）。
@override final  Decimal? alertChangePct;

/// Create a copy of WatchedPair
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WatchedPairCopyWith<_WatchedPair> get copyWith => __$WatchedPairCopyWithImpl<_WatchedPair>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WatchedPair&&(identical(other.pairKey, pairKey) || other.pairKey == pairKey)&&(identical(other.baseCurrency, baseCurrency) || other.baseCurrency == baseCurrency)&&(identical(other.quoteCurrency, quoteCurrency) || other.quoteCurrency == quoteCurrency)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.thresholdHigh, thresholdHigh) || other.thresholdHigh == thresholdHigh)&&(identical(other.thresholdLow, thresholdLow) || other.thresholdLow == thresholdLow)&&(identical(other.alertChangePct, alertChangePct) || other.alertChangePct == alertChangePct));
}


@override
int get hashCode => Object.hash(runtimeType,pairKey,baseCurrency,quoteCurrency,createdAt,sortOrder,thresholdHigh,thresholdLow,alertChangePct);

@override
String toString() {
  return 'WatchedPair(pairKey: $pairKey, baseCurrency: $baseCurrency, quoteCurrency: $quoteCurrency, createdAt: $createdAt, sortOrder: $sortOrder, thresholdHigh: $thresholdHigh, thresholdLow: $thresholdLow, alertChangePct: $alertChangePct)';
}


}

/// @nodoc
abstract mixin class _$WatchedPairCopyWith<$Res> implements $WatchedPairCopyWith<$Res> {
  factory _$WatchedPairCopyWith(_WatchedPair value, $Res Function(_WatchedPair) _then) = __$WatchedPairCopyWithImpl;
@override @useResult
$Res call({
 String pairKey, String baseCurrency, String quoteCurrency, DateTime createdAt, int sortOrder, Decimal? thresholdHigh, Decimal? thresholdLow, Decimal? alertChangePct
});




}
/// @nodoc
class __$WatchedPairCopyWithImpl<$Res>
    implements _$WatchedPairCopyWith<$Res> {
  __$WatchedPairCopyWithImpl(this._self, this._then);

  final _WatchedPair _self;
  final $Res Function(_WatchedPair) _then;

/// Create a copy of WatchedPair
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pairKey = null,Object? baseCurrency = null,Object? quoteCurrency = null,Object? createdAt = null,Object? sortOrder = null,Object? thresholdHigh = freezed,Object? thresholdLow = freezed,Object? alertChangePct = freezed,}) {
  return _then(_WatchedPair(
pairKey: null == pairKey ? _self.pairKey : pairKey // ignore: cast_nullable_to_non_nullable
as String,baseCurrency: null == baseCurrency ? _self.baseCurrency : baseCurrency // ignore: cast_nullable_to_non_nullable
as String,quoteCurrency: null == quoteCurrency ? _self.quoteCurrency : quoteCurrency // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,thresholdHigh: freezed == thresholdHigh ? _self.thresholdHigh : thresholdHigh // ignore: cast_nullable_to_non_nullable
as Decimal?,thresholdLow: freezed == thresholdLow ? _self.thresholdLow : thresholdLow // ignore: cast_nullable_to_non_nullable
as Decimal?,alertChangePct: freezed == alertChangePct ? _self.alertChangePct : alertChangePct // ignore: cast_nullable_to_non_nullable
as Decimal?,
  ));
}


}

// dart format on
