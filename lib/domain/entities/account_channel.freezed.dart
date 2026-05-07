// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account_channel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AccountChannel {

 String get accountId; String get channelId; Decimal? get feeRateOverride; Decimal? get fixedFeeOverride; String? get feeCurrencyOverride; DateTime get createdAt; DateTime? get updatedAt;
/// Create a copy of AccountChannel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountChannelCopyWith<AccountChannel> get copyWith => _$AccountChannelCopyWithImpl<AccountChannel>(this as AccountChannel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountChannel&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.channelId, channelId) || other.channelId == channelId)&&(identical(other.feeRateOverride, feeRateOverride) || other.feeRateOverride == feeRateOverride)&&(identical(other.fixedFeeOverride, fixedFeeOverride) || other.fixedFeeOverride == fixedFeeOverride)&&(identical(other.feeCurrencyOverride, feeCurrencyOverride) || other.feeCurrencyOverride == feeCurrencyOverride)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,accountId,channelId,feeRateOverride,fixedFeeOverride,feeCurrencyOverride,createdAt,updatedAt);

@override
String toString() {
  return 'AccountChannel(accountId: $accountId, channelId: $channelId, feeRateOverride: $feeRateOverride, fixedFeeOverride: $fixedFeeOverride, feeCurrencyOverride: $feeCurrencyOverride, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $AccountChannelCopyWith<$Res>  {
  factory $AccountChannelCopyWith(AccountChannel value, $Res Function(AccountChannel) _then) = _$AccountChannelCopyWithImpl;
@useResult
$Res call({
 String accountId, String channelId, Decimal? feeRateOverride, Decimal? fixedFeeOverride, String? feeCurrencyOverride, DateTime createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$AccountChannelCopyWithImpl<$Res>
    implements $AccountChannelCopyWith<$Res> {
  _$AccountChannelCopyWithImpl(this._self, this._then);

  final AccountChannel _self;
  final $Res Function(AccountChannel) _then;

/// Create a copy of AccountChannel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accountId = null,Object? channelId = null,Object? feeRateOverride = freezed,Object? fixedFeeOverride = freezed,Object? feeCurrencyOverride = freezed,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,channelId: null == channelId ? _self.channelId : channelId // ignore: cast_nullable_to_non_nullable
as String,feeRateOverride: freezed == feeRateOverride ? _self.feeRateOverride : feeRateOverride // ignore: cast_nullable_to_non_nullable
as Decimal?,fixedFeeOverride: freezed == fixedFeeOverride ? _self.fixedFeeOverride : fixedFeeOverride // ignore: cast_nullable_to_non_nullable
as Decimal?,feeCurrencyOverride: freezed == feeCurrencyOverride ? _self.feeCurrencyOverride : feeCurrencyOverride // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [AccountChannel].
extension AccountChannelPatterns on AccountChannel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AccountChannel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AccountChannel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AccountChannel value)  $default,){
final _that = this;
switch (_that) {
case _AccountChannel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AccountChannel value)?  $default,){
final _that = this;
switch (_that) {
case _AccountChannel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String accountId,  String channelId,  Decimal? feeRateOverride,  Decimal? fixedFeeOverride,  String? feeCurrencyOverride,  DateTime createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AccountChannel() when $default != null:
return $default(_that.accountId,_that.channelId,_that.feeRateOverride,_that.fixedFeeOverride,_that.feeCurrencyOverride,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String accountId,  String channelId,  Decimal? feeRateOverride,  Decimal? fixedFeeOverride,  String? feeCurrencyOverride,  DateTime createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _AccountChannel():
return $default(_that.accountId,_that.channelId,_that.feeRateOverride,_that.fixedFeeOverride,_that.feeCurrencyOverride,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String accountId,  String channelId,  Decimal? feeRateOverride,  Decimal? fixedFeeOverride,  String? feeCurrencyOverride,  DateTime createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _AccountChannel() when $default != null:
return $default(_that.accountId,_that.channelId,_that.feeRateOverride,_that.fixedFeeOverride,_that.feeCurrencyOverride,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _AccountChannel implements AccountChannel {
  const _AccountChannel({required this.accountId, required this.channelId, this.feeRateOverride, this.fixedFeeOverride, this.feeCurrencyOverride, required this.createdAt, this.updatedAt});
  

@override final  String accountId;
@override final  String channelId;
@override final  Decimal? feeRateOverride;
@override final  Decimal? fixedFeeOverride;
@override final  String? feeCurrencyOverride;
@override final  DateTime createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of AccountChannel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccountChannelCopyWith<_AccountChannel> get copyWith => __$AccountChannelCopyWithImpl<_AccountChannel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AccountChannel&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.channelId, channelId) || other.channelId == channelId)&&(identical(other.feeRateOverride, feeRateOverride) || other.feeRateOverride == feeRateOverride)&&(identical(other.fixedFeeOverride, fixedFeeOverride) || other.fixedFeeOverride == fixedFeeOverride)&&(identical(other.feeCurrencyOverride, feeCurrencyOverride) || other.feeCurrencyOverride == feeCurrencyOverride)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,accountId,channelId,feeRateOverride,fixedFeeOverride,feeCurrencyOverride,createdAt,updatedAt);

@override
String toString() {
  return 'AccountChannel(accountId: $accountId, channelId: $channelId, feeRateOverride: $feeRateOverride, fixedFeeOverride: $fixedFeeOverride, feeCurrencyOverride: $feeCurrencyOverride, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$AccountChannelCopyWith<$Res> implements $AccountChannelCopyWith<$Res> {
  factory _$AccountChannelCopyWith(_AccountChannel value, $Res Function(_AccountChannel) _then) = __$AccountChannelCopyWithImpl;
@override @useResult
$Res call({
 String accountId, String channelId, Decimal? feeRateOverride, Decimal? fixedFeeOverride, String? feeCurrencyOverride, DateTime createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$AccountChannelCopyWithImpl<$Res>
    implements _$AccountChannelCopyWith<$Res> {
  __$AccountChannelCopyWithImpl(this._self, this._then);

  final _AccountChannel _self;
  final $Res Function(_AccountChannel) _then;

/// Create a copy of AccountChannel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accountId = null,Object? channelId = null,Object? feeRateOverride = freezed,Object? fixedFeeOverride = freezed,Object? feeCurrencyOverride = freezed,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(_AccountChannel(
accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,channelId: null == channelId ? _self.channelId : channelId // ignore: cast_nullable_to_non_nullable
as String,feeRateOverride: freezed == feeRateOverride ? _self.feeRateOverride : feeRateOverride // ignore: cast_nullable_to_non_nullable
as Decimal?,fixedFeeOverride: freezed == fixedFeeOverride ? _self.fixedFeeOverride : fixedFeeOverride // ignore: cast_nullable_to_non_nullable
as Decimal?,feeCurrencyOverride: freezed == feeCurrencyOverride ? _self.feeCurrencyOverride : feeCurrencyOverride // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
