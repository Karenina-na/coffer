// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dict_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DictEntry {

 int get id; DictType get type; String get code; String get name; String? get nameEn; int get sortOrder; bool get isBuiltin; DateTime get createdAt; DateTime get updatedAt;// ── 地区 UI 元数据（仅 sovereigntyRegion 使用）──────────────────────────
/// Emoji 国旗，如 `'🇨🇳'`。
 String? get flagEmoji;/// 大洲分组标签，如 `'亚太'`。
 String? get continent;/// 强调色十六进制字符串，如 `'0xFFEF4444'`。
 String? get colorHex;/// 地图经度（-180 ~ 180）。
 double? get mapLon;/// 地图纬度（-90 ~ 90）。
 double? get mapLat;/// 所属上级区域 code（如 `DE` 的 `parent_region = 'EU'`）。
/// `null` 表示顶级区域。UI 展示为「区域 | 国家」层级格式。
 String? get parentRegion;
/// Create a copy of DictEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DictEntryCopyWith<DictEntry> get copyWith => _$DictEntryCopyWithImpl<DictEntry>(this as DictEntry, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DictEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.isBuiltin, isBuiltin) || other.isBuiltin == isBuiltin)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.flagEmoji, flagEmoji) || other.flagEmoji == flagEmoji)&&(identical(other.continent, continent) || other.continent == continent)&&(identical(other.colorHex, colorHex) || other.colorHex == colorHex)&&(identical(other.mapLon, mapLon) || other.mapLon == mapLon)&&(identical(other.mapLat, mapLat) || other.mapLat == mapLat)&&(identical(other.parentRegion, parentRegion) || other.parentRegion == parentRegion));
}


@override
int get hashCode => Object.hash(runtimeType,id,type,code,name,nameEn,sortOrder,isBuiltin,createdAt,updatedAt,flagEmoji,continent,colorHex,mapLon,mapLat,parentRegion);

@override
String toString() {
  return 'DictEntry(id: $id, type: $type, code: $code, name: $name, nameEn: $nameEn, sortOrder: $sortOrder, isBuiltin: $isBuiltin, createdAt: $createdAt, updatedAt: $updatedAt, flagEmoji: $flagEmoji, continent: $continent, colorHex: $colorHex, mapLon: $mapLon, mapLat: $mapLat, parentRegion: $parentRegion)';
}


}

/// @nodoc
abstract mixin class $DictEntryCopyWith<$Res>  {
  factory $DictEntryCopyWith(DictEntry value, $Res Function(DictEntry) _then) = _$DictEntryCopyWithImpl;
@useResult
$Res call({
 int id, DictType type, String code, String name, String? nameEn, int sortOrder, bool isBuiltin, DateTime createdAt, DateTime updatedAt, String? flagEmoji, String? continent, String? colorHex, double? mapLon, double? mapLat, String? parentRegion
});




}
/// @nodoc
class _$DictEntryCopyWithImpl<$Res>
    implements $DictEntryCopyWith<$Res> {
  _$DictEntryCopyWithImpl(this._self, this._then);

  final DictEntry _self;
  final $Res Function(DictEntry) _then;

/// Create a copy of DictEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? code = null,Object? name = null,Object? nameEn = freezed,Object? sortOrder = null,Object? isBuiltin = null,Object? createdAt = null,Object? updatedAt = null,Object? flagEmoji = freezed,Object? continent = freezed,Object? colorHex = freezed,Object? mapLon = freezed,Object? mapLat = freezed,Object? parentRegion = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as DictType,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameEn: freezed == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,isBuiltin: null == isBuiltin ? _self.isBuiltin : isBuiltin // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,flagEmoji: freezed == flagEmoji ? _self.flagEmoji : flagEmoji // ignore: cast_nullable_to_non_nullable
as String?,continent: freezed == continent ? _self.continent : continent // ignore: cast_nullable_to_non_nullable
as String?,colorHex: freezed == colorHex ? _self.colorHex : colorHex // ignore: cast_nullable_to_non_nullable
as String?,mapLon: freezed == mapLon ? _self.mapLon : mapLon // ignore: cast_nullable_to_non_nullable
as double?,mapLat: freezed == mapLat ? _self.mapLat : mapLat // ignore: cast_nullable_to_non_nullable
as double?,parentRegion: freezed == parentRegion ? _self.parentRegion : parentRegion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DictEntry].
extension DictEntryPatterns on DictEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DictEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DictEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DictEntry value)  $default,){
final _that = this;
switch (_that) {
case _DictEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DictEntry value)?  $default,){
final _that = this;
switch (_that) {
case _DictEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  DictType type,  String code,  String name,  String? nameEn,  int sortOrder,  bool isBuiltin,  DateTime createdAt,  DateTime updatedAt,  String? flagEmoji,  String? continent,  String? colorHex,  double? mapLon,  double? mapLat,  String? parentRegion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DictEntry() when $default != null:
return $default(_that.id,_that.type,_that.code,_that.name,_that.nameEn,_that.sortOrder,_that.isBuiltin,_that.createdAt,_that.updatedAt,_that.flagEmoji,_that.continent,_that.colorHex,_that.mapLon,_that.mapLat,_that.parentRegion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  DictType type,  String code,  String name,  String? nameEn,  int sortOrder,  bool isBuiltin,  DateTime createdAt,  DateTime updatedAt,  String? flagEmoji,  String? continent,  String? colorHex,  double? mapLon,  double? mapLat,  String? parentRegion)  $default,) {final _that = this;
switch (_that) {
case _DictEntry():
return $default(_that.id,_that.type,_that.code,_that.name,_that.nameEn,_that.sortOrder,_that.isBuiltin,_that.createdAt,_that.updatedAt,_that.flagEmoji,_that.continent,_that.colorHex,_that.mapLon,_that.mapLat,_that.parentRegion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  DictType type,  String code,  String name,  String? nameEn,  int sortOrder,  bool isBuiltin,  DateTime createdAt,  DateTime updatedAt,  String? flagEmoji,  String? continent,  String? colorHex,  double? mapLon,  double? mapLat,  String? parentRegion)?  $default,) {final _that = this;
switch (_that) {
case _DictEntry() when $default != null:
return $default(_that.id,_that.type,_that.code,_that.name,_that.nameEn,_that.sortOrder,_that.isBuiltin,_that.createdAt,_that.updatedAt,_that.flagEmoji,_that.continent,_that.colorHex,_that.mapLon,_that.mapLat,_that.parentRegion);case _:
  return null;

}
}

}

/// @nodoc


class _DictEntry implements DictEntry {
  const _DictEntry({required this.id, required this.type, required this.code, required this.name, this.nameEn, this.sortOrder = 1000, this.isBuiltin = false, required this.createdAt, required this.updatedAt, this.flagEmoji, this.continent, this.colorHex, this.mapLon, this.mapLat, this.parentRegion});
  

@override final  int id;
@override final  DictType type;
@override final  String code;
@override final  String name;
@override final  String? nameEn;
@override@JsonKey() final  int sortOrder;
@override@JsonKey() final  bool isBuiltin;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
// ── 地区 UI 元数据（仅 sovereigntyRegion 使用）──────────────────────────
/// Emoji 国旗，如 `'🇨🇳'`。
@override final  String? flagEmoji;
/// 大洲分组标签，如 `'亚太'`。
@override final  String? continent;
/// 强调色十六进制字符串，如 `'0xFFEF4444'`。
@override final  String? colorHex;
/// 地图经度（-180 ~ 180）。
@override final  double? mapLon;
/// 地图纬度（-90 ~ 90）。
@override final  double? mapLat;
/// 所属上级区域 code（如 `DE` 的 `parent_region = 'EU'`）。
/// `null` 表示顶级区域。UI 展示为「区域 | 国家」层级格式。
@override final  String? parentRegion;

/// Create a copy of DictEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DictEntryCopyWith<_DictEntry> get copyWith => __$DictEntryCopyWithImpl<_DictEntry>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DictEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.isBuiltin, isBuiltin) || other.isBuiltin == isBuiltin)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.flagEmoji, flagEmoji) || other.flagEmoji == flagEmoji)&&(identical(other.continent, continent) || other.continent == continent)&&(identical(other.colorHex, colorHex) || other.colorHex == colorHex)&&(identical(other.mapLon, mapLon) || other.mapLon == mapLon)&&(identical(other.mapLat, mapLat) || other.mapLat == mapLat)&&(identical(other.parentRegion, parentRegion) || other.parentRegion == parentRegion));
}


@override
int get hashCode => Object.hash(runtimeType,id,type,code,name,nameEn,sortOrder,isBuiltin,createdAt,updatedAt,flagEmoji,continent,colorHex,mapLon,mapLat,parentRegion);

@override
String toString() {
  return 'DictEntry(id: $id, type: $type, code: $code, name: $name, nameEn: $nameEn, sortOrder: $sortOrder, isBuiltin: $isBuiltin, createdAt: $createdAt, updatedAt: $updatedAt, flagEmoji: $flagEmoji, continent: $continent, colorHex: $colorHex, mapLon: $mapLon, mapLat: $mapLat, parentRegion: $parentRegion)';
}


}

/// @nodoc
abstract mixin class _$DictEntryCopyWith<$Res> implements $DictEntryCopyWith<$Res> {
  factory _$DictEntryCopyWith(_DictEntry value, $Res Function(_DictEntry) _then) = __$DictEntryCopyWithImpl;
@override @useResult
$Res call({
 int id, DictType type, String code, String name, String? nameEn, int sortOrder, bool isBuiltin, DateTime createdAt, DateTime updatedAt, String? flagEmoji, String? continent, String? colorHex, double? mapLon, double? mapLat, String? parentRegion
});




}
/// @nodoc
class __$DictEntryCopyWithImpl<$Res>
    implements _$DictEntryCopyWith<$Res> {
  __$DictEntryCopyWithImpl(this._self, this._then);

  final _DictEntry _self;
  final $Res Function(_DictEntry) _then;

/// Create a copy of DictEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? code = null,Object? name = null,Object? nameEn = freezed,Object? sortOrder = null,Object? isBuiltin = null,Object? createdAt = null,Object? updatedAt = null,Object? flagEmoji = freezed,Object? continent = freezed,Object? colorHex = freezed,Object? mapLon = freezed,Object? mapLat = freezed,Object? parentRegion = freezed,}) {
  return _then(_DictEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as DictType,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameEn: freezed == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,isBuiltin: null == isBuiltin ? _self.isBuiltin : isBuiltin // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,flagEmoji: freezed == flagEmoji ? _self.flagEmoji : flagEmoji // ignore: cast_nullable_to_non_nullable
as String?,continent: freezed == continent ? _self.continent : continent // ignore: cast_nullable_to_non_nullable
as String?,colorHex: freezed == colorHex ? _self.colorHex : colorHex // ignore: cast_nullable_to_non_nullable
as String?,mapLon: freezed == mapLon ? _self.mapLon : mapLon // ignore: cast_nullable_to_non_nullable
as double?,mapLat: freezed == mapLat ? _self.mapLat : mapLat // ignore: cast_nullable_to_non_nullable
as double?,parentRegion: freezed == parentRegion ? _self.parentRegion : parentRegion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
