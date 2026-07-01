// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workout_entities.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TestWeekResult _$TestWeekResultFromJson(Map<String, dynamic> json) {
  return _TestWeekResult.fromJson(json);
}

/// @nodoc
mixin _$TestWeekResult {
  DateTime get completedAt => throw _privateConstructorUsedError;
  List<TestExerciseResult> get exercises => throw _privateConstructorUsedError;
  double get averageHeartRate => throw _privateConstructorUsedError;
  int get averageSessionDuration => throw _privateConstructorUsedError;
  int get perceivedDifficulty => throw _privateConstructorUsedError;
  String? get feedback => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TestWeekResultCopyWith<TestWeekResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TestWeekResultCopyWith<$Res> {
  factory $TestWeekResultCopyWith(
    TestWeekResult value,
    $Res Function(TestWeekResult) then,
  ) = _$TestWeekResultCopyWithImpl<$Res, TestWeekResult>;
  @useResult
  $Res call({
    DateTime completedAt,
    List<TestExerciseResult> exercises,
    double averageHeartRate,
    int averageSessionDuration,
    int perceivedDifficulty,
    String? feedback,
  });
}

/// @nodoc
class _$TestWeekResultCopyWithImpl<$Res, $Val extends TestWeekResult>
    implements $TestWeekResultCopyWith<$Res> {
  _$TestWeekResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? completedAt = null,
    Object? exercises = null,
    Object? averageHeartRate = null,
    Object? averageSessionDuration = null,
    Object? perceivedDifficulty = null,
    Object? feedback = freezed,
  }) {
    return _then(
      _value.copyWith(
            completedAt: null == completedAt
                ? _value.completedAt
                : completedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            exercises: null == exercises
                ? _value.exercises
                : exercises // ignore: cast_nullable_to_non_nullable
                      as List<TestExerciseResult>,
            averageHeartRate: null == averageHeartRate
                ? _value.averageHeartRate
                : averageHeartRate // ignore: cast_nullable_to_non_nullable
                      as double,
            averageSessionDuration: null == averageSessionDuration
                ? _value.averageSessionDuration
                : averageSessionDuration // ignore: cast_nullable_to_non_nullable
                      as int,
            perceivedDifficulty: null == perceivedDifficulty
                ? _value.perceivedDifficulty
                : perceivedDifficulty // ignore: cast_nullable_to_non_nullable
                      as int,
            feedback: freezed == feedback
                ? _value.feedback
                : feedback // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TestWeekResultImplCopyWith<$Res>
    implements $TestWeekResultCopyWith<$Res> {
  factory _$$TestWeekResultImplCopyWith(
    _$TestWeekResultImpl value,
    $Res Function(_$TestWeekResultImpl) then,
  ) = __$$TestWeekResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    DateTime completedAt,
    List<TestExerciseResult> exercises,
    double averageHeartRate,
    int averageSessionDuration,
    int perceivedDifficulty,
    String? feedback,
  });
}

/// @nodoc
class __$$TestWeekResultImplCopyWithImpl<$Res>
    extends _$TestWeekResultCopyWithImpl<$Res, _$TestWeekResultImpl>
    implements _$$TestWeekResultImplCopyWith<$Res> {
  __$$TestWeekResultImplCopyWithImpl(
    _$TestWeekResultImpl _value,
    $Res Function(_$TestWeekResultImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? completedAt = null,
    Object? exercises = null,
    Object? averageHeartRate = null,
    Object? averageSessionDuration = null,
    Object? perceivedDifficulty = null,
    Object? feedback = freezed,
  }) {
    return _then(
      _$TestWeekResultImpl(
        completedAt: null == completedAt
            ? _value.completedAt
            : completedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        exercises: null == exercises
            ? _value._exercises
            : exercises // ignore: cast_nullable_to_non_nullable
                  as List<TestExerciseResult>,
        averageHeartRate: null == averageHeartRate
            ? _value.averageHeartRate
            : averageHeartRate // ignore: cast_nullable_to_non_nullable
                  as double,
        averageSessionDuration: null == averageSessionDuration
            ? _value.averageSessionDuration
            : averageSessionDuration // ignore: cast_nullable_to_non_nullable
                  as int,
        perceivedDifficulty: null == perceivedDifficulty
            ? _value.perceivedDifficulty
            : perceivedDifficulty // ignore: cast_nullable_to_non_nullable
                  as int,
        feedback: freezed == feedback
            ? _value.feedback
            : feedback // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TestWeekResultImpl implements _TestWeekResult {
  const _$TestWeekResultImpl({
    required this.completedAt,
    required final List<TestExerciseResult> exercises,
    this.averageHeartRate = 0,
    this.averageSessionDuration = 0,
    this.perceivedDifficulty = 5,
    this.feedback,
  }) : _exercises = exercises;

  factory _$TestWeekResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$TestWeekResultImplFromJson(json);

  @override
  final DateTime completedAt;
  final List<TestExerciseResult> _exercises;
  @override
  List<TestExerciseResult> get exercises {
    if (_exercises is EqualUnmodifiableListView) return _exercises;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_exercises);
  }

  @override
  @JsonKey()
  final double averageHeartRate;
  @override
  @JsonKey()
  final int averageSessionDuration;
  @override
  @JsonKey()
  final int perceivedDifficulty;
  @override
  final String? feedback;

  @override
  String toString() {
    return 'TestWeekResult(completedAt: $completedAt, exercises: $exercises, averageHeartRate: $averageHeartRate, averageSessionDuration: $averageSessionDuration, perceivedDifficulty: $perceivedDifficulty, feedback: $feedback)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TestWeekResultImpl &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            const DeepCollectionEquality().equals(
              other._exercises,
              _exercises,
            ) &&
            (identical(other.averageHeartRate, averageHeartRate) ||
                other.averageHeartRate == averageHeartRate) &&
            (identical(other.averageSessionDuration, averageSessionDuration) ||
                other.averageSessionDuration == averageSessionDuration) &&
            (identical(other.perceivedDifficulty, perceivedDifficulty) ||
                other.perceivedDifficulty == perceivedDifficulty) &&
            (identical(other.feedback, feedback) ||
                other.feedback == feedback));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    completedAt,
    const DeepCollectionEquality().hash(_exercises),
    averageHeartRate,
    averageSessionDuration,
    perceivedDifficulty,
    feedback,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TestWeekResultImplCopyWith<_$TestWeekResultImpl> get copyWith =>
      __$$TestWeekResultImplCopyWithImpl<_$TestWeekResultImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$TestWeekResultImplToJson(this);
  }
}

abstract class _TestWeekResult implements TestWeekResult {
  const factory _TestWeekResult({
    required final DateTime completedAt,
    required final List<TestExerciseResult> exercises,
    final double averageHeartRate,
    final int averageSessionDuration,
    final int perceivedDifficulty,
    final String? feedback,
  }) = _$TestWeekResultImpl;

  factory _TestWeekResult.fromJson(Map<String, dynamic> json) =
      _$TestWeekResultImpl.fromJson;

  @override
  DateTime get completedAt;
  @override
  List<TestExerciseResult> get exercises;
  @override
  double get averageHeartRate;
  @override
  int get averageSessionDuration;
  @override
  int get perceivedDifficulty;
  @override
  String? get feedback;
  @override
  @JsonKey(ignore: true)
  _$$TestWeekResultImplCopyWith<_$TestWeekResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

WorkoutPlan _$WorkoutPlanFromJson(Map<String, dynamic> json) {
  return _WorkoutPlan.fromJson(json);
}

/// @nodoc
mixin _$WorkoutPlan {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  FitnessGoal get goal => throw _privateConstructorUsedError;
  IntensityLevel get intensity => throw _privateConstructorUsedError;
  int get durationWeeks => throw _privateConstructorUsedError;
  List<WorkoutWeek> get weeks => throw _privateConstructorUsedError;
  DateTime get startDate => throw _privateConstructorUsedError;
  DateTime? get completedAt => throw _privateConstructorUsedError;
  WorkoutPlanStatus get status => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WorkoutPlanCopyWith<WorkoutPlan> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkoutPlanCopyWith<$Res> {
  factory $WorkoutPlanCopyWith(
    WorkoutPlan value,
    $Res Function(WorkoutPlan) then,
  ) = _$WorkoutPlanCopyWithImpl<$Res, WorkoutPlan>;
  @useResult
  $Res call({
    String id,
    String userId,
    String title,
    FitnessGoal goal,
    IntensityLevel intensity,
    int durationWeeks,
    List<WorkoutWeek> weeks,
    DateTime startDate,
    DateTime? completedAt,
    WorkoutPlanStatus status,
  });
}

/// @nodoc
class _$WorkoutPlanCopyWithImpl<$Res, $Val extends WorkoutPlan>
    implements $WorkoutPlanCopyWith<$Res> {
  _$WorkoutPlanCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? title = null,
    Object? goal = null,
    Object? intensity = null,
    Object? durationWeeks = null,
    Object? weeks = null,
    Object? startDate = null,
    Object? completedAt = freezed,
    Object? status = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            goal: null == goal
                ? _value.goal
                : goal // ignore: cast_nullable_to_non_nullable
                      as FitnessGoal,
            intensity: null == intensity
                ? _value.intensity
                : intensity // ignore: cast_nullable_to_non_nullable
                      as IntensityLevel,
            durationWeeks: null == durationWeeks
                ? _value.durationWeeks
                : durationWeeks // ignore: cast_nullable_to_non_nullable
                      as int,
            weeks: null == weeks
                ? _value.weeks
                : weeks // ignore: cast_nullable_to_non_nullable
                      as List<WorkoutWeek>,
            startDate: null == startDate
                ? _value.startDate
                : startDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            completedAt: freezed == completedAt
                ? _value.completedAt
                : completedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as WorkoutPlanStatus,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$WorkoutPlanImplCopyWith<$Res>
    implements $WorkoutPlanCopyWith<$Res> {
  factory _$$WorkoutPlanImplCopyWith(
    _$WorkoutPlanImpl value,
    $Res Function(_$WorkoutPlanImpl) then,
  ) = __$$WorkoutPlanImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String title,
    FitnessGoal goal,
    IntensityLevel intensity,
    int durationWeeks,
    List<WorkoutWeek> weeks,
    DateTime startDate,
    DateTime? completedAt,
    WorkoutPlanStatus status,
  });
}

/// @nodoc
class __$$WorkoutPlanImplCopyWithImpl<$Res>
    extends _$WorkoutPlanCopyWithImpl<$Res, _$WorkoutPlanImpl>
    implements _$$WorkoutPlanImplCopyWith<$Res> {
  __$$WorkoutPlanImplCopyWithImpl(
    _$WorkoutPlanImpl _value,
    $Res Function(_$WorkoutPlanImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? title = null,
    Object? goal = null,
    Object? intensity = null,
    Object? durationWeeks = null,
    Object? weeks = null,
    Object? startDate = null,
    Object? completedAt = freezed,
    Object? status = null,
  }) {
    return _then(
      _$WorkoutPlanImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        goal: null == goal
            ? _value.goal
            : goal // ignore: cast_nullable_to_non_nullable
                  as FitnessGoal,
        intensity: null == intensity
            ? _value.intensity
            : intensity // ignore: cast_nullable_to_non_nullable
                  as IntensityLevel,
        durationWeeks: null == durationWeeks
            ? _value.durationWeeks
            : durationWeeks // ignore: cast_nullable_to_non_nullable
                  as int,
        weeks: null == weeks
            ? _value._weeks
            : weeks // ignore: cast_nullable_to_non_nullable
                  as List<WorkoutWeek>,
        startDate: null == startDate
            ? _value.startDate
            : startDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        completedAt: freezed == completedAt
            ? _value.completedAt
            : completedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as WorkoutPlanStatus,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkoutPlanImpl implements _WorkoutPlan {
  const _$WorkoutPlanImpl({
    required this.id,
    required this.userId,
    required this.title,
    required this.goal,
    required this.intensity,
    required this.durationWeeks,
    required final List<WorkoutWeek> weeks,
    required this.startDate,
    this.completedAt,
    this.status = WorkoutPlanStatus.active,
  }) : _weeks = weeks;

  factory _$WorkoutPlanImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkoutPlanImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String title;
  @override
  final FitnessGoal goal;
  @override
  final IntensityLevel intensity;
  @override
  final int durationWeeks;
  final List<WorkoutWeek> _weeks;
  @override
  List<WorkoutWeek> get weeks {
    if (_weeks is EqualUnmodifiableListView) return _weeks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_weeks);
  }

  @override
  final DateTime startDate;
  @override
  final DateTime? completedAt;
  @override
  @JsonKey()
  final WorkoutPlanStatus status;

  @override
  String toString() {
    return 'WorkoutPlan(id: $id, userId: $userId, title: $title, goal: $goal, intensity: $intensity, durationWeeks: $durationWeeks, weeks: $weeks, startDate: $startDate, completedAt: $completedAt, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkoutPlanImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.goal, goal) || other.goal == goal) &&
            (identical(other.intensity, intensity) ||
                other.intensity == intensity) &&
            (identical(other.durationWeeks, durationWeeks) ||
                other.durationWeeks == durationWeeks) &&
            const DeepCollectionEquality().equals(other._weeks, _weeks) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.status, status) || other.status == status));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    title,
    goal,
    intensity,
    durationWeeks,
    const DeepCollectionEquality().hash(_weeks),
    startDate,
    completedAt,
    status,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkoutPlanImplCopyWith<_$WorkoutPlanImpl> get copyWith =>
      __$$WorkoutPlanImplCopyWithImpl<_$WorkoutPlanImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkoutPlanImplToJson(this);
  }
}

abstract class _WorkoutPlan implements WorkoutPlan {
  const factory _WorkoutPlan({
    required final String id,
    required final String userId,
    required final String title,
    required final FitnessGoal goal,
    required final IntensityLevel intensity,
    required final int durationWeeks,
    required final List<WorkoutWeek> weeks,
    required final DateTime startDate,
    final DateTime? completedAt,
    final WorkoutPlanStatus status,
  }) = _$WorkoutPlanImpl;

  factory _WorkoutPlan.fromJson(Map<String, dynamic> json) =
      _$WorkoutPlanImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get title;
  @override
  FitnessGoal get goal;
  @override
  IntensityLevel get intensity;
  @override
  int get durationWeeks;
  @override
  List<WorkoutWeek> get weeks;
  @override
  DateTime get startDate;
  @override
  DateTime? get completedAt;
  @override
  WorkoutPlanStatus get status;
  @override
  @JsonKey(ignore: true)
  _$$WorkoutPlanImplCopyWith<_$WorkoutPlanImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

WorkoutWeek _$WorkoutWeekFromJson(Map<String, dynamic> json) {
  return _WorkoutWeek.fromJson(json);
}

/// @nodoc
mixin _$WorkoutWeek {
  int get weekNumber => throw _privateConstructorUsedError;
  List<WorkoutDay> get days => throw _privateConstructorUsedError;
  String? get weeklyFocus => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WorkoutWeekCopyWith<WorkoutWeek> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkoutWeekCopyWith<$Res> {
  factory $WorkoutWeekCopyWith(
    WorkoutWeek value,
    $Res Function(WorkoutWeek) then,
  ) = _$WorkoutWeekCopyWithImpl<$Res, WorkoutWeek>;
  @useResult
  $Res call({int weekNumber, List<WorkoutDay> days, String? weeklyFocus});
}

/// @nodoc
class _$WorkoutWeekCopyWithImpl<$Res, $Val extends WorkoutWeek>
    implements $WorkoutWeekCopyWith<$Res> {
  _$WorkoutWeekCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? weekNumber = null,
    Object? days = null,
    Object? weeklyFocus = freezed,
  }) {
    return _then(
      _value.copyWith(
            weekNumber: null == weekNumber
                ? _value.weekNumber
                : weekNumber // ignore: cast_nullable_to_non_nullable
                      as int,
            days: null == days
                ? _value.days
                : days // ignore: cast_nullable_to_non_nullable
                      as List<WorkoutDay>,
            weeklyFocus: freezed == weeklyFocus
                ? _value.weeklyFocus
                : weeklyFocus // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$WorkoutWeekImplCopyWith<$Res>
    implements $WorkoutWeekCopyWith<$Res> {
  factory _$$WorkoutWeekImplCopyWith(
    _$WorkoutWeekImpl value,
    $Res Function(_$WorkoutWeekImpl) then,
  ) = __$$WorkoutWeekImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int weekNumber, List<WorkoutDay> days, String? weeklyFocus});
}

/// @nodoc
class __$$WorkoutWeekImplCopyWithImpl<$Res>
    extends _$WorkoutWeekCopyWithImpl<$Res, _$WorkoutWeekImpl>
    implements _$$WorkoutWeekImplCopyWith<$Res> {
  __$$WorkoutWeekImplCopyWithImpl(
    _$WorkoutWeekImpl _value,
    $Res Function(_$WorkoutWeekImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? weekNumber = null,
    Object? days = null,
    Object? weeklyFocus = freezed,
  }) {
    return _then(
      _$WorkoutWeekImpl(
        weekNumber: null == weekNumber
            ? _value.weekNumber
            : weekNumber // ignore: cast_nullable_to_non_nullable
                  as int,
        days: null == days
            ? _value._days
            : days // ignore: cast_nullable_to_non_nullable
                  as List<WorkoutDay>,
        weeklyFocus: freezed == weeklyFocus
            ? _value.weeklyFocus
            : weeklyFocus // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkoutWeekImpl implements _WorkoutWeek {
  const _$WorkoutWeekImpl({
    required this.weekNumber,
    required final List<WorkoutDay> days,
    this.weeklyFocus,
  }) : _days = days;

  factory _$WorkoutWeekImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkoutWeekImplFromJson(json);

  @override
  final int weekNumber;
  final List<WorkoutDay> _days;
  @override
  List<WorkoutDay> get days {
    if (_days is EqualUnmodifiableListView) return _days;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_days);
  }

  @override
  final String? weeklyFocus;

  @override
  String toString() {
    return 'WorkoutWeek(weekNumber: $weekNumber, days: $days, weeklyFocus: $weeklyFocus)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkoutWeekImpl &&
            (identical(other.weekNumber, weekNumber) ||
                other.weekNumber == weekNumber) &&
            const DeepCollectionEquality().equals(other._days, _days) &&
            (identical(other.weeklyFocus, weeklyFocus) ||
                other.weeklyFocus == weeklyFocus));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    weekNumber,
    const DeepCollectionEquality().hash(_days),
    weeklyFocus,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkoutWeekImplCopyWith<_$WorkoutWeekImpl> get copyWith =>
      __$$WorkoutWeekImplCopyWithImpl<_$WorkoutWeekImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkoutWeekImplToJson(this);
  }
}

abstract class _WorkoutWeek implements WorkoutWeek {
  const factory _WorkoutWeek({
    required final int weekNumber,
    required final List<WorkoutDay> days,
    final String? weeklyFocus,
  }) = _$WorkoutWeekImpl;

  factory _WorkoutWeek.fromJson(Map<String, dynamic> json) =
      _$WorkoutWeekImpl.fromJson;

  @override
  int get weekNumber;
  @override
  List<WorkoutDay> get days;
  @override
  String? get weeklyFocus;
  @override
  @JsonKey(ignore: true)
  _$$WorkoutWeekImplCopyWith<_$WorkoutWeekImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

WorkoutDay _$WorkoutDayFromJson(Map<String, dynamic> json) {
  return _WorkoutDay.fromJson(json);
}

/// @nodoc
mixin _$WorkoutDay {
  int get dayNumber => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  WorkoutDayType get type => throw _privateConstructorUsedError;
  WorkoutSession? get session => throw _privateConstructorUsedError;
  WorkoutLog? get log => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WorkoutDayCopyWith<WorkoutDay> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkoutDayCopyWith<$Res> {
  factory $WorkoutDayCopyWith(
    WorkoutDay value,
    $Res Function(WorkoutDay) then,
  ) = _$WorkoutDayCopyWithImpl<$Res, WorkoutDay>;
  @useResult
  $Res call({
    int dayNumber,
    DateTime date,
    WorkoutDayType type,
    WorkoutSession? session,
    WorkoutLog? log,
  });

  $WorkoutSessionCopyWith<$Res>? get session;
  $WorkoutLogCopyWith<$Res>? get log;
}

/// @nodoc
class _$WorkoutDayCopyWithImpl<$Res, $Val extends WorkoutDay>
    implements $WorkoutDayCopyWith<$Res> {
  _$WorkoutDayCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dayNumber = null,
    Object? date = null,
    Object? type = null,
    Object? session = freezed,
    Object? log = freezed,
  }) {
    return _then(
      _value.copyWith(
            dayNumber: null == dayNumber
                ? _value.dayNumber
                : dayNumber // ignore: cast_nullable_to_non_nullable
                      as int,
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as WorkoutDayType,
            session: freezed == session
                ? _value.session
                : session // ignore: cast_nullable_to_non_nullable
                      as WorkoutSession?,
            log: freezed == log
                ? _value.log
                : log // ignore: cast_nullable_to_non_nullable
                      as WorkoutLog?,
          )
          as $Val,
    );
  }

  @override
  @pragma('vm:prefer-inline')
  $WorkoutSessionCopyWith<$Res>? get session {
    if (_value.session == null) {
      return null;
    }

    return $WorkoutSessionCopyWith<$Res>(_value.session!, (value) {
      return _then(_value.copyWith(session: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $WorkoutLogCopyWith<$Res>? get log {
    if (_value.log == null) {
      return null;
    }

    return $WorkoutLogCopyWith<$Res>(_value.log!, (value) {
      return _then(_value.copyWith(log: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$WorkoutDayImplCopyWith<$Res>
    implements $WorkoutDayCopyWith<$Res> {
  factory _$$WorkoutDayImplCopyWith(
    _$WorkoutDayImpl value,
    $Res Function(_$WorkoutDayImpl) then,
  ) = __$$WorkoutDayImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int dayNumber,
    DateTime date,
    WorkoutDayType type,
    WorkoutSession? session,
    WorkoutLog? log,
  });

  @override
  $WorkoutSessionCopyWith<$Res>? get session;
  @override
  $WorkoutLogCopyWith<$Res>? get log;
}

/// @nodoc
class __$$WorkoutDayImplCopyWithImpl<$Res>
    extends _$WorkoutDayCopyWithImpl<$Res, _$WorkoutDayImpl>
    implements _$$WorkoutDayImplCopyWith<$Res> {
  __$$WorkoutDayImplCopyWithImpl(
    _$WorkoutDayImpl _value,
    $Res Function(_$WorkoutDayImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dayNumber = null,
    Object? date = null,
    Object? type = null,
    Object? session = freezed,
    Object? log = freezed,
  }) {
    return _then(
      _$WorkoutDayImpl(
        dayNumber: null == dayNumber
            ? _value.dayNumber
            : dayNumber // ignore: cast_nullable_to_non_nullable
                  as int,
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as WorkoutDayType,
        session: freezed == session
            ? _value.session
            : session // ignore: cast_nullable_to_non_nullable
                  as WorkoutSession?,
        log: freezed == log
            ? _value.log
            : log // ignore: cast_nullable_to_non_nullable
                  as WorkoutLog?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkoutDayImpl extends _WorkoutDay {
  const _$WorkoutDayImpl({
    required this.dayNumber,
    required this.date,
    required this.type,
    this.session,
    this.log,
  }) : super._();

  factory _$WorkoutDayImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkoutDayImplFromJson(json);

  @override
  final int dayNumber;
  @override
  final DateTime date;
  @override
  final WorkoutDayType type;
  @override
  final WorkoutSession? session;
  @override
  final WorkoutLog? log;

  @override
  String toString() {
    return 'WorkoutDay(dayNumber: $dayNumber, date: $date, type: $type, session: $session, log: $log)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkoutDayImpl &&
            (identical(other.dayNumber, dayNumber) ||
                other.dayNumber == dayNumber) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.session, session) || other.session == session) &&
            (identical(other.log, log) || other.log == log));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, dayNumber, date, type, session, log);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkoutDayImplCopyWith<_$WorkoutDayImpl> get copyWith =>
      __$$WorkoutDayImplCopyWithImpl<_$WorkoutDayImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkoutDayImplToJson(this);
  }
}

abstract class _WorkoutDay extends WorkoutDay {
  const factory _WorkoutDay({
    required final int dayNumber,
    required final DateTime date,
    required final WorkoutDayType type,
    final WorkoutSession? session,
    final WorkoutLog? log,
  }) = _$WorkoutDayImpl;
  const _WorkoutDay._() : super._();

  factory _WorkoutDay.fromJson(Map<String, dynamic> json) =
      _$WorkoutDayImpl.fromJson;

  @override
  int get dayNumber;
  @override
  DateTime get date;
  @override
  WorkoutDayType get type;
  @override
  WorkoutSession? get session;
  @override
  WorkoutLog? get log;
  @override
  @JsonKey(ignore: true)
  _$$WorkoutDayImplCopyWith<_$WorkoutDayImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

WorkoutSession _$WorkoutSessionFromJson(Map<String, dynamic> json) {
  return _WorkoutSession.fromJson(json);
}

/// @nodoc
mixin _$WorkoutSession {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  MuscleGroup get primaryMuscle => throw _privateConstructorUsedError;
  List<MuscleGroup> get secondaryMuscles => throw _privateConstructorUsedError;
  List<ExerciseSet> get exercises => throw _privateConstructorUsedError;
  int get estimatedDurationMinutes => throw _privateConstructorUsedError;
  int get estimatedCaloriesBurn => throw _privateConstructorUsedError;
  DifficultyLevel get difficulty => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WorkoutSessionCopyWith<WorkoutSession> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkoutSessionCopyWith<$Res> {
  factory $WorkoutSessionCopyWith(
    WorkoutSession value,
    $Res Function(WorkoutSession) then,
  ) = _$WorkoutSessionCopyWithImpl<$Res, WorkoutSession>;
  @useResult
  $Res call({
    String id,
    String title,
    String? description,
    MuscleGroup primaryMuscle,
    List<MuscleGroup> secondaryMuscles,
    List<ExerciseSet> exercises,
    int estimatedDurationMinutes,
    int estimatedCaloriesBurn,
    DifficultyLevel difficulty,
  });
}

/// @nodoc
class _$WorkoutSessionCopyWithImpl<$Res, $Val extends WorkoutSession>
    implements $WorkoutSessionCopyWith<$Res> {
  _$WorkoutSessionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = freezed,
    Object? primaryMuscle = null,
    Object? secondaryMuscles = null,
    Object? exercises = null,
    Object? estimatedDurationMinutes = null,
    Object? estimatedCaloriesBurn = null,
    Object? difficulty = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            primaryMuscle: null == primaryMuscle
                ? _value.primaryMuscle
                : primaryMuscle // ignore: cast_nullable_to_non_nullable
                      as MuscleGroup,
            secondaryMuscles: null == secondaryMuscles
                ? _value.secondaryMuscles
                : secondaryMuscles // ignore: cast_nullable_to_non_nullable
                      as List<MuscleGroup>,
            exercises: null == exercises
                ? _value.exercises
                : exercises // ignore: cast_nullable_to_non_nullable
                      as List<ExerciseSet>,
            estimatedDurationMinutes: null == estimatedDurationMinutes
                ? _value.estimatedDurationMinutes
                : estimatedDurationMinutes // ignore: cast_nullable_to_non_nullable
                      as int,
            estimatedCaloriesBurn: null == estimatedCaloriesBurn
                ? _value.estimatedCaloriesBurn
                : estimatedCaloriesBurn // ignore: cast_nullable_to_non_nullable
                      as int,
            difficulty: null == difficulty
                ? _value.difficulty
                : difficulty // ignore: cast_nullable_to_non_nullable
                      as DifficultyLevel,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$WorkoutSessionImplCopyWith<$Res>
    implements $WorkoutSessionCopyWith<$Res> {
  factory _$$WorkoutSessionImplCopyWith(
    _$WorkoutSessionImpl value,
    $Res Function(_$WorkoutSessionImpl) then,
  ) = __$$WorkoutSessionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String? description,
    MuscleGroup primaryMuscle,
    List<MuscleGroup> secondaryMuscles,
    List<ExerciseSet> exercises,
    int estimatedDurationMinutes,
    int estimatedCaloriesBurn,
    DifficultyLevel difficulty,
  });
}

/// @nodoc
class __$$WorkoutSessionImplCopyWithImpl<$Res>
    extends _$WorkoutSessionCopyWithImpl<$Res, _$WorkoutSessionImpl>
    implements _$$WorkoutSessionImplCopyWith<$Res> {
  __$$WorkoutSessionImplCopyWithImpl(
    _$WorkoutSessionImpl _value,
    $Res Function(_$WorkoutSessionImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = freezed,
    Object? primaryMuscle = null,
    Object? secondaryMuscles = null,
    Object? exercises = null,
    Object? estimatedDurationMinutes = null,
    Object? estimatedCaloriesBurn = null,
    Object? difficulty = null,
  }) {
    return _then(
      _$WorkoutSessionImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        primaryMuscle: null == primaryMuscle
            ? _value.primaryMuscle
            : primaryMuscle // ignore: cast_nullable_to_non_nullable
                  as MuscleGroup,
        secondaryMuscles: null == secondaryMuscles
            ? _value._secondaryMuscles
            : secondaryMuscles // ignore: cast_nullable_to_non_nullable
                  as List<MuscleGroup>,
        exercises: null == exercises
            ? _value._exercises
            : exercises // ignore: cast_nullable_to_non_nullable
                  as List<ExerciseSet>,
        estimatedDurationMinutes: null == estimatedDurationMinutes
            ? _value.estimatedDurationMinutes
            : estimatedDurationMinutes // ignore: cast_nullable_to_non_nullable
                  as int,
        estimatedCaloriesBurn: null == estimatedCaloriesBurn
            ? _value.estimatedCaloriesBurn
            : estimatedCaloriesBurn // ignore: cast_nullable_to_non_nullable
                  as int,
        difficulty: null == difficulty
            ? _value.difficulty
            : difficulty // ignore: cast_nullable_to_non_nullable
                  as DifficultyLevel,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkoutSessionImpl implements _WorkoutSession {
  const _$WorkoutSessionImpl({
    required this.id,
    required this.title,
    this.description,
    required this.primaryMuscle,
    final List<MuscleGroup> secondaryMuscles = const [],
    required final List<ExerciseSet> exercises,
    required this.estimatedDurationMinutes,
    required this.estimatedCaloriesBurn,
    required this.difficulty,
  }) : _secondaryMuscles = secondaryMuscles,
       _exercises = exercises;

  factory _$WorkoutSessionImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkoutSessionImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String? description;
  @override
  final MuscleGroup primaryMuscle;
  final List<MuscleGroup> _secondaryMuscles;
  @override
  @JsonKey()
  List<MuscleGroup> get secondaryMuscles {
    if (_secondaryMuscles is EqualUnmodifiableListView)
      return _secondaryMuscles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_secondaryMuscles);
  }

  final List<ExerciseSet> _exercises;
  @override
  List<ExerciseSet> get exercises {
    if (_exercises is EqualUnmodifiableListView) return _exercises;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_exercises);
  }

  @override
  final int estimatedDurationMinutes;
  @override
  final int estimatedCaloriesBurn;
  @override
  final DifficultyLevel difficulty;

  @override
  String toString() {
    return 'WorkoutSession(id: $id, title: $title, description: $description, primaryMuscle: $primaryMuscle, secondaryMuscles: $secondaryMuscles, exercises: $exercises, estimatedDurationMinutes: $estimatedDurationMinutes, estimatedCaloriesBurn: $estimatedCaloriesBurn, difficulty: $difficulty)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkoutSessionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.primaryMuscle, primaryMuscle) ||
                other.primaryMuscle == primaryMuscle) &&
            const DeepCollectionEquality().equals(
              other._secondaryMuscles,
              _secondaryMuscles,
            ) &&
            const DeepCollectionEquality().equals(
              other._exercises,
              _exercises,
            ) &&
            (identical(
                  other.estimatedDurationMinutes,
                  estimatedDurationMinutes,
                ) ||
                other.estimatedDurationMinutes == estimatedDurationMinutes) &&
            (identical(other.estimatedCaloriesBurn, estimatedCaloriesBurn) ||
                other.estimatedCaloriesBurn == estimatedCaloriesBurn) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    description,
    primaryMuscle,
    const DeepCollectionEquality().hash(_secondaryMuscles),
    const DeepCollectionEquality().hash(_exercises),
    estimatedDurationMinutes,
    estimatedCaloriesBurn,
    difficulty,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkoutSessionImplCopyWith<_$WorkoutSessionImpl> get copyWith =>
      __$$WorkoutSessionImplCopyWithImpl<_$WorkoutSessionImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkoutSessionImplToJson(this);
  }
}

abstract class _WorkoutSession implements WorkoutSession {
  const factory _WorkoutSession({
    required final String id,
    required final String title,
    final String? description,
    required final MuscleGroup primaryMuscle,
    final List<MuscleGroup> secondaryMuscles,
    required final List<ExerciseSet> exercises,
    required final int estimatedDurationMinutes,
    required final int estimatedCaloriesBurn,
    required final DifficultyLevel difficulty,
  }) = _$WorkoutSessionImpl;

  factory _WorkoutSession.fromJson(Map<String, dynamic> json) =
      _$WorkoutSessionImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String? get description;
  @override
  MuscleGroup get primaryMuscle;
  @override
  List<MuscleGroup> get secondaryMuscles;
  @override
  List<ExerciseSet> get exercises;
  @override
  int get estimatedDurationMinutes;
  @override
  int get estimatedCaloriesBurn;
  @override
  DifficultyLevel get difficulty;
  @override
  @JsonKey(ignore: true)
  _$$WorkoutSessionImplCopyWith<_$WorkoutSessionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ExerciseSet _$ExerciseSetFromJson(Map<String, dynamic> json) {
  return _ExerciseSet.fromJson(json);
}

/// @nodoc
mixin _$ExerciseSet {
  Exercise get exercise => throw _privateConstructorUsedError;
  List<SetData> get sets => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  int get restSeconds => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ExerciseSetCopyWith<ExerciseSet> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExerciseSetCopyWith<$Res> {
  factory $ExerciseSetCopyWith(
    ExerciseSet value,
    $Res Function(ExerciseSet) then,
  ) = _$ExerciseSetCopyWithImpl<$Res, ExerciseSet>;
  @useResult
  $Res call({
    Exercise exercise,
    List<SetData> sets,
    String? notes,
    int restSeconds,
  });

  $ExerciseCopyWith<$Res> get exercise;
}

/// @nodoc
class _$ExerciseSetCopyWithImpl<$Res, $Val extends ExerciseSet>
    implements $ExerciseSetCopyWith<$Res> {
  _$ExerciseSetCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? exercise = null,
    Object? sets = null,
    Object? notes = freezed,
    Object? restSeconds = null,
  }) {
    return _then(
      _value.copyWith(
            exercise: null == exercise
                ? _value.exercise
                : exercise // ignore: cast_nullable_to_non_nullable
                      as Exercise,
            sets: null == sets
                ? _value.sets
                : sets // ignore: cast_nullable_to_non_nullable
                      as List<SetData>,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            restSeconds: null == restSeconds
                ? _value.restSeconds
                : restSeconds // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }

  @override
  @pragma('vm:prefer-inline')
  $ExerciseCopyWith<$Res> get exercise {
    return $ExerciseCopyWith<$Res>(_value.exercise, (value) {
      return _then(_value.copyWith(exercise: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ExerciseSetImplCopyWith<$Res>
    implements $ExerciseSetCopyWith<$Res> {
  factory _$$ExerciseSetImplCopyWith(
    _$ExerciseSetImpl value,
    $Res Function(_$ExerciseSetImpl) then,
  ) = __$$ExerciseSetImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    Exercise exercise,
    List<SetData> sets,
    String? notes,
    int restSeconds,
  });

  @override
  $ExerciseCopyWith<$Res> get exercise;
}

/// @nodoc
class __$$ExerciseSetImplCopyWithImpl<$Res>
    extends _$ExerciseSetCopyWithImpl<$Res, _$ExerciseSetImpl>
    implements _$$ExerciseSetImplCopyWith<$Res> {
  __$$ExerciseSetImplCopyWithImpl(
    _$ExerciseSetImpl _value,
    $Res Function(_$ExerciseSetImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? exercise = null,
    Object? sets = null,
    Object? notes = freezed,
    Object? restSeconds = null,
  }) {
    return _then(
      _$ExerciseSetImpl(
        exercise: null == exercise
            ? _value.exercise
            : exercise // ignore: cast_nullable_to_non_nullable
                  as Exercise,
        sets: null == sets
            ? _value._sets
            : sets // ignore: cast_nullable_to_non_nullable
                  as List<SetData>,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        restSeconds: null == restSeconds
            ? _value.restSeconds
            : restSeconds // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ExerciseSetImpl implements _ExerciseSet {
  const _$ExerciseSetImpl({
    required this.exercise,
    required final List<SetData> sets,
    this.notes,
    this.restSeconds = 60,
  }) : _sets = sets;

  factory _$ExerciseSetImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExerciseSetImplFromJson(json);

  @override
  final Exercise exercise;
  final List<SetData> _sets;
  @override
  List<SetData> get sets {
    if (_sets is EqualUnmodifiableListView) return _sets;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sets);
  }

  @override
  final String? notes;
  @override
  @JsonKey()
  final int restSeconds;

  @override
  String toString() {
    return 'ExerciseSet(exercise: $exercise, sets: $sets, notes: $notes, restSeconds: $restSeconds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExerciseSetImpl &&
            (identical(other.exercise, exercise) ||
                other.exercise == exercise) &&
            const DeepCollectionEquality().equals(other._sets, _sets) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.restSeconds, restSeconds) ||
                other.restSeconds == restSeconds));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    exercise,
    const DeepCollectionEquality().hash(_sets),
    notes,
    restSeconds,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ExerciseSetImplCopyWith<_$ExerciseSetImpl> get copyWith =>
      __$$ExerciseSetImplCopyWithImpl<_$ExerciseSetImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExerciseSetImplToJson(this);
  }
}

abstract class _ExerciseSet implements ExerciseSet {
  const factory _ExerciseSet({
    required final Exercise exercise,
    required final List<SetData> sets,
    final String? notes,
    final int restSeconds,
  }) = _$ExerciseSetImpl;

  factory _ExerciseSet.fromJson(Map<String, dynamic> json) =
      _$ExerciseSetImpl.fromJson;

  @override
  Exercise get exercise;
  @override
  List<SetData> get sets;
  @override
  String? get notes;
  @override
  int get restSeconds;
  @override
  @JsonKey(ignore: true)
  _$$ExerciseSetImplCopyWith<_$ExerciseSetImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SetData _$SetDataFromJson(Map<String, dynamic> json) {
  return _SetData.fromJson(json);
}

/// @nodoc
mixin _$SetData {
  int get setNumber => throw _privateConstructorUsedError;
  int get reps => throw _privateConstructorUsedError;
  double? get weightKg => throw _privateConstructorUsedError;
  int? get durationSeconds => throw _privateConstructorUsedError;
  bool? get completed => throw _privateConstructorUsedError;
  double? get actualWeight => throw _privateConstructorUsedError;
  int? get actualReps => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SetDataCopyWith<SetData> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SetDataCopyWith<$Res> {
  factory $SetDataCopyWith(SetData value, $Res Function(SetData) then) =
      _$SetDataCopyWithImpl<$Res, SetData>;
  @useResult
  $Res call({
    int setNumber,
    int reps,
    double? weightKg,
    int? durationSeconds,
    bool? completed,
    double? actualWeight,
    int? actualReps,
  });
}

/// @nodoc
class _$SetDataCopyWithImpl<$Res, $Val extends SetData>
    implements $SetDataCopyWith<$Res> {
  _$SetDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? setNumber = null,
    Object? reps = null,
    Object? weightKg = freezed,
    Object? durationSeconds = freezed,
    Object? completed = freezed,
    Object? actualWeight = freezed,
    Object? actualReps = freezed,
  }) {
    return _then(
      _value.copyWith(
            setNumber: null == setNumber
                ? _value.setNumber
                : setNumber // ignore: cast_nullable_to_non_nullable
                      as int,
            reps: null == reps
                ? _value.reps
                : reps // ignore: cast_nullable_to_non_nullable
                      as int,
            weightKg: freezed == weightKg
                ? _value.weightKg
                : weightKg // ignore: cast_nullable_to_non_nullable
                      as double?,
            durationSeconds: freezed == durationSeconds
                ? _value.durationSeconds
                : durationSeconds // ignore: cast_nullable_to_non_nullable
                      as int?,
            completed: freezed == completed
                ? _value.completed
                : completed // ignore: cast_nullable_to_non_nullable
                      as bool?,
            actualWeight: freezed == actualWeight
                ? _value.actualWeight
                : actualWeight // ignore: cast_nullable_to_non_nullable
                      as double?,
            actualReps: freezed == actualReps
                ? _value.actualReps
                : actualReps // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SetDataImplCopyWith<$Res> implements $SetDataCopyWith<$Res> {
  factory _$$SetDataImplCopyWith(
    _$SetDataImpl value,
    $Res Function(_$SetDataImpl) then,
  ) = __$$SetDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int setNumber,
    int reps,
    double? weightKg,
    int? durationSeconds,
    bool? completed,
    double? actualWeight,
    int? actualReps,
  });
}

/// @nodoc
class __$$SetDataImplCopyWithImpl<$Res>
    extends _$SetDataCopyWithImpl<$Res, _$SetDataImpl>
    implements _$$SetDataImplCopyWith<$Res> {
  __$$SetDataImplCopyWithImpl(
    _$SetDataImpl _value,
    $Res Function(_$SetDataImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? setNumber = null,
    Object? reps = null,
    Object? weightKg = freezed,
    Object? durationSeconds = freezed,
    Object? completed = freezed,
    Object? actualWeight = freezed,
    Object? actualReps = freezed,
  }) {
    return _then(
      _$SetDataImpl(
        setNumber: null == setNumber
            ? _value.setNumber
            : setNumber // ignore: cast_nullable_to_non_nullable
                  as int,
        reps: null == reps
            ? _value.reps
            : reps // ignore: cast_nullable_to_non_nullable
                  as int,
        weightKg: freezed == weightKg
            ? _value.weightKg
            : weightKg // ignore: cast_nullable_to_non_nullable
                  as double?,
        durationSeconds: freezed == durationSeconds
            ? _value.durationSeconds
            : durationSeconds // ignore: cast_nullable_to_non_nullable
                  as int?,
        completed: freezed == completed
            ? _value.completed
            : completed // ignore: cast_nullable_to_non_nullable
                  as bool?,
        actualWeight: freezed == actualWeight
            ? _value.actualWeight
            : actualWeight // ignore: cast_nullable_to_non_nullable
                  as double?,
        actualReps: freezed == actualReps
            ? _value.actualReps
            : actualReps // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SetDataImpl implements _SetData {
  const _$SetDataImpl({
    required this.setNumber,
    required this.reps,
    this.weightKg,
    this.durationSeconds,
    this.completed,
    this.actualWeight,
    this.actualReps,
  });

  factory _$SetDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$SetDataImplFromJson(json);

  @override
  final int setNumber;
  @override
  final int reps;
  @override
  final double? weightKg;
  @override
  final int? durationSeconds;
  @override
  final bool? completed;
  @override
  final double? actualWeight;
  @override
  final int? actualReps;

  @override
  String toString() {
    return 'SetData(setNumber: $setNumber, reps: $reps, weightKg: $weightKg, durationSeconds: $durationSeconds, completed: $completed, actualWeight: $actualWeight, actualReps: $actualReps)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SetDataImpl &&
            (identical(other.setNumber, setNumber) ||
                other.setNumber == setNumber) &&
            (identical(other.reps, reps) || other.reps == reps) &&
            (identical(other.weightKg, weightKg) ||
                other.weightKg == weightKg) &&
            (identical(other.durationSeconds, durationSeconds) ||
                other.durationSeconds == durationSeconds) &&
            (identical(other.completed, completed) ||
                other.completed == completed) &&
            (identical(other.actualWeight, actualWeight) ||
                other.actualWeight == actualWeight) &&
            (identical(other.actualReps, actualReps) ||
                other.actualReps == actualReps));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    setNumber,
    reps,
    weightKg,
    durationSeconds,
    completed,
    actualWeight,
    actualReps,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SetDataImplCopyWith<_$SetDataImpl> get copyWith =>
      __$$SetDataImplCopyWithImpl<_$SetDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SetDataImplToJson(this);
  }
}

abstract class _SetData implements SetData {
  const factory _SetData({
    required final int setNumber,
    required final int reps,
    final double? weightKg,
    final int? durationSeconds,
    final bool? completed,
    final double? actualWeight,
    final int? actualReps,
  }) = _$SetDataImpl;

  factory _SetData.fromJson(Map<String, dynamic> json) = _$SetDataImpl.fromJson;

  @override
  int get setNumber;
  @override
  int get reps;
  @override
  double? get weightKg;
  @override
  int? get durationSeconds;
  @override
  bool? get completed;
  @override
  double? get actualWeight;
  @override
  int? get actualReps;
  @override
  @JsonKey(ignore: true)
  _$$SetDataImplCopyWith<_$SetDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Exercise _$ExerciseFromJson(Map<String, dynamic> json) {
  return _Exercise.fromJson(json);
}

/// @nodoc
mixin _$Exercise {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get videoUrl => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  MuscleGroup get primaryMuscle => throw _privateConstructorUsedError;
  List<MuscleGroup> get secondaryMuscles => throw _privateConstructorUsedError;
  ExerciseType get type => throw _privateConstructorUsedError;
  List<String> get equipment => throw _privateConstructorUsedError;
  DifficultyLevel get difficulty => throw _privateConstructorUsedError;
  List<String> get instructions => throw _privateConstructorUsedError;
  List<String>? get contraindications => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ExerciseCopyWith<Exercise> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExerciseCopyWith<$Res> {
  factory $ExerciseCopyWith(Exercise value, $Res Function(Exercise) then) =
      _$ExerciseCopyWithImpl<$Res, Exercise>;
  @useResult
  $Res call({
    String id,
    String name,
    String? description,
    String? videoUrl,
    String? imageUrl,
    MuscleGroup primaryMuscle,
    List<MuscleGroup> secondaryMuscles,
    ExerciseType type,
    List<String> equipment,
    DifficultyLevel difficulty,
    List<String> instructions,
    List<String>? contraindications,
  });
}

/// @nodoc
class _$ExerciseCopyWithImpl<$Res, $Val extends Exercise>
    implements $ExerciseCopyWith<$Res> {
  _$ExerciseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? videoUrl = freezed,
    Object? imageUrl = freezed,
    Object? primaryMuscle = null,
    Object? secondaryMuscles = null,
    Object? type = null,
    Object? equipment = null,
    Object? difficulty = null,
    Object? instructions = null,
    Object? contraindications = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            videoUrl: freezed == videoUrl
                ? _value.videoUrl
                : videoUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            imageUrl: freezed == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            primaryMuscle: null == primaryMuscle
                ? _value.primaryMuscle
                : primaryMuscle // ignore: cast_nullable_to_non_nullable
                      as MuscleGroup,
            secondaryMuscles: null == secondaryMuscles
                ? _value.secondaryMuscles
                : secondaryMuscles // ignore: cast_nullable_to_non_nullable
                      as List<MuscleGroup>,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as ExerciseType,
            equipment: null == equipment
                ? _value.equipment
                : equipment // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            difficulty: null == difficulty
                ? _value.difficulty
                : difficulty // ignore: cast_nullable_to_non_nullable
                      as DifficultyLevel,
            instructions: null == instructions
                ? _value.instructions
                : instructions // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            contraindications: freezed == contraindications
                ? _value.contraindications
                : contraindications // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ExerciseImplCopyWith<$Res>
    implements $ExerciseCopyWith<$Res> {
  factory _$$ExerciseImplCopyWith(
    _$ExerciseImpl value,
    $Res Function(_$ExerciseImpl) then,
  ) = __$$ExerciseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String? description,
    String? videoUrl,
    String? imageUrl,
    MuscleGroup primaryMuscle,
    List<MuscleGroup> secondaryMuscles,
    ExerciseType type,
    List<String> equipment,
    DifficultyLevel difficulty,
    List<String> instructions,
    List<String>? contraindications,
  });
}

/// @nodoc
class __$$ExerciseImplCopyWithImpl<$Res>
    extends _$ExerciseCopyWithImpl<$Res, _$ExerciseImpl>
    implements _$$ExerciseImplCopyWith<$Res> {
  __$$ExerciseImplCopyWithImpl(
    _$ExerciseImpl _value,
    $Res Function(_$ExerciseImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? videoUrl = freezed,
    Object? imageUrl = freezed,
    Object? primaryMuscle = null,
    Object? secondaryMuscles = null,
    Object? type = null,
    Object? equipment = null,
    Object? difficulty = null,
    Object? instructions = null,
    Object? contraindications = freezed,
  }) {
    return _then(
      _$ExerciseImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        videoUrl: freezed == videoUrl
            ? _value.videoUrl
            : videoUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        imageUrl: freezed == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        primaryMuscle: null == primaryMuscle
            ? _value.primaryMuscle
            : primaryMuscle // ignore: cast_nullable_to_non_nullable
                  as MuscleGroup,
        secondaryMuscles: null == secondaryMuscles
            ? _value._secondaryMuscles
            : secondaryMuscles // ignore: cast_nullable_to_non_nullable
                  as List<MuscleGroup>,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as ExerciseType,
        equipment: null == equipment
            ? _value._equipment
            : equipment // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        difficulty: null == difficulty
            ? _value.difficulty
            : difficulty // ignore: cast_nullable_to_non_nullable
                  as DifficultyLevel,
        instructions: null == instructions
            ? _value._instructions
            : instructions // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        contraindications: freezed == contraindications
            ? _value._contraindications
            : contraindications // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ExerciseImpl implements _Exercise {
  const _$ExerciseImpl({
    required this.id,
    required this.name,
    this.description,
    this.videoUrl,
    this.imageUrl,
    required this.primaryMuscle,
    final List<MuscleGroup> secondaryMuscles = const [],
    required this.type,
    final List<String> equipment = const [],
    required this.difficulty,
    required final List<String> instructions,
    final List<String>? contraindications,
  }) : _secondaryMuscles = secondaryMuscles,
       _equipment = equipment,
       _instructions = instructions,
       _contraindications = contraindications;

  factory _$ExerciseImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExerciseImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? description;
  @override
  final String? videoUrl;
  @override
  final String? imageUrl;
  @override
  final MuscleGroup primaryMuscle;
  final List<MuscleGroup> _secondaryMuscles;
  @override
  @JsonKey()
  List<MuscleGroup> get secondaryMuscles {
    if (_secondaryMuscles is EqualUnmodifiableListView)
      return _secondaryMuscles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_secondaryMuscles);
  }

  @override
  final ExerciseType type;
  final List<String> _equipment;
  @override
  @JsonKey()
  List<String> get equipment {
    if (_equipment is EqualUnmodifiableListView) return _equipment;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_equipment);
  }

  @override
  final DifficultyLevel difficulty;
  final List<String> _instructions;
  @override
  List<String> get instructions {
    if (_instructions is EqualUnmodifiableListView) return _instructions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_instructions);
  }

  final List<String>? _contraindications;
  @override
  List<String>? get contraindications {
    final value = _contraindications;
    if (value == null) return null;
    if (_contraindications is EqualUnmodifiableListView)
      return _contraindications;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'Exercise(id: $id, name: $name, description: $description, videoUrl: $videoUrl, imageUrl: $imageUrl, primaryMuscle: $primaryMuscle, secondaryMuscles: $secondaryMuscles, type: $type, equipment: $equipment, difficulty: $difficulty, instructions: $instructions, contraindications: $contraindications)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExerciseImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.videoUrl, videoUrl) ||
                other.videoUrl == videoUrl) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.primaryMuscle, primaryMuscle) ||
                other.primaryMuscle == primaryMuscle) &&
            const DeepCollectionEquality().equals(
              other._secondaryMuscles,
              _secondaryMuscles,
            ) &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality().equals(
              other._equipment,
              _equipment,
            ) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty) &&
            const DeepCollectionEquality().equals(
              other._instructions,
              _instructions,
            ) &&
            const DeepCollectionEquality().equals(
              other._contraindications,
              _contraindications,
            ));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    description,
    videoUrl,
    imageUrl,
    primaryMuscle,
    const DeepCollectionEquality().hash(_secondaryMuscles),
    type,
    const DeepCollectionEquality().hash(_equipment),
    difficulty,
    const DeepCollectionEquality().hash(_instructions),
    const DeepCollectionEquality().hash(_contraindications),
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ExerciseImplCopyWith<_$ExerciseImpl> get copyWith =>
      __$$ExerciseImplCopyWithImpl<_$ExerciseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExerciseImplToJson(this);
  }
}

abstract class _Exercise implements Exercise {
  const factory _Exercise({
    required final String id,
    required final String name,
    final String? description,
    final String? videoUrl,
    final String? imageUrl,
    required final MuscleGroup primaryMuscle,
    final List<MuscleGroup> secondaryMuscles,
    required final ExerciseType type,
    final List<String> equipment,
    required final DifficultyLevel difficulty,
    required final List<String> instructions,
    final List<String>? contraindications,
  }) = _$ExerciseImpl;

  factory _Exercise.fromJson(Map<String, dynamic> json) =
      _$ExerciseImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get description;
  @override
  String? get videoUrl;
  @override
  String? get imageUrl;
  @override
  MuscleGroup get primaryMuscle;
  @override
  List<MuscleGroup> get secondaryMuscles;
  @override
  ExerciseType get type;
  @override
  List<String> get equipment;
  @override
  DifficultyLevel get difficulty;
  @override
  List<String> get instructions;
  @override
  List<String>? get contraindications;
  @override
  @JsonKey(ignore: true)
  _$$ExerciseImplCopyWith<_$ExerciseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

WorkoutLog _$WorkoutLogFromJson(Map<String, dynamic> json) {
  return _WorkoutLog.fromJson(json);
}

/// @nodoc
mixin _$WorkoutLog {
  String get id => throw _privateConstructorUsedError;
  String get sessionId => throw _privateConstructorUsedError;
  DateTime get startTime => throw _privateConstructorUsedError;
  DateTime? get endTime => throw _privateConstructorUsedError;
  List<ExerciseLog> get exerciseLogs => throw _privateConstructorUsedError;
  double? get caloriesBurned => throw _privateConstructorUsedError;
  int? get heartRateAvg => throw _privateConstructorUsedError;
  int? get heartRateMax => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  int? get mood => throw _privateConstructorUsedError;
  int? get perceivedEffort => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WorkoutLogCopyWith<WorkoutLog> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkoutLogCopyWith<$Res> {
  factory $WorkoutLogCopyWith(
    WorkoutLog value,
    $Res Function(WorkoutLog) then,
  ) = _$WorkoutLogCopyWithImpl<$Res, WorkoutLog>;
  @useResult
  $Res call({
    String id,
    String sessionId,
    DateTime startTime,
    DateTime? endTime,
    List<ExerciseLog> exerciseLogs,
    double? caloriesBurned,
    int? heartRateAvg,
    int? heartRateMax,
    String? notes,
    int? mood,
    int? perceivedEffort,
  });
}

/// @nodoc
class _$WorkoutLogCopyWithImpl<$Res, $Val extends WorkoutLog>
    implements $WorkoutLogCopyWith<$Res> {
  _$WorkoutLogCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sessionId = null,
    Object? startTime = null,
    Object? endTime = freezed,
    Object? exerciseLogs = null,
    Object? caloriesBurned = freezed,
    Object? heartRateAvg = freezed,
    Object? heartRateMax = freezed,
    Object? notes = freezed,
    Object? mood = freezed,
    Object? perceivedEffort = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            sessionId: null == sessionId
                ? _value.sessionId
                : sessionId // ignore: cast_nullable_to_non_nullable
                      as String,
            startTime: null == startTime
                ? _value.startTime
                : startTime // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            endTime: freezed == endTime
                ? _value.endTime
                : endTime // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            exerciseLogs: null == exerciseLogs
                ? _value.exerciseLogs
                : exerciseLogs // ignore: cast_nullable_to_non_nullable
                      as List<ExerciseLog>,
            caloriesBurned: freezed == caloriesBurned
                ? _value.caloriesBurned
                : caloriesBurned // ignore: cast_nullable_to_non_nullable
                      as double?,
            heartRateAvg: freezed == heartRateAvg
                ? _value.heartRateAvg
                : heartRateAvg // ignore: cast_nullable_to_non_nullable
                      as int?,
            heartRateMax: freezed == heartRateMax
                ? _value.heartRateMax
                : heartRateMax // ignore: cast_nullable_to_non_nullable
                      as int?,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            mood: freezed == mood
                ? _value.mood
                : mood // ignore: cast_nullable_to_non_nullable
                      as int?,
            perceivedEffort: freezed == perceivedEffort
                ? _value.perceivedEffort
                : perceivedEffort // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$WorkoutLogImplCopyWith<$Res>
    implements $WorkoutLogCopyWith<$Res> {
  factory _$$WorkoutLogImplCopyWith(
    _$WorkoutLogImpl value,
    $Res Function(_$WorkoutLogImpl) then,
  ) = __$$WorkoutLogImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String sessionId,
    DateTime startTime,
    DateTime? endTime,
    List<ExerciseLog> exerciseLogs,
    double? caloriesBurned,
    int? heartRateAvg,
    int? heartRateMax,
    String? notes,
    int? mood,
    int? perceivedEffort,
  });
}

/// @nodoc
class __$$WorkoutLogImplCopyWithImpl<$Res>
    extends _$WorkoutLogCopyWithImpl<$Res, _$WorkoutLogImpl>
    implements _$$WorkoutLogImplCopyWith<$Res> {
  __$$WorkoutLogImplCopyWithImpl(
    _$WorkoutLogImpl _value,
    $Res Function(_$WorkoutLogImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sessionId = null,
    Object? startTime = null,
    Object? endTime = freezed,
    Object? exerciseLogs = null,
    Object? caloriesBurned = freezed,
    Object? heartRateAvg = freezed,
    Object? heartRateMax = freezed,
    Object? notes = freezed,
    Object? mood = freezed,
    Object? perceivedEffort = freezed,
  }) {
    return _then(
      _$WorkoutLogImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        sessionId: null == sessionId
            ? _value.sessionId
            : sessionId // ignore: cast_nullable_to_non_nullable
                  as String,
        startTime: null == startTime
            ? _value.startTime
            : startTime // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        endTime: freezed == endTime
            ? _value.endTime
            : endTime // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        exerciseLogs: null == exerciseLogs
            ? _value._exerciseLogs
            : exerciseLogs // ignore: cast_nullable_to_non_nullable
                  as List<ExerciseLog>,
        caloriesBurned: freezed == caloriesBurned
            ? _value.caloriesBurned
            : caloriesBurned // ignore: cast_nullable_to_non_nullable
                  as double?,
        heartRateAvg: freezed == heartRateAvg
            ? _value.heartRateAvg
            : heartRateAvg // ignore: cast_nullable_to_non_nullable
                  as int?,
        heartRateMax: freezed == heartRateMax
            ? _value.heartRateMax
            : heartRateMax // ignore: cast_nullable_to_non_nullable
                  as int?,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        mood: freezed == mood
            ? _value.mood
            : mood // ignore: cast_nullable_to_non_nullable
                  as int?,
        perceivedEffort: freezed == perceivedEffort
            ? _value.perceivedEffort
            : perceivedEffort // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkoutLogImpl extends _WorkoutLog {
  const _$WorkoutLogImpl({
    required this.id,
    required this.sessionId,
    required this.startTime,
    this.endTime,
    required final List<ExerciseLog> exerciseLogs,
    this.caloriesBurned,
    this.heartRateAvg,
    this.heartRateMax,
    this.notes,
    this.mood,
    this.perceivedEffort,
  }) : _exerciseLogs = exerciseLogs,
       super._();

  factory _$WorkoutLogImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkoutLogImplFromJson(json);

  @override
  final String id;
  @override
  final String sessionId;
  @override
  final DateTime startTime;
  @override
  final DateTime? endTime;
  final List<ExerciseLog> _exerciseLogs;
  @override
  List<ExerciseLog> get exerciseLogs {
    if (_exerciseLogs is EqualUnmodifiableListView) return _exerciseLogs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_exerciseLogs);
  }

  @override
  final double? caloriesBurned;
  @override
  final int? heartRateAvg;
  @override
  final int? heartRateMax;
  @override
  final String? notes;
  @override
  final int? mood;
  @override
  final int? perceivedEffort;

  @override
  String toString() {
    return 'WorkoutLog(id: $id, sessionId: $sessionId, startTime: $startTime, endTime: $endTime, exerciseLogs: $exerciseLogs, caloriesBurned: $caloriesBurned, heartRateAvg: $heartRateAvg, heartRateMax: $heartRateMax, notes: $notes, mood: $mood, perceivedEffort: $perceivedEffort)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkoutLogImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            const DeepCollectionEquality().equals(
              other._exerciseLogs,
              _exerciseLogs,
            ) &&
            (identical(other.caloriesBurned, caloriesBurned) ||
                other.caloriesBurned == caloriesBurned) &&
            (identical(other.heartRateAvg, heartRateAvg) ||
                other.heartRateAvg == heartRateAvg) &&
            (identical(other.heartRateMax, heartRateMax) ||
                other.heartRateMax == heartRateMax) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.mood, mood) || other.mood == mood) &&
            (identical(other.perceivedEffort, perceivedEffort) ||
                other.perceivedEffort == perceivedEffort));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    sessionId,
    startTime,
    endTime,
    const DeepCollectionEquality().hash(_exerciseLogs),
    caloriesBurned,
    heartRateAvg,
    heartRateMax,
    notes,
    mood,
    perceivedEffort,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkoutLogImplCopyWith<_$WorkoutLogImpl> get copyWith =>
      __$$WorkoutLogImplCopyWithImpl<_$WorkoutLogImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkoutLogImplToJson(this);
  }
}

abstract class _WorkoutLog extends WorkoutLog {
  const factory _WorkoutLog({
    required final String id,
    required final String sessionId,
    required final DateTime startTime,
    final DateTime? endTime,
    required final List<ExerciseLog> exerciseLogs,
    final double? caloriesBurned,
    final int? heartRateAvg,
    final int? heartRateMax,
    final String? notes,
    final int? mood,
    final int? perceivedEffort,
  }) = _$WorkoutLogImpl;
  const _WorkoutLog._() : super._();

  factory _WorkoutLog.fromJson(Map<String, dynamic> json) =
      _$WorkoutLogImpl.fromJson;

  @override
  String get id;
  @override
  String get sessionId;
  @override
  DateTime get startTime;
  @override
  DateTime? get endTime;
  @override
  List<ExerciseLog> get exerciseLogs;
  @override
  double? get caloriesBurned;
  @override
  int? get heartRateAvg;
  @override
  int? get heartRateMax;
  @override
  String? get notes;
  @override
  int? get mood;
  @override
  int? get perceivedEffort;
  @override
  @JsonKey(ignore: true)
  _$$WorkoutLogImplCopyWith<_$WorkoutLogImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ExerciseLog _$ExerciseLogFromJson(Map<String, dynamic> json) {
  return _ExerciseLog.fromJson(json);
}

/// @nodoc
mixin _$ExerciseLog {
  String get exerciseId => throw _privateConstructorUsedError;
  List<SetLog> get sets => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ExerciseLogCopyWith<ExerciseLog> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExerciseLogCopyWith<$Res> {
  factory $ExerciseLogCopyWith(
    ExerciseLog value,
    $Res Function(ExerciseLog) then,
  ) = _$ExerciseLogCopyWithImpl<$Res, ExerciseLog>;
  @useResult
  $Res call({String exerciseId, List<SetLog> sets});
}

/// @nodoc
class _$ExerciseLogCopyWithImpl<$Res, $Val extends ExerciseLog>
    implements $ExerciseLogCopyWith<$Res> {
  _$ExerciseLogCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? exerciseId = null, Object? sets = null}) {
    return _then(
      _value.copyWith(
            exerciseId: null == exerciseId
                ? _value.exerciseId
                : exerciseId // ignore: cast_nullable_to_non_nullable
                      as String,
            sets: null == sets
                ? _value.sets
                : sets // ignore: cast_nullable_to_non_nullable
                      as List<SetLog>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ExerciseLogImplCopyWith<$Res>
    implements $ExerciseLogCopyWith<$Res> {
  factory _$$ExerciseLogImplCopyWith(
    _$ExerciseLogImpl value,
    $Res Function(_$ExerciseLogImpl) then,
  ) = __$$ExerciseLogImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String exerciseId, List<SetLog> sets});
}

/// @nodoc
class __$$ExerciseLogImplCopyWithImpl<$Res>
    extends _$ExerciseLogCopyWithImpl<$Res, _$ExerciseLogImpl>
    implements _$$ExerciseLogImplCopyWith<$Res> {
  __$$ExerciseLogImplCopyWithImpl(
    _$ExerciseLogImpl _value,
    $Res Function(_$ExerciseLogImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? exerciseId = null, Object? sets = null}) {
    return _then(
      _$ExerciseLogImpl(
        exerciseId: null == exerciseId
            ? _value.exerciseId
            : exerciseId // ignore: cast_nullable_to_non_nullable
                  as String,
        sets: null == sets
            ? _value._sets
            : sets // ignore: cast_nullable_to_non_nullable
                  as List<SetLog>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ExerciseLogImpl implements _ExerciseLog {
  const _$ExerciseLogImpl({
    required this.exerciseId,
    required final List<SetLog> sets,
  }) : _sets = sets;

  factory _$ExerciseLogImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExerciseLogImplFromJson(json);

  @override
  final String exerciseId;
  final List<SetLog> _sets;
  @override
  List<SetLog> get sets {
    if (_sets is EqualUnmodifiableListView) return _sets;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sets);
  }

  @override
  String toString() {
    return 'ExerciseLog(exerciseId: $exerciseId, sets: $sets)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExerciseLogImpl &&
            (identical(other.exerciseId, exerciseId) ||
                other.exerciseId == exerciseId) &&
            const DeepCollectionEquality().equals(other._sets, _sets));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    exerciseId,
    const DeepCollectionEquality().hash(_sets),
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ExerciseLogImplCopyWith<_$ExerciseLogImpl> get copyWith =>
      __$$ExerciseLogImplCopyWithImpl<_$ExerciseLogImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExerciseLogImplToJson(this);
  }
}

abstract class _ExerciseLog implements ExerciseLog {
  const factory _ExerciseLog({
    required final String exerciseId,
    required final List<SetLog> sets,
  }) = _$ExerciseLogImpl;

  factory _ExerciseLog.fromJson(Map<String, dynamic> json) =
      _$ExerciseLogImpl.fromJson;

  @override
  String get exerciseId;
  @override
  List<SetLog> get sets;
  @override
  @JsonKey(ignore: true)
  _$$ExerciseLogImplCopyWith<_$ExerciseLogImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SetLog _$SetLogFromJson(Map<String, dynamic> json) {
  return _SetLog.fromJson(json);
}

/// @nodoc
mixin _$SetLog {
  int get setNumber => throw _privateConstructorUsedError;
  int get reps => throw _privateConstructorUsedError;
  double? get weightKg => throw _privateConstructorUsedError;
  int? get durationSeconds => throw _privateConstructorUsedError;
  bool get completed => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SetLogCopyWith<SetLog> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SetLogCopyWith<$Res> {
  factory $SetLogCopyWith(SetLog value, $Res Function(SetLog) then) =
      _$SetLogCopyWithImpl<$Res, SetLog>;
  @useResult
  $Res call({
    int setNumber,
    int reps,
    double? weightKg,
    int? durationSeconds,
    bool completed,
  });
}

/// @nodoc
class _$SetLogCopyWithImpl<$Res, $Val extends SetLog>
    implements $SetLogCopyWith<$Res> {
  _$SetLogCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? setNumber = null,
    Object? reps = null,
    Object? weightKg = freezed,
    Object? durationSeconds = freezed,
    Object? completed = null,
  }) {
    return _then(
      _value.copyWith(
            setNumber: null == setNumber
                ? _value.setNumber
                : setNumber // ignore: cast_nullable_to_non_nullable
                      as int,
            reps: null == reps
                ? _value.reps
                : reps // ignore: cast_nullable_to_non_nullable
                      as int,
            weightKg: freezed == weightKg
                ? _value.weightKg
                : weightKg // ignore: cast_nullable_to_non_nullable
                      as double?,
            durationSeconds: freezed == durationSeconds
                ? _value.durationSeconds
                : durationSeconds // ignore: cast_nullable_to_non_nullable
                      as int?,
            completed: null == completed
                ? _value.completed
                : completed // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SetLogImplCopyWith<$Res> implements $SetLogCopyWith<$Res> {
  factory _$$SetLogImplCopyWith(
    _$SetLogImpl value,
    $Res Function(_$SetLogImpl) then,
  ) = __$$SetLogImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int setNumber,
    int reps,
    double? weightKg,
    int? durationSeconds,
    bool completed,
  });
}

/// @nodoc
class __$$SetLogImplCopyWithImpl<$Res>
    extends _$SetLogCopyWithImpl<$Res, _$SetLogImpl>
    implements _$$SetLogImplCopyWith<$Res> {
  __$$SetLogImplCopyWithImpl(
    _$SetLogImpl _value,
    $Res Function(_$SetLogImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? setNumber = null,
    Object? reps = null,
    Object? weightKg = freezed,
    Object? durationSeconds = freezed,
    Object? completed = null,
  }) {
    return _then(
      _$SetLogImpl(
        setNumber: null == setNumber
            ? _value.setNumber
            : setNumber // ignore: cast_nullable_to_non_nullable
                  as int,
        reps: null == reps
            ? _value.reps
            : reps // ignore: cast_nullable_to_non_nullable
                  as int,
        weightKg: freezed == weightKg
            ? _value.weightKg
            : weightKg // ignore: cast_nullable_to_non_nullable
                  as double?,
        durationSeconds: freezed == durationSeconds
            ? _value.durationSeconds
            : durationSeconds // ignore: cast_nullable_to_non_nullable
                  as int?,
        completed: null == completed
            ? _value.completed
            : completed // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SetLogImpl implements _SetLog {
  const _$SetLogImpl({
    required this.setNumber,
    required this.reps,
    this.weightKg,
    this.durationSeconds,
    this.completed = true,
  });

  factory _$SetLogImpl.fromJson(Map<String, dynamic> json) =>
      _$$SetLogImplFromJson(json);

  @override
  final int setNumber;
  @override
  final int reps;
  @override
  final double? weightKg;
  @override
  final int? durationSeconds;
  @override
  @JsonKey()
  final bool completed;

  @override
  String toString() {
    return 'SetLog(setNumber: $setNumber, reps: $reps, weightKg: $weightKg, durationSeconds: $durationSeconds, completed: $completed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SetLogImpl &&
            (identical(other.setNumber, setNumber) ||
                other.setNumber == setNumber) &&
            (identical(other.reps, reps) || other.reps == reps) &&
            (identical(other.weightKg, weightKg) ||
                other.weightKg == weightKg) &&
            (identical(other.durationSeconds, durationSeconds) ||
                other.durationSeconds == durationSeconds) &&
            (identical(other.completed, completed) ||
                other.completed == completed));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    setNumber,
    reps,
    weightKg,
    durationSeconds,
    completed,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SetLogImplCopyWith<_$SetLogImpl> get copyWith =>
      __$$SetLogImplCopyWithImpl<_$SetLogImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SetLogImplToJson(this);
  }
}

abstract class _SetLog implements SetLog {
  const factory _SetLog({
    required final int setNumber,
    required final int reps,
    final double? weightKg,
    final int? durationSeconds,
    final bool completed,
  }) = _$SetLogImpl;

  factory _SetLog.fromJson(Map<String, dynamic> json) = _$SetLogImpl.fromJson;

  @override
  int get setNumber;
  @override
  int get reps;
  @override
  double? get weightKg;
  @override
  int? get durationSeconds;
  @override
  bool get completed;
  @override
  @JsonKey(ignore: true)
  _$$SetLogImplCopyWith<_$SetLogImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
