// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'test_day_exercise.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TestDayExercise _$TestDayExerciseFromJson(Map<String, dynamic> json) {
  return _TestDayExercise.fromJson(json);
}

/// @nodoc
mixin _$TestDayExercise {
  String get name => throw _privateConstructorUsedError;
  MuscleGroup get muscle => throw _privateConstructorUsedError;
  double get baseWeight => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TestDayExerciseCopyWith<TestDayExercise> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TestDayExerciseCopyWith<$Res> {
  factory $TestDayExerciseCopyWith(
    TestDayExercise value,
    $Res Function(TestDayExercise) then,
  ) = _$TestDayExerciseCopyWithImpl<$Res, TestDayExercise>;
  @useResult
  $Res call({String name, MuscleGroup muscle, double baseWeight});
}

/// @nodoc
class _$TestDayExerciseCopyWithImpl<$Res, $Val extends TestDayExercise>
    implements $TestDayExerciseCopyWith<$Res> {
  _$TestDayExerciseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? muscle = null,
    Object? baseWeight = null,
  }) {
    return _then(
      _value.copyWith(
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            muscle: null == muscle
                ? _value.muscle
                : muscle // ignore: cast_nullable_to_non_nullable
                      as MuscleGroup,
            baseWeight: null == baseWeight
                ? _value.baseWeight
                : baseWeight // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TestDayExerciseImplCopyWith<$Res>
    implements $TestDayExerciseCopyWith<$Res> {
  factory _$$TestDayExerciseImplCopyWith(
    _$TestDayExerciseImpl value,
    $Res Function(_$TestDayExerciseImpl) then,
  ) = __$$TestDayExerciseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String name, MuscleGroup muscle, double baseWeight});
}

/// @nodoc
class __$$TestDayExerciseImplCopyWithImpl<$Res>
    extends _$TestDayExerciseCopyWithImpl<$Res, _$TestDayExerciseImpl>
    implements _$$TestDayExerciseImplCopyWith<$Res> {
  __$$TestDayExerciseImplCopyWithImpl(
    _$TestDayExerciseImpl _value,
    $Res Function(_$TestDayExerciseImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? muscle = null,
    Object? baseWeight = null,
  }) {
    return _then(
      _$TestDayExerciseImpl(
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        muscle: null == muscle
            ? _value.muscle
            : muscle // ignore: cast_nullable_to_non_nullable
                  as MuscleGroup,
        baseWeight: null == baseWeight
            ? _value.baseWeight
            : baseWeight // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TestDayExerciseImpl implements _TestDayExercise {
  const _$TestDayExerciseImpl({
    required this.name,
    required this.muscle,
    required this.baseWeight,
  });

  factory _$TestDayExerciseImpl.fromJson(Map<String, dynamic> json) =>
      _$$TestDayExerciseImplFromJson(json);

  @override
  final String name;
  @override
  final MuscleGroup muscle;
  @override
  final double baseWeight;

  @override
  String toString() {
    return 'TestDayExercise(name: $name, muscle: $muscle, baseWeight: $baseWeight)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TestDayExerciseImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.muscle, muscle) || other.muscle == muscle) &&
            (identical(other.baseWeight, baseWeight) ||
                other.baseWeight == baseWeight));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, name, muscle, baseWeight);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TestDayExerciseImplCopyWith<_$TestDayExerciseImpl> get copyWith =>
      __$$TestDayExerciseImplCopyWithImpl<_$TestDayExerciseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$TestDayExerciseImplToJson(this);
  }
}

abstract class _TestDayExercise implements TestDayExercise {
  const factory _TestDayExercise({
    required final String name,
    required final MuscleGroup muscle,
    required final double baseWeight,
  }) = _$TestDayExerciseImpl;

  factory _TestDayExercise.fromJson(Map<String, dynamic> json) =
      _$TestDayExerciseImpl.fromJson;

  @override
  String get name;
  @override
  MuscleGroup get muscle;
  @override
  double get baseWeight;
  @override
  @JsonKey(ignore: true)
  _$$TestDayExerciseImplCopyWith<_$TestDayExerciseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
