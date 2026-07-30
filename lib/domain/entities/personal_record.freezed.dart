// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'personal_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PersonalRecord _$PersonalRecordFromJson(Map<String, dynamic> json) {
  return _PersonalRecord.fromJson(json);
}

/// @nodoc
mixin _$PersonalRecord {
  String get id => throw _privateConstructorUsedError;
  String get exerciseName => throw _privateConstructorUsedError;
  double? get weightKg => throw _privateConstructorUsedError;
  int? get reps => throw _privateConstructorUsedError;
  int? get sets => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  String get notes => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PersonalRecordCopyWith<PersonalRecord> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PersonalRecordCopyWith<$Res> {
  factory $PersonalRecordCopyWith(
          PersonalRecord value, $Res Function(PersonalRecord) then) =
      _$PersonalRecordCopyWithImpl<$Res, PersonalRecord>;
  @useResult
  $Res call(
      {String id,
      String exerciseName,
      double? weightKg,
      int? reps,
      int? sets,
      DateTime date,
      String notes});
}

/// @nodoc
class _$PersonalRecordCopyWithImpl<$Res, $Val extends PersonalRecord>
    implements $PersonalRecordCopyWith<$Res> {
  _$PersonalRecordCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? exerciseName = null,
    Object? weightKg = freezed,
    Object? reps = freezed,
    Object? sets = freezed,
    Object? date = null,
    Object? notes = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      exerciseName: null == exerciseName
          ? _value.exerciseName
          : exerciseName // ignore: cast_nullable_to_non_nullable
              as String,
      weightKg: freezed == weightKg
          ? _value.weightKg
          : weightKg // ignore: cast_nullable_to_non_nullable
              as double?,
      reps: freezed == reps
          ? _value.reps
          : reps // ignore: cast_nullable_to_non_nullable
              as int?,
      sets: freezed == sets
          ? _value.sets
          : sets // ignore: cast_nullable_to_non_nullable
              as int?,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      notes: null == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PersonalRecordImplCopyWith<$Res>
    implements $PersonalRecordCopyWith<$Res> {
  factory _$$PersonalRecordImplCopyWith(_$PersonalRecordImpl value,
          $Res Function(_$PersonalRecordImpl) then) =
      __$$PersonalRecordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String exerciseName,
      double? weightKg,
      int? reps,
      int? sets,
      DateTime date,
      String notes});
}

/// @nodoc
class __$$PersonalRecordImplCopyWithImpl<$Res>
    extends _$PersonalRecordCopyWithImpl<$Res, _$PersonalRecordImpl>
    implements _$$PersonalRecordImplCopyWith<$Res> {
  __$$PersonalRecordImplCopyWithImpl(
      _$PersonalRecordImpl _value, $Res Function(_$PersonalRecordImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? exerciseName = null,
    Object? weightKg = freezed,
    Object? reps = freezed,
    Object? sets = freezed,
    Object? date = null,
    Object? notes = null,
  }) {
    return _then(_$PersonalRecordImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      exerciseName: null == exerciseName
          ? _value.exerciseName
          : exerciseName // ignore: cast_nullable_to_non_nullable
              as String,
      weightKg: freezed == weightKg
          ? _value.weightKg
          : weightKg // ignore: cast_nullable_to_non_nullable
              as double?,
      reps: freezed == reps
          ? _value.reps
          : reps // ignore: cast_nullable_to_non_nullable
              as int?,
      sets: freezed == sets
          ? _value.sets
          : sets // ignore: cast_nullable_to_non_nullable
              as int?,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      notes: null == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PersonalRecordImpl extends _PersonalRecord {
  const _$PersonalRecordImpl(
      {required this.id,
      required this.exerciseName,
      this.weightKg,
      this.reps,
      this.sets,
      required this.date,
      this.notes = ''})
      : super._();

  factory _$PersonalRecordImpl.fromJson(Map<String, dynamic> json) =>
      _$$PersonalRecordImplFromJson(json);

  @override
  final String id;
  @override
  final String exerciseName;
  @override
  final double? weightKg;
  @override
  final int? reps;
  @override
  final int? sets;
  @override
  final DateTime date;
  @override
  @JsonKey()
  final String notes;

  @override
  String toString() {
    return 'PersonalRecord(id: $id, exerciseName: $exerciseName, weightKg: $weightKg, reps: $reps, sets: $sets, date: $date, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PersonalRecordImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.exerciseName, exerciseName) ||
                other.exerciseName == exerciseName) &&
            (identical(other.weightKg, weightKg) ||
                other.weightKg == weightKg) &&
            (identical(other.reps, reps) || other.reps == reps) &&
            (identical(other.sets, sets) || other.sets == sets) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, exerciseName, weightKg, reps, sets, date, notes);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PersonalRecordImplCopyWith<_$PersonalRecordImpl> get copyWith =>
      __$$PersonalRecordImplCopyWithImpl<_$PersonalRecordImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PersonalRecordImplToJson(
      this,
    );
  }
}

abstract class _PersonalRecord extends PersonalRecord {
  const factory _PersonalRecord(
      {required final String id,
      required final String exerciseName,
      final double? weightKg,
      final int? reps,
      final int? sets,
      required final DateTime date,
      final String notes}) = _$PersonalRecordImpl;
  const _PersonalRecord._() : super._();

  factory _PersonalRecord.fromJson(Map<String, dynamic> json) =
      _$PersonalRecordImpl.fromJson;

  @override
  String get id;
  @override
  String get exerciseName;
  @override
  double? get weightKg;
  @override
  int? get reps;
  @override
  int? get sets;
  @override
  DateTime get date;
  @override
  String get notes;
  @override
  @JsonKey(ignore: true)
  _$$PersonalRecordImplCopyWith<_$PersonalRecordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
