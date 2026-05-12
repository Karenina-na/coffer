// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'channel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Channel {

 String get id; String get name;/// 转账协议代码（如 SWIFT / ACH / SEPA / 用户自定义）。
///
/// 值来自 `dict_entries` 表的 `TRANSFER_PROTOCOL` 类型，应用层只按代码字符串
/// 处理，展示时通过 [DictRepository] 查出对应名称。
 String get transferProtocol; bool get isBuiltin; Decimal? get feeRate; Decimal? get fixedFee; Map<String, dynamic>? get sovereigntyRegionRule; String? get limitCurrency; Decimal? get dailyLimit; Decimal? get singleLimit; ChannelStatus get status; int get sortOrder; DateTime? get effectiveFrom; DateTime? get effectiveTo; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of Channel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChannelCopyWith<Channel> get copyWith => _$ChannelCopyWithImpl<Channel>(this as Channel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Channel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.transferProtocol, transferProtocol) || other.transferProtocol == transferProtocol)&&(identical(other.isBuiltin, isBuiltin) || other.isBuiltin == isBuiltin)&&(identical(other.feeRate, feeRate) || other.feeRate == feeRate)&&(identical(other.fixedFee, fixedFee) || other.fixedFee == fixedFee)&&const DeepCollectionEquality().equals(other.sovereigntyRegionRule, sovereigntyRegionRule)&&(identical(other.limitCurrency, limitCurrency) || other.limitCurrency == limitCurrency)&&(identical(other.dailyLimit, dailyLimit) || other.dailyLimit == dailyLimit)&&(identical(other.singleLimit, singleLimit) || other.singleLimit == singleLimit)&&(identical(other.status, status) || other.status == status)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.effectiveFrom, effectiveFrom) || other.effectiveFrom == effectiveFrom)&&(identical(other.effectiveTo, effectiveTo) || other.effectiveTo == effectiveTo)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,transferProtocol,isBuiltin,feeRate,fixedFee,const DeepCollectionEquality().hash(sovereigntyRegionRule),limitCurrency,dailyLimit,singleLimit,status,sortOrder,effectiveFrom,effectiveTo,createdAt,updatedAt);

@override
String toString() {
  return 'Channel(id: $id, name: $name, transferProtocol: $transferProtocol, isBuiltin: $isBuiltin, feeRate: $feeRate, fixedFee: $fixedFee, sovereigntyRegionRule: $sovereigntyRegionRule, limitCurrency: $limitCurrency, dailyLimit: $dailyLimit, singleLimit: $singleLimit, status: $status, sortOrder: $sortOrder, effectiveFrom: $effectiveFrom, effectiveTo: $effectiveTo, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ChannelCopyWith<$Res>  {
  factory $ChannelCopyWith(Channel value, $Res Function(Channel) _then) = _$ChannelCopyWithImpl;
@useResult
$Res call({
 String id, String name, String transferProtocol, bool isBuiltin, Decimal? feeRate, Decimal? fixedFee, Map<String, dynamic>? sovereigntyRegionRule, String? limitCurrency, Decimal? dailyLimit, Decimal? singleLimit, ChannelStatus status, int sortOrder, DateTime? effectiveFrom, DateTime? effectiveTo, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$ChannelCopyWithImpl<$Res>
    implements $ChannelCopyWith<$Res> {
  _$ChannelCopyWithImpl(this._self, this._then);

  final Channel _self;
  final $Res Function(Channel) _then;

/// Create a copy of Channel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? transferProtocol = null,Object? isBuiltin = null,Object? feeRate = freezed,Object? fixedFee = freezed,Object? sovereigntyRegionRule = freezed,Object? limitCurrency = freezed,Object? dailyLimit = freezed,Object? singleLimit = freezed,Object? status = null,Object? sortOrder = null,Object? effectiveFrom = freezed,Object? effectiveTo = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,transferProtocol: null == transferProtocol ? _self.transferProtocol : transferProtocol // ignore: cast_nullable_to_non_nullable
as String,isBuiltin: null == isBuiltin ? _self.isBuiltin : isBuiltin // ignore: cast_nullable_to_non_nullable
as bool,feeRate: freezed == feeRate ? _self.feeRate : feeRate // ignore: cast_nullable_to_non_nullable
as Decimal?,fixedFee: freezed == fixedFee ? _self.fixedFee : fixedFee // ignore: cast_nullable_to_non_nullable
as Decimal?,sovereigntyRegionRule: freezed == sovereigntyRegionRule ? _self.sovereigntyRegionRule : sovereigntyRegionRule // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,limitCurrency: freezed == limitCurrency ? _self.limitCurrency : limitCurrency // ignore: cast_nullable_to_non_nullable
as String?,dailyLimit: freezed == dailyLimit ? _self.dailyLimit : dailyLimit // ignore: cast_nullable_to_non_nullable
as Decimal?,singleLimit: freezed == singleLimit ? _self.singleLimit : singleLimit // ignore: cast_nullable_to_non_nullable
as Decimal?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ChannelStatus,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,effectiveFrom: freezed == effectiveFrom ? _self.effectiveFrom : effectiveFrom // ignore: cast_nullable_to_non_nullable
as DateTime?,effectiveTo: freezed == effectiveTo ? _self.effectiveTo : effectiveTo // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Channel].
extension ChannelPatterns on Channel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Channel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Channel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Channel value)  $default,){
final _that = this;
switch (_that) {
case _Channel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Channel value)?  $default,){
final _that = this;
switch (_that) {
case _Channel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String transferProtocol,  bool isBuiltin,  Decimal? feeRate,  Decimal? fixedFee,  Map<String, dynamic>? sovereigntyRegionRule,  String? limitCurrency,  Decimal? dailyLimit,  Decimal? singleLimit,  ChannelStatus status,  int sortOrder,  DateTime? effectiveFrom,  DateTime? effectiveTo,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Channel() when $default != null:
return $default(_that.id,_that.name,_that.transferProtocol,_that.isBuiltin,_that.feeRate,_that.fixedFee,_that.sovereigntyRegionRule,_that.limitCurrency,_that.dailyLimit,_that.singleLimit,_that.status,_that.sortOrder,_that.effectiveFrom,_that.effectiveTo,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String transferProtocol,  bool isBuiltin,  Decimal? feeRate,  Decimal? fixedFee,  Map<String, dynamic>? sovereigntyRegionRule,  String? limitCurrency,  Decimal? dailyLimit,  Decimal? singleLimit,  ChannelStatus status,  int sortOrder,  DateTime? effectiveFrom,  DateTime? effectiveTo,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Channel():
return $default(_that.id,_that.name,_that.transferProtocol,_that.isBuiltin,_that.feeRate,_that.fixedFee,_that.sovereigntyRegionRule,_that.limitCurrency,_that.dailyLimit,_that.singleLimit,_that.status,_that.sortOrder,_that.effectiveFrom,_that.effectiveTo,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String transferProtocol,  bool isBuiltin,  Decimal? feeRate,  Decimal? fixedFee,  Map<String, dynamic>? sovereigntyRegionRule,  String? limitCurrency,  Decimal? dailyLimit,  Decimal? singleLimit,  ChannelStatus status,  int sortOrder,  DateTime? effectiveFrom,  DateTime? effectiveTo,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Channel() when $default != null:
return $default(_that.id,_that.name,_that.transferProtocol,_that.isBuiltin,_that.feeRate,_that.fixedFee,_that.sovereigntyRegionRule,_that.limitCurrency,_that.dailyLimit,_that.singleLimit,_that.status,_that.sortOrder,_that.effectiveFrom,_that.effectiveTo,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _Channel implements Channel {
  const _Channel({required this.id, required this.name, required this.transferProtocol, this.isBuiltin = false, this.feeRate, this.fixedFee, final  Map<String, dynamic>? sovereigntyRegionRule, this.limitCurrency, this.dailyLimit, this.singleLimit, required this.status, this.sortOrder = 1000, this.effectiveFrom, this.effectiveTo, required this.createdAt, required this.updatedAt}): _sovereigntyRegionRule = sovereigntyRegionRule;
  

@override final  String id;
@override final  String name;
/// 转账协议代码（如 SWIFT / ACH / SEPA / 用户自定义）。
///
/// 值来自 `dict_entries` 表的 `TRANSFER_PROTOCOL` 类型，应用层只按代码字符串
/// 处理，展示时通过 [DictRepository] 查出对应名称。
@override final  String transferProtocol;
@override@JsonKey() final  bool isBuiltin;
@override final  Decimal? feeRate;
@override final  Decimal? fixedFee;
 final  Map<String, dynamic>? _sovereigntyRegionRule;
@override Map<String, dynamic>? get sovereigntyRegionRule {
  final value = _sovereigntyRegionRule;
  if (value == null) return null;
  if (_sovereigntyRegionRule is EqualUnmodifiableMapView) return _sovereigntyRegionRule;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  String? limitCurrency;
@override final  Decimal? dailyLimit;
@override final  Decimal? singleLimit;
@override final  ChannelStatus status;
@override@JsonKey() final  int sortOrder;
@override final  DateTime? effectiveFrom;
@override final  DateTime? effectiveTo;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of Channel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChannelCopyWith<_Channel> get copyWith => __$ChannelCopyWithImpl<_Channel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Channel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.transferProtocol, transferProtocol) || other.transferProtocol == transferProtocol)&&(identical(other.isBuiltin, isBuiltin) || other.isBuiltin == isBuiltin)&&(identical(other.feeRate, feeRate) || other.feeRate == feeRate)&&(identical(other.fixedFee, fixedFee) || other.fixedFee == fixedFee)&&const DeepCollectionEquality().equals(other._sovereigntyRegionRule, _sovereigntyRegionRule)&&(identical(other.limitCurrency, limitCurrency) || other.limitCurrency == limitCurrency)&&(identical(other.dailyLimit, dailyLimit) || other.dailyLimit == dailyLimit)&&(identical(other.singleLimit, singleLimit) || other.singleLimit == singleLimit)&&(identical(other.status, status) || other.status == status)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.effectiveFrom, effectiveFrom) || other.effectiveFrom == effectiveFrom)&&(identical(other.effectiveTo, effectiveTo) || other.effectiveTo == effectiveTo)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,transferProtocol,isBuiltin,feeRate,fixedFee,const DeepCollectionEquality().hash(_sovereigntyRegionRule),limitCurrency,dailyLimit,singleLimit,status,sortOrder,effectiveFrom,effectiveTo,createdAt,updatedAt);

@override
String toString() {
  return 'Channel(id: $id, name: $name, transferProtocol: $transferProtocol, isBuiltin: $isBuiltin, feeRate: $feeRate, fixedFee: $fixedFee, sovereigntyRegionRule: $sovereigntyRegionRule, limitCurrency: $limitCurrency, dailyLimit: $dailyLimit, singleLimit: $singleLimit, status: $status, sortOrder: $sortOrder, effectiveFrom: $effectiveFrom, effectiveTo: $effectiveTo, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ChannelCopyWith<$Res> implements $ChannelCopyWith<$Res> {
  factory _$ChannelCopyWith(_Channel value, $Res Function(_Channel) _then) = __$ChannelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String transferProtocol, bool isBuiltin, Decimal? feeRate, Decimal? fixedFee, Map<String, dynamic>? sovereigntyRegionRule, String? limitCurrency, Decimal? dailyLimit, Decimal? singleLimit, ChannelStatus status, int sortOrder, DateTime? effectiveFrom, DateTime? effectiveTo, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$ChannelCopyWithImpl<$Res>
    implements _$ChannelCopyWith<$Res> {
  __$ChannelCopyWithImpl(this._self, this._then);

  final _Channel _self;
  final $Res Function(_Channel) _then;

/// Create a copy of Channel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? transferProtocol = null,Object? isBuiltin = null,Object? feeRate = freezed,Object? fixedFee = freezed,Object? sovereigntyRegionRule = freezed,Object? limitCurrency = freezed,Object? dailyLimit = freezed,Object? singleLimit = freezed,Object? status = null,Object? sortOrder = null,Object? effectiveFrom = freezed,Object? effectiveTo = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Channel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,transferProtocol: null == transferProtocol ? _self.transferProtocol : transferProtocol // ignore: cast_nullable_to_non_nullable
as String,isBuiltin: null == isBuiltin ? _self.isBuiltin : isBuiltin // ignore: cast_nullable_to_non_nullable
as bool,feeRate: freezed == feeRate ? _self.feeRate : feeRate // ignore: cast_nullable_to_non_nullable
as Decimal?,fixedFee: freezed == fixedFee ? _self.fixedFee : fixedFee // ignore: cast_nullable_to_non_nullable
as Decimal?,sovereigntyRegionRule: freezed == sovereigntyRegionRule ? _self._sovereigntyRegionRule : sovereigntyRegionRule // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,limitCurrency: freezed == limitCurrency ? _self.limitCurrency : limitCurrency // ignore: cast_nullable_to_non_nullable
as String?,dailyLimit: freezed == dailyLimit ? _self.dailyLimit : dailyLimit // ignore: cast_nullable_to_non_nullable
as Decimal?,singleLimit: freezed == singleLimit ? _self.singleLimit : singleLimit // ignore: cast_nullable_to_non_nullable
as Decimal?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ChannelStatus,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,effectiveFrom: freezed == effectiveFrom ? _self.effectiveFrom : effectiveFrom // ignore: cast_nullable_to_non_nullable
as DateTime?,effectiveTo: freezed == effectiveTo ? _self.effectiveTo : effectiveTo // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
