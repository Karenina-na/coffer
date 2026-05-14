// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Account {

 String get id; String? get accountNo; AccountType get accountType; String get sovereigntyRegion; String get institutionName; AccountStatus get status; DateTime? get openedAt; Map<String, dynamic>? get extInfo;/// FX spread percentage (0–100, e.g. 0.3 = 0.3% loss per conversion).
/// 0 means this account does not support internal currency exchange.
 double get fxSpreadPercent; DateTime get createdAt; DateTime get updatedAt; bool get isDeleted;
/// Create a copy of Account
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountCopyWith<Account> get copyWith => _$AccountCopyWithImpl<Account>(this as Account, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Account&&(identical(other.id, id) || other.id == id)&&(identical(other.accountNo, accountNo) || other.accountNo == accountNo)&&(identical(other.accountType, accountType) || other.accountType == accountType)&&(identical(other.sovereigntyRegion, sovereigntyRegion) || other.sovereigntyRegion == sovereigntyRegion)&&(identical(other.institutionName, institutionName) || other.institutionName == institutionName)&&(identical(other.status, status) || other.status == status)&&(identical(other.openedAt, openedAt) || other.openedAt == openedAt)&&const DeepCollectionEquality().equals(other.extInfo, extInfo)&&(identical(other.fxSpreadPercent, fxSpreadPercent) || other.fxSpreadPercent == fxSpreadPercent)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted));
}


@override
int get hashCode => Object.hash(runtimeType,id,accountNo,accountType,sovereigntyRegion,institutionName,status,openedAt,const DeepCollectionEquality().hash(extInfo),fxSpreadPercent,createdAt,updatedAt,isDeleted);

@override
String toString() {
  return 'Account(id: $id, accountNo: $accountNo, accountType: $accountType, sovereigntyRegion: $sovereigntyRegion, institutionName: $institutionName, status: $status, openedAt: $openedAt, extInfo: $extInfo, fxSpreadPercent: $fxSpreadPercent, createdAt: $createdAt, updatedAt: $updatedAt, isDeleted: $isDeleted)';
}


}

/// @nodoc
abstract mixin class $AccountCopyWith<$Res>  {
  factory $AccountCopyWith(Account value, $Res Function(Account) _then) = _$AccountCopyWithImpl;
@useResult
$Res call({
 String id, String? accountNo, AccountType accountType, String sovereigntyRegion, String institutionName, AccountStatus status, DateTime? openedAt, Map<String, dynamic>? extInfo, double fxSpreadPercent, DateTime createdAt, DateTime updatedAt, bool isDeleted
});




}
/// @nodoc
class _$AccountCopyWithImpl<$Res>
    implements $AccountCopyWith<$Res> {
  _$AccountCopyWithImpl(this._self, this._then);

  final Account _self;
  final $Res Function(Account) _then;

/// Create a copy of Account
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? accountNo = freezed,Object? accountType = null,Object? sovereigntyRegion = null,Object? institutionName = null,Object? status = null,Object? openedAt = freezed,Object? extInfo = freezed,Object? fxSpreadPercent = null,Object? createdAt = null,Object? updatedAt = null,Object? isDeleted = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,accountNo: freezed == accountNo ? _self.accountNo : accountNo // ignore: cast_nullable_to_non_nullable
as String?,accountType: null == accountType ? _self.accountType : accountType // ignore: cast_nullable_to_non_nullable
as AccountType,sovereigntyRegion: null == sovereigntyRegion ? _self.sovereigntyRegion : sovereigntyRegion // ignore: cast_nullable_to_non_nullable
as String,institutionName: null == institutionName ? _self.institutionName : institutionName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AccountStatus,openedAt: freezed == openedAt ? _self.openedAt : openedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,extInfo: freezed == extInfo ? _self.extInfo : extInfo // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,fxSpreadPercent: null == fxSpreadPercent ? _self.fxSpreadPercent : fxSpreadPercent // ignore: cast_nullable_to_non_nullable
as double,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Account].
extension AccountPatterns on Account {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Account value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Account() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Account value)  $default,){
final _that = this;
switch (_that) {
case _Account():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Account value)?  $default,){
final _that = this;
switch (_that) {
case _Account() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? accountNo,  AccountType accountType,  String sovereigntyRegion,  String institutionName,  AccountStatus status,  DateTime? openedAt,  Map<String, dynamic>? extInfo,  double fxSpreadPercent,  DateTime createdAt,  DateTime updatedAt,  bool isDeleted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Account() when $default != null:
return $default(_that.id,_that.accountNo,_that.accountType,_that.sovereigntyRegion,_that.institutionName,_that.status,_that.openedAt,_that.extInfo,_that.fxSpreadPercent,_that.createdAt,_that.updatedAt,_that.isDeleted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? accountNo,  AccountType accountType,  String sovereigntyRegion,  String institutionName,  AccountStatus status,  DateTime? openedAt,  Map<String, dynamic>? extInfo,  double fxSpreadPercent,  DateTime createdAt,  DateTime updatedAt,  bool isDeleted)  $default,) {final _that = this;
switch (_that) {
case _Account():
return $default(_that.id,_that.accountNo,_that.accountType,_that.sovereigntyRegion,_that.institutionName,_that.status,_that.openedAt,_that.extInfo,_that.fxSpreadPercent,_that.createdAt,_that.updatedAt,_that.isDeleted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? accountNo,  AccountType accountType,  String sovereigntyRegion,  String institutionName,  AccountStatus status,  DateTime? openedAt,  Map<String, dynamic>? extInfo,  double fxSpreadPercent,  DateTime createdAt,  DateTime updatedAt,  bool isDeleted)?  $default,) {final _that = this;
switch (_that) {
case _Account() when $default != null:
return $default(_that.id,_that.accountNo,_that.accountType,_that.sovereigntyRegion,_that.institutionName,_that.status,_that.openedAt,_that.extInfo,_that.fxSpreadPercent,_that.createdAt,_that.updatedAt,_that.isDeleted);case _:
  return null;

}
}

}

/// @nodoc


class _Account implements Account {
  const _Account({required this.id, this.accountNo, required this.accountType, required this.sovereigntyRegion, required this.institutionName, required this.status, this.openedAt, final  Map<String, dynamic>? extInfo, this.fxSpreadPercent = 0, required this.createdAt, required this.updatedAt, this.isDeleted = false}): _extInfo = extInfo;
  

@override final  String id;
@override final  String? accountNo;
@override final  AccountType accountType;
@override final  String sovereigntyRegion;
@override final  String institutionName;
@override final  AccountStatus status;
@override final  DateTime? openedAt;
 final  Map<String, dynamic>? _extInfo;
@override Map<String, dynamic>? get extInfo {
  final value = _extInfo;
  if (value == null) return null;
  if (_extInfo is EqualUnmodifiableMapView) return _extInfo;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

/// FX spread percentage (0–100, e.g. 0.3 = 0.3% loss per conversion).
/// 0 means this account does not support internal currency exchange.
@override@JsonKey() final  double fxSpreadPercent;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override@JsonKey() final  bool isDeleted;

/// Create a copy of Account
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccountCopyWith<_Account> get copyWith => __$AccountCopyWithImpl<_Account>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Account&&(identical(other.id, id) || other.id == id)&&(identical(other.accountNo, accountNo) || other.accountNo == accountNo)&&(identical(other.accountType, accountType) || other.accountType == accountType)&&(identical(other.sovereigntyRegion, sovereigntyRegion) || other.sovereigntyRegion == sovereigntyRegion)&&(identical(other.institutionName, institutionName) || other.institutionName == institutionName)&&(identical(other.status, status) || other.status == status)&&(identical(other.openedAt, openedAt) || other.openedAt == openedAt)&&const DeepCollectionEquality().equals(other._extInfo, _extInfo)&&(identical(other.fxSpreadPercent, fxSpreadPercent) || other.fxSpreadPercent == fxSpreadPercent)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted));
}


@override
int get hashCode => Object.hash(runtimeType,id,accountNo,accountType,sovereigntyRegion,institutionName,status,openedAt,const DeepCollectionEquality().hash(_extInfo),fxSpreadPercent,createdAt,updatedAt,isDeleted);

@override
String toString() {
  return 'Account(id: $id, accountNo: $accountNo, accountType: $accountType, sovereigntyRegion: $sovereigntyRegion, institutionName: $institutionName, status: $status, openedAt: $openedAt, extInfo: $extInfo, fxSpreadPercent: $fxSpreadPercent, createdAt: $createdAt, updatedAt: $updatedAt, isDeleted: $isDeleted)';
}


}

/// @nodoc
abstract mixin class _$AccountCopyWith<$Res> implements $AccountCopyWith<$Res> {
  factory _$AccountCopyWith(_Account value, $Res Function(_Account) _then) = __$AccountCopyWithImpl;
@override @useResult
$Res call({
 String id, String? accountNo, AccountType accountType, String sovereigntyRegion, String institutionName, AccountStatus status, DateTime? openedAt, Map<String, dynamic>? extInfo, double fxSpreadPercent, DateTime createdAt, DateTime updatedAt, bool isDeleted
});




}
/// @nodoc
class __$AccountCopyWithImpl<$Res>
    implements _$AccountCopyWith<$Res> {
  __$AccountCopyWithImpl(this._self, this._then);

  final _Account _self;
  final $Res Function(_Account) _then;

/// Create a copy of Account
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? accountNo = freezed,Object? accountType = null,Object? sovereigntyRegion = null,Object? institutionName = null,Object? status = null,Object? openedAt = freezed,Object? extInfo = freezed,Object? fxSpreadPercent = null,Object? createdAt = null,Object? updatedAt = null,Object? isDeleted = null,}) {
  return _then(_Account(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,accountNo: freezed == accountNo ? _self.accountNo : accountNo // ignore: cast_nullable_to_non_nullable
as String?,accountType: null == accountType ? _self.accountType : accountType // ignore: cast_nullable_to_non_nullable
as AccountType,sovereigntyRegion: null == sovereigntyRegion ? _self.sovereigntyRegion : sovereigntyRegion // ignore: cast_nullable_to_non_nullable
as String,institutionName: null == institutionName ? _self.institutionName : institutionName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AccountStatus,openedAt: freezed == openedAt ? _self.openedAt : openedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,extInfo: freezed == extInfo ? _self._extInfo : extInfo // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,fxSpreadPercent: null == fxSpreadPercent ? _self.fxSpreadPercent : fxSpreadPercent // ignore: cast_nullable_to_non_nullable
as double,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
