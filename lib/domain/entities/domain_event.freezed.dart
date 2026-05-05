// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'domain_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DomainEvent {

 String get id; String get eventType; RelatedModel get relatedModel; String get relatedId; DateTime get triggerTime; EventPriority? get priority; EventStatus get status; HandlingStatus? get handlingStatus; String? get handler; String? get handlingNote;// —— 幂等与聚合 ——
/// 幂等键；形如 `{eventType}:{relatedId}:{yyyymmdd}:{source}`。
/// 写入前调用方应先查重，存在则跳过。
 String? get sourceKey;/// 批次 ID：一次同步 / 导入产生的多个事件共享同一 batch，UI 可折叠。
 String? get batchId;/// 截止时间：REQUIRED 类事件需要在此之前被确认（到期 / 还款）。
 DateTime? get dueAt;/// 辅助关联；主关联在 [relatedId]，这里放 role → (model, id)。
 Map<String, String>? get refs;// —— 用户确认维度（与 handling_status 正交）——
 AckRequirement get ackRequirement; AckStatus get ackStatus; DateTime? get ackAt; String? get ackNote; bool get isDeleted; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of DomainEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DomainEventCopyWith<DomainEvent> get copyWith => _$DomainEventCopyWithImpl<DomainEvent>(this as DomainEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DomainEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.relatedModel, relatedModel) || other.relatedModel == relatedModel)&&(identical(other.relatedId, relatedId) || other.relatedId == relatedId)&&(identical(other.triggerTime, triggerTime) || other.triggerTime == triggerTime)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.status, status) || other.status == status)&&(identical(other.handlingStatus, handlingStatus) || other.handlingStatus == handlingStatus)&&(identical(other.handler, handler) || other.handler == handler)&&(identical(other.handlingNote, handlingNote) || other.handlingNote == handlingNote)&&(identical(other.sourceKey, sourceKey) || other.sourceKey == sourceKey)&&(identical(other.batchId, batchId) || other.batchId == batchId)&&(identical(other.dueAt, dueAt) || other.dueAt == dueAt)&&const DeepCollectionEquality().equals(other.refs, refs)&&(identical(other.ackRequirement, ackRequirement) || other.ackRequirement == ackRequirement)&&(identical(other.ackStatus, ackStatus) || other.ackStatus == ackStatus)&&(identical(other.ackAt, ackAt) || other.ackAt == ackAt)&&(identical(other.ackNote, ackNote) || other.ackNote == ackNote)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,eventType,relatedModel,relatedId,triggerTime,priority,status,handlingStatus,handler,handlingNote,sourceKey,batchId,dueAt,const DeepCollectionEquality().hash(refs),ackRequirement,ackStatus,ackAt,ackNote,isDeleted,createdAt,updatedAt]);

@override
String toString() {
  return 'DomainEvent(id: $id, eventType: $eventType, relatedModel: $relatedModel, relatedId: $relatedId, triggerTime: $triggerTime, priority: $priority, status: $status, handlingStatus: $handlingStatus, handler: $handler, handlingNote: $handlingNote, sourceKey: $sourceKey, batchId: $batchId, dueAt: $dueAt, refs: $refs, ackRequirement: $ackRequirement, ackStatus: $ackStatus, ackAt: $ackAt, ackNote: $ackNote, isDeleted: $isDeleted, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $DomainEventCopyWith<$Res>  {
  factory $DomainEventCopyWith(DomainEvent value, $Res Function(DomainEvent) _then) = _$DomainEventCopyWithImpl;
@useResult
$Res call({
 String id, String eventType, RelatedModel relatedModel, String relatedId, DateTime triggerTime, EventPriority? priority, EventStatus status, HandlingStatus? handlingStatus, String? handler, String? handlingNote, String? sourceKey, String? batchId, DateTime? dueAt, Map<String, String>? refs, AckRequirement ackRequirement, AckStatus ackStatus, DateTime? ackAt, String? ackNote, bool isDeleted, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$DomainEventCopyWithImpl<$Res>
    implements $DomainEventCopyWith<$Res> {
  _$DomainEventCopyWithImpl(this._self, this._then);

  final DomainEvent _self;
  final $Res Function(DomainEvent) _then;

/// Create a copy of DomainEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? eventType = null,Object? relatedModel = null,Object? relatedId = null,Object? triggerTime = null,Object? priority = freezed,Object? status = null,Object? handlingStatus = freezed,Object? handler = freezed,Object? handlingNote = freezed,Object? sourceKey = freezed,Object? batchId = freezed,Object? dueAt = freezed,Object? refs = freezed,Object? ackRequirement = null,Object? ackStatus = null,Object? ackAt = freezed,Object? ackNote = freezed,Object? isDeleted = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as String,relatedModel: null == relatedModel ? _self.relatedModel : relatedModel // ignore: cast_nullable_to_non_nullable
as RelatedModel,relatedId: null == relatedId ? _self.relatedId : relatedId // ignore: cast_nullable_to_non_nullable
as String,triggerTime: null == triggerTime ? _self.triggerTime : triggerTime // ignore: cast_nullable_to_non_nullable
as DateTime,priority: freezed == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as EventPriority?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as EventStatus,handlingStatus: freezed == handlingStatus ? _self.handlingStatus : handlingStatus // ignore: cast_nullable_to_non_nullable
as HandlingStatus?,handler: freezed == handler ? _self.handler : handler // ignore: cast_nullable_to_non_nullable
as String?,handlingNote: freezed == handlingNote ? _self.handlingNote : handlingNote // ignore: cast_nullable_to_non_nullable
as String?,sourceKey: freezed == sourceKey ? _self.sourceKey : sourceKey // ignore: cast_nullable_to_non_nullable
as String?,batchId: freezed == batchId ? _self.batchId : batchId // ignore: cast_nullable_to_non_nullable
as String?,dueAt: freezed == dueAt ? _self.dueAt : dueAt // ignore: cast_nullable_to_non_nullable
as DateTime?,refs: freezed == refs ? _self.refs : refs // ignore: cast_nullable_to_non_nullable
as Map<String, String>?,ackRequirement: null == ackRequirement ? _self.ackRequirement : ackRequirement // ignore: cast_nullable_to_non_nullable
as AckRequirement,ackStatus: null == ackStatus ? _self.ackStatus : ackStatus // ignore: cast_nullable_to_non_nullable
as AckStatus,ackAt: freezed == ackAt ? _self.ackAt : ackAt // ignore: cast_nullable_to_non_nullable
as DateTime?,ackNote: freezed == ackNote ? _self.ackNote : ackNote // ignore: cast_nullable_to_non_nullable
as String?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [DomainEvent].
extension DomainEventPatterns on DomainEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DomainEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DomainEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DomainEvent value)  $default,){
final _that = this;
switch (_that) {
case _DomainEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DomainEvent value)?  $default,){
final _that = this;
switch (_that) {
case _DomainEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String eventType,  RelatedModel relatedModel,  String relatedId,  DateTime triggerTime,  EventPriority? priority,  EventStatus status,  HandlingStatus? handlingStatus,  String? handler,  String? handlingNote,  String? sourceKey,  String? batchId,  DateTime? dueAt,  Map<String, String>? refs,  AckRequirement ackRequirement,  AckStatus ackStatus,  DateTime? ackAt,  String? ackNote,  bool isDeleted,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DomainEvent() when $default != null:
return $default(_that.id,_that.eventType,_that.relatedModel,_that.relatedId,_that.triggerTime,_that.priority,_that.status,_that.handlingStatus,_that.handler,_that.handlingNote,_that.sourceKey,_that.batchId,_that.dueAt,_that.refs,_that.ackRequirement,_that.ackStatus,_that.ackAt,_that.ackNote,_that.isDeleted,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String eventType,  RelatedModel relatedModel,  String relatedId,  DateTime triggerTime,  EventPriority? priority,  EventStatus status,  HandlingStatus? handlingStatus,  String? handler,  String? handlingNote,  String? sourceKey,  String? batchId,  DateTime? dueAt,  Map<String, String>? refs,  AckRequirement ackRequirement,  AckStatus ackStatus,  DateTime? ackAt,  String? ackNote,  bool isDeleted,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _DomainEvent():
return $default(_that.id,_that.eventType,_that.relatedModel,_that.relatedId,_that.triggerTime,_that.priority,_that.status,_that.handlingStatus,_that.handler,_that.handlingNote,_that.sourceKey,_that.batchId,_that.dueAt,_that.refs,_that.ackRequirement,_that.ackStatus,_that.ackAt,_that.ackNote,_that.isDeleted,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String eventType,  RelatedModel relatedModel,  String relatedId,  DateTime triggerTime,  EventPriority? priority,  EventStatus status,  HandlingStatus? handlingStatus,  String? handler,  String? handlingNote,  String? sourceKey,  String? batchId,  DateTime? dueAt,  Map<String, String>? refs,  AckRequirement ackRequirement,  AckStatus ackStatus,  DateTime? ackAt,  String? ackNote,  bool isDeleted,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _DomainEvent() when $default != null:
return $default(_that.id,_that.eventType,_that.relatedModel,_that.relatedId,_that.triggerTime,_that.priority,_that.status,_that.handlingStatus,_that.handler,_that.handlingNote,_that.sourceKey,_that.batchId,_that.dueAt,_that.refs,_that.ackRequirement,_that.ackStatus,_that.ackAt,_that.ackNote,_that.isDeleted,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _DomainEvent implements DomainEvent {
  const _DomainEvent({required this.id, required this.eventType, required this.relatedModel, required this.relatedId, required this.triggerTime, this.priority, required this.status, this.handlingStatus, this.handler, this.handlingNote, this.sourceKey, this.batchId, this.dueAt, final  Map<String, String>? refs, this.ackRequirement = AckRequirement.notApplicable, this.ackStatus = AckStatus.pending, this.ackAt, this.ackNote, this.isDeleted = false, required this.createdAt, required this.updatedAt}): _refs = refs;
  

@override final  String id;
@override final  String eventType;
@override final  RelatedModel relatedModel;
@override final  String relatedId;
@override final  DateTime triggerTime;
@override final  EventPriority? priority;
@override final  EventStatus status;
@override final  HandlingStatus? handlingStatus;
@override final  String? handler;
@override final  String? handlingNote;
// —— 幂等与聚合 ——
/// 幂等键；形如 `{eventType}:{relatedId}:{yyyymmdd}:{source}`。
/// 写入前调用方应先查重，存在则跳过。
@override final  String? sourceKey;
/// 批次 ID：一次同步 / 导入产生的多个事件共享同一 batch，UI 可折叠。
@override final  String? batchId;
/// 截止时间：REQUIRED 类事件需要在此之前被确认（到期 / 还款）。
@override final  DateTime? dueAt;
/// 辅助关联；主关联在 [relatedId]，这里放 role → (model, id)。
 final  Map<String, String>? _refs;
/// 辅助关联；主关联在 [relatedId]，这里放 role → (model, id)。
@override Map<String, String>? get refs {
  final value = _refs;
  if (value == null) return null;
  if (_refs is EqualUnmodifiableMapView) return _refs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

// —— 用户确认维度（与 handling_status 正交）——
@override@JsonKey() final  AckRequirement ackRequirement;
@override@JsonKey() final  AckStatus ackStatus;
@override final  DateTime? ackAt;
@override final  String? ackNote;
@override@JsonKey() final  bool isDeleted;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of DomainEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DomainEventCopyWith<_DomainEvent> get copyWith => __$DomainEventCopyWithImpl<_DomainEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DomainEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.relatedModel, relatedModel) || other.relatedModel == relatedModel)&&(identical(other.relatedId, relatedId) || other.relatedId == relatedId)&&(identical(other.triggerTime, triggerTime) || other.triggerTime == triggerTime)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.status, status) || other.status == status)&&(identical(other.handlingStatus, handlingStatus) || other.handlingStatus == handlingStatus)&&(identical(other.handler, handler) || other.handler == handler)&&(identical(other.handlingNote, handlingNote) || other.handlingNote == handlingNote)&&(identical(other.sourceKey, sourceKey) || other.sourceKey == sourceKey)&&(identical(other.batchId, batchId) || other.batchId == batchId)&&(identical(other.dueAt, dueAt) || other.dueAt == dueAt)&&const DeepCollectionEquality().equals(other._refs, _refs)&&(identical(other.ackRequirement, ackRequirement) || other.ackRequirement == ackRequirement)&&(identical(other.ackStatus, ackStatus) || other.ackStatus == ackStatus)&&(identical(other.ackAt, ackAt) || other.ackAt == ackAt)&&(identical(other.ackNote, ackNote) || other.ackNote == ackNote)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,eventType,relatedModel,relatedId,triggerTime,priority,status,handlingStatus,handler,handlingNote,sourceKey,batchId,dueAt,const DeepCollectionEquality().hash(_refs),ackRequirement,ackStatus,ackAt,ackNote,isDeleted,createdAt,updatedAt]);

@override
String toString() {
  return 'DomainEvent(id: $id, eventType: $eventType, relatedModel: $relatedModel, relatedId: $relatedId, triggerTime: $triggerTime, priority: $priority, status: $status, handlingStatus: $handlingStatus, handler: $handler, handlingNote: $handlingNote, sourceKey: $sourceKey, batchId: $batchId, dueAt: $dueAt, refs: $refs, ackRequirement: $ackRequirement, ackStatus: $ackStatus, ackAt: $ackAt, ackNote: $ackNote, isDeleted: $isDeleted, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$DomainEventCopyWith<$Res> implements $DomainEventCopyWith<$Res> {
  factory _$DomainEventCopyWith(_DomainEvent value, $Res Function(_DomainEvent) _then) = __$DomainEventCopyWithImpl;
@override @useResult
$Res call({
 String id, String eventType, RelatedModel relatedModel, String relatedId, DateTime triggerTime, EventPriority? priority, EventStatus status, HandlingStatus? handlingStatus, String? handler, String? handlingNote, String? sourceKey, String? batchId, DateTime? dueAt, Map<String, String>? refs, AckRequirement ackRequirement, AckStatus ackStatus, DateTime? ackAt, String? ackNote, bool isDeleted, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$DomainEventCopyWithImpl<$Res>
    implements _$DomainEventCopyWith<$Res> {
  __$DomainEventCopyWithImpl(this._self, this._then);

  final _DomainEvent _self;
  final $Res Function(_DomainEvent) _then;

/// Create a copy of DomainEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? eventType = null,Object? relatedModel = null,Object? relatedId = null,Object? triggerTime = null,Object? priority = freezed,Object? status = null,Object? handlingStatus = freezed,Object? handler = freezed,Object? handlingNote = freezed,Object? sourceKey = freezed,Object? batchId = freezed,Object? dueAt = freezed,Object? refs = freezed,Object? ackRequirement = null,Object? ackStatus = null,Object? ackAt = freezed,Object? ackNote = freezed,Object? isDeleted = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_DomainEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as String,relatedModel: null == relatedModel ? _self.relatedModel : relatedModel // ignore: cast_nullable_to_non_nullable
as RelatedModel,relatedId: null == relatedId ? _self.relatedId : relatedId // ignore: cast_nullable_to_non_nullable
as String,triggerTime: null == triggerTime ? _self.triggerTime : triggerTime // ignore: cast_nullable_to_non_nullable
as DateTime,priority: freezed == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as EventPriority?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as EventStatus,handlingStatus: freezed == handlingStatus ? _self.handlingStatus : handlingStatus // ignore: cast_nullable_to_non_nullable
as HandlingStatus?,handler: freezed == handler ? _self.handler : handler // ignore: cast_nullable_to_non_nullable
as String?,handlingNote: freezed == handlingNote ? _self.handlingNote : handlingNote // ignore: cast_nullable_to_non_nullable
as String?,sourceKey: freezed == sourceKey ? _self.sourceKey : sourceKey // ignore: cast_nullable_to_non_nullable
as String?,batchId: freezed == batchId ? _self.batchId : batchId // ignore: cast_nullable_to_non_nullable
as String?,dueAt: freezed == dueAt ? _self.dueAt : dueAt // ignore: cast_nullable_to_non_nullable
as DateTime?,refs: freezed == refs ? _self._refs : refs // ignore: cast_nullable_to_non_nullable
as Map<String, String>?,ackRequirement: null == ackRequirement ? _self.ackRequirement : ackRequirement // ignore: cast_nullable_to_non_nullable
as AckRequirement,ackStatus: null == ackStatus ? _self.ackStatus : ackStatus // ignore: cast_nullable_to_non_nullable
as AckStatus,ackAt: freezed == ackAt ? _self.ackAt : ackAt // ignore: cast_nullable_to_non_nullable
as DateTime?,ackNote: freezed == ackNote ? _self.ackNote : ackNote // ignore: cast_nullable_to_non_nullable
as String?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
