// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_entities.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

UserEntity _$UserEntityFromJson(Map<String, dynamic> json) {
  return _UserEntity.fromJson(json);
}

/// @nodoc
mixin _$UserEntity {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;
  UserProfile? get profile => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserEntityCopyWith<UserEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserEntityCopyWith<$Res> {
  factory $UserEntityCopyWith(
    UserEntity value,
    $Res Function(UserEntity) then,
  ) = _$UserEntityCopyWithImpl<$Res, UserEntity>;
  @useResult
  $Res call({
    String id,
    String name,
    String email,
    String? avatarUrl,
    UserProfile? profile,
    DateTime createdAt,
  });

  $UserProfileCopyWith<$Res>? get profile;
}

/// @nodoc
class _$UserEntityCopyWithImpl<$Res, $Val extends UserEntity>
    implements $UserEntityCopyWith<$Res> {
  _$UserEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? email = null,
    Object? avatarUrl = freezed,
    Object? profile = freezed,
    Object? createdAt = null,
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
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
            avatarUrl: freezed == avatarUrl
                ? _value.avatarUrl
                : avatarUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            profile: freezed == profile
                ? _value.profile
                : profile // ignore: cast_nullable_to_non_nullable
                      as UserProfile?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }

  @override
  @pragma('vm:prefer-inline')
  $UserProfileCopyWith<$Res>? get profile {
    if (_value.profile == null) {
      return null;
    }

    return $UserProfileCopyWith<$Res>(_value.profile!, (value) {
      return _then(_value.copyWith(profile: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$UserEntityImplCopyWith<$Res>
    implements $UserEntityCopyWith<$Res> {
  factory _$$UserEntityImplCopyWith(
    _$UserEntityImpl value,
    $Res Function(_$UserEntityImpl) then,
  ) = __$$UserEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String email,
    String? avatarUrl,
    UserProfile? profile,
    DateTime createdAt,
  });

  @override
  $UserProfileCopyWith<$Res>? get profile;
}

/// @nodoc
class __$$UserEntityImplCopyWithImpl<$Res>
    extends _$UserEntityCopyWithImpl<$Res, _$UserEntityImpl>
    implements _$$UserEntityImplCopyWith<$Res> {
  __$$UserEntityImplCopyWithImpl(
    _$UserEntityImpl _value,
    $Res Function(_$UserEntityImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? email = null,
    Object? avatarUrl = freezed,
    Object? profile = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _$UserEntityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        avatarUrl: freezed == avatarUrl
            ? _value.avatarUrl
            : avatarUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        profile: freezed == profile
            ? _value.profile
            : profile // ignore: cast_nullable_to_non_nullable
                  as UserProfile?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserEntityImpl implements _UserEntity {
  const _$UserEntityImpl({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.profile,
    required this.createdAt,
  });

  factory _$UserEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserEntityImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String email;
  @override
  final String? avatarUrl;
  @override
  final UserProfile? profile;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'UserEntity(id: $id, name: $name, email: $email, avatarUrl: $avatarUrl, profile: $profile, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.profile, profile) || other.profile == profile) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, email, avatarUrl, profile, createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserEntityImplCopyWith<_$UserEntityImpl> get copyWith =>
      __$$UserEntityImplCopyWithImpl<_$UserEntityImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserEntityImplToJson(this);
  }
}

abstract class _UserEntity implements UserEntity {
  const factory _UserEntity({
    required final String id,
    required final String name,
    required final String email,
    final String? avatarUrl,
    final UserProfile? profile,
    required final DateTime createdAt,
  }) = _$UserEntityImpl;

  factory _UserEntity.fromJson(Map<String, dynamic> json) =
      _$UserEntityImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get email;
  @override
  String? get avatarUrl;
  @override
  UserProfile? get profile;
  @override
  DateTime get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$UserEntityImplCopyWith<_$UserEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) {
  return _UserProfile.fromJson(json);
}

/// @nodoc
mixin _$UserProfile {
  double get weight => throw _privateConstructorUsedError;
  double get height => throw _privateConstructorUsedError;
  int get age => throw _privateConstructorUsedError;
  DateTime? get dateOfBirth => throw _privateConstructorUsedError;
  Gender get gender => throw _privateConstructorUsedError;
  FitnessGoal get goal => throw _privateConstructorUsedError;
  IntensityLevel get intensity => throw _privateConstructorUsedError;
  List<String> get medicalRestrictions => throw _privateConstructorUsedError;
  List<String> get exerciseRestrictions => throw _privateConstructorUsedError;
  ActivityLevel get activityLevel => throw _privateConstructorUsedError;
  double? get targetWeight => throw _privateConstructorUsedError;
  DateTime? get targetDate => throw _privateConstructorUsedError;
  bool get testWeekCompleted => throw _privateConstructorUsedError;
  List<TestExerciseResult> get testResults =>
      throw _privateConstructorUsedError;
  String? get workoutLocation => throw _privateConstructorUsedError;
  String? get runningPreference => throw _privateConstructorUsedError;
  String? get city => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserProfileCopyWith<UserProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserProfileCopyWith<$Res> {
  factory $UserProfileCopyWith(
    UserProfile value,
    $Res Function(UserProfile) then,
  ) = _$UserProfileCopyWithImpl<$Res, UserProfile>;
  @useResult
  $Res call({
    double weight,
    double height,
    int age,
    DateTime? dateOfBirth,
    Gender gender,
    FitnessGoal goal,
    IntensityLevel intensity,
    List<String> medicalRestrictions,
    List<String> exerciseRestrictions,
    ActivityLevel activityLevel,
    double? targetWeight,
    DateTime? targetDate,
    bool testWeekCompleted,
    List<TestExerciseResult> testResults,
    String? workoutLocation,
    String? runningPreference,
    String? city,
  });
}

/// @nodoc
class _$UserProfileCopyWithImpl<$Res, $Val extends UserProfile>
    implements $UserProfileCopyWith<$Res> {
  _$UserProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? weight = null,
    Object? height = null,
    Object? age = null,
    Object? dateOfBirth = freezed,
    Object? gender = null,
    Object? goal = null,
    Object? intensity = null,
    Object? medicalRestrictions = null,
    Object? exerciseRestrictions = null,
    Object? activityLevel = null,
    Object? targetWeight = freezed,
    Object? targetDate = freezed,
    Object? testWeekCompleted = null,
    Object? testResults = null,
    Object? workoutLocation = freezed,
    Object? runningPreference = freezed,
    Object? city = freezed,
  }) {
    return _then(
      _value.copyWith(
            weight: null == weight
                ? _value.weight
                : weight // ignore: cast_nullable_to_non_nullable
                      as double,
            height: null == height
                ? _value.height
                : height // ignore: cast_nullable_to_non_nullable
                      as double,
            age: null == age
                ? _value.age
                : age // ignore: cast_nullable_to_non_nullable
                      as int,
            dateOfBirth: freezed == dateOfBirth
                ? _value.dateOfBirth
                : dateOfBirth // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            gender: null == gender
                ? _value.gender
                : gender // ignore: cast_nullable_to_non_nullable
                      as Gender,
            goal: null == goal
                ? _value.goal
                : goal // ignore: cast_nullable_to_non_nullable
                      as FitnessGoal,
            intensity: null == intensity
                ? _value.intensity
                : intensity // ignore: cast_nullable_to_non_nullable
                      as IntensityLevel,
            medicalRestrictions: null == medicalRestrictions
                ? _value.medicalRestrictions
                : medicalRestrictions // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            exerciseRestrictions: null == exerciseRestrictions
                ? _value.exerciseRestrictions
                : exerciseRestrictions // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            activityLevel: null == activityLevel
                ? _value.activityLevel
                : activityLevel // ignore: cast_nullable_to_non_nullable
                      as ActivityLevel,
            targetWeight: freezed == targetWeight
                ? _value.targetWeight
                : targetWeight // ignore: cast_nullable_to_non_nullable
                      as double?,
            targetDate: freezed == targetDate
                ? _value.targetDate
                : targetDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            testWeekCompleted: null == testWeekCompleted
                ? _value.testWeekCompleted
                : testWeekCompleted // ignore: cast_nullable_to_non_nullable
                      as bool,
            testResults: null == testResults
                ? _value.testResults
                : testResults // ignore: cast_nullable_to_non_nullable
                      as List<TestExerciseResult>,
            workoutLocation: freezed == workoutLocation
                ? _value.workoutLocation
                : workoutLocation // ignore: cast_nullable_to_non_nullable
                      as String?,
            runningPreference: freezed == runningPreference
                ? _value.runningPreference
                : runningPreference // ignore: cast_nullable_to_non_nullable
                      as String?,
            city: freezed == city
                ? _value.city
                : city // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserProfileImplCopyWith<$Res>
    implements $UserProfileCopyWith<$Res> {
  factory _$$UserProfileImplCopyWith(
    _$UserProfileImpl value,
    $Res Function(_$UserProfileImpl) then,
  ) = __$$UserProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    double weight,
    double height,
    int age,
    DateTime? dateOfBirth,
    Gender gender,
    FitnessGoal goal,
    IntensityLevel intensity,
    List<String> medicalRestrictions,
    List<String> exerciseRestrictions,
    ActivityLevel activityLevel,
    double? targetWeight,
    DateTime? targetDate,
    bool testWeekCompleted,
    List<TestExerciseResult> testResults,
    String? workoutLocation,
    String? runningPreference,
    String? city,
  });
}

/// @nodoc
class __$$UserProfileImplCopyWithImpl<$Res>
    extends _$UserProfileCopyWithImpl<$Res, _$UserProfileImpl>
    implements _$$UserProfileImplCopyWith<$Res> {
  __$$UserProfileImplCopyWithImpl(
    _$UserProfileImpl _value,
    $Res Function(_$UserProfileImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? weight = null,
    Object? height = null,
    Object? age = null,
    Object? dateOfBirth = freezed,
    Object? gender = null,
    Object? goal = null,
    Object? intensity = null,
    Object? medicalRestrictions = null,
    Object? exerciseRestrictions = null,
    Object? activityLevel = null,
    Object? targetWeight = freezed,
    Object? targetDate = freezed,
    Object? testWeekCompleted = null,
    Object? testResults = null,
    Object? workoutLocation = freezed,
    Object? runningPreference = freezed,
    Object? city = freezed,
  }) {
    return _then(
      _$UserProfileImpl(
        weight: null == weight
            ? _value.weight
            : weight // ignore: cast_nullable_to_non_nullable
                  as double,
        height: null == height
            ? _value.height
            : height // ignore: cast_nullable_to_non_nullable
                  as double,
        age: null == age
            ? _value.age
            : age // ignore: cast_nullable_to_non_nullable
                  as int,
        dateOfBirth: freezed == dateOfBirth
            ? _value.dateOfBirth
            : dateOfBirth // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        gender: null == gender
            ? _value.gender
            : gender // ignore: cast_nullable_to_non_nullable
                  as Gender,
        goal: null == goal
            ? _value.goal
            : goal // ignore: cast_nullable_to_non_nullable
                  as FitnessGoal,
        intensity: null == intensity
            ? _value.intensity
            : intensity // ignore: cast_nullable_to_non_nullable
                  as IntensityLevel,
        medicalRestrictions: null == medicalRestrictions
            ? _value._medicalRestrictions
            : medicalRestrictions // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        exerciseRestrictions: null == exerciseRestrictions
            ? _value._exerciseRestrictions
            : exerciseRestrictions // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        activityLevel: null == activityLevel
            ? _value.activityLevel
            : activityLevel // ignore: cast_nullable_to_non_nullable
                  as ActivityLevel,
        targetWeight: freezed == targetWeight
            ? _value.targetWeight
            : targetWeight // ignore: cast_nullable_to_non_nullable
                  as double?,
        targetDate: freezed == targetDate
            ? _value.targetDate
            : targetDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        testWeekCompleted: null == testWeekCompleted
            ? _value.testWeekCompleted
            : testWeekCompleted // ignore: cast_nullable_to_non_nullable
                  as bool,
        testResults: null == testResults
            ? _value._testResults
            : testResults // ignore: cast_nullable_to_non_nullable
                  as List<TestExerciseResult>,
        workoutLocation: freezed == workoutLocation
            ? _value.workoutLocation
            : workoutLocation // ignore: cast_nullable_to_non_nullable
                  as String?,
        runningPreference: freezed == runningPreference
            ? _value.runningPreference
            : runningPreference // ignore: cast_nullable_to_non_nullable
                  as String?,
        city: freezed == city
            ? _value.city
            : city // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserProfileImpl extends _UserProfile {
  const _$UserProfileImpl({
    required this.weight,
    required this.height,
    required this.age,
    this.dateOfBirth,
    required this.gender,
    required this.goal,
    required this.intensity,
    final List<String> medicalRestrictions = const [],
    final List<String> exerciseRestrictions = const [],
    required this.activityLevel,
    this.targetWeight,
    this.targetDate,
    this.testWeekCompleted = false,
    final List<TestExerciseResult> testResults = const [],
    this.workoutLocation,
    this.runningPreference,
    this.city,
  }) : _medicalRestrictions = medicalRestrictions,
       _exerciseRestrictions = exerciseRestrictions,
       _testResults = testResults,
       super._();

  factory _$UserProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserProfileImplFromJson(json);

  @override
  final double weight;
  @override
  final double height;
  @override
  final int age;
  @override
  final DateTime? dateOfBirth;
  @override
  final Gender gender;
  @override
  final FitnessGoal goal;
  @override
  final IntensityLevel intensity;
  final List<String> _medicalRestrictions;
  @override
  @JsonKey()
  List<String> get medicalRestrictions {
    if (_medicalRestrictions is EqualUnmodifiableListView)
      return _medicalRestrictions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_medicalRestrictions);
  }

  final List<String> _exerciseRestrictions;
  @override
  @JsonKey()
  List<String> get exerciseRestrictions {
    if (_exerciseRestrictions is EqualUnmodifiableListView)
      return _exerciseRestrictions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_exerciseRestrictions);
  }

  @override
  final ActivityLevel activityLevel;
  @override
  final double? targetWeight;
  @override
  final DateTime? targetDate;
  @override
  @JsonKey()
  final bool testWeekCompleted;
  final List<TestExerciseResult> _testResults;
  @override
  @JsonKey()
  List<TestExerciseResult> get testResults {
    if (_testResults is EqualUnmodifiableListView) return _testResults;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_testResults);
  }

  @override
  final String? workoutLocation;
  @override
  final String? runningPreference;
  @override
  final String? city;

  @override
  String toString() {
    return 'UserProfile(weight: $weight, height: $height, age: $age, dateOfBirth: $dateOfBirth, gender: $gender, goal: $goal, intensity: $intensity, medicalRestrictions: $medicalRestrictions, exerciseRestrictions: $exerciseRestrictions, activityLevel: $activityLevel, targetWeight: $targetWeight, targetDate: $targetDate, testWeekCompleted: $testWeekCompleted, testResults: $testResults, workoutLocation: $workoutLocation, runningPreference: $runningPreference, city: $city)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserProfileImpl &&
            (identical(other.weight, weight) || other.weight == weight) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.age, age) || other.age == age) &&
            (identical(other.dateOfBirth, dateOfBirth) ||
                other.dateOfBirth == dateOfBirth) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.goal, goal) || other.goal == goal) &&
            (identical(other.intensity, intensity) ||
                other.intensity == intensity) &&
            const DeepCollectionEquality().equals(
              other._medicalRestrictions,
              _medicalRestrictions,
            ) &&
            const DeepCollectionEquality().equals(
              other._exerciseRestrictions,
              _exerciseRestrictions,
            ) &&
            (identical(other.activityLevel, activityLevel) ||
                other.activityLevel == activityLevel) &&
            (identical(other.targetWeight, targetWeight) ||
                other.targetWeight == targetWeight) &&
            (identical(other.targetDate, targetDate) ||
                other.targetDate == targetDate) &&
            (identical(other.testWeekCompleted, testWeekCompleted) ||
                other.testWeekCompleted == testWeekCompleted) &&
            const DeepCollectionEquality().equals(
              other._testResults,
              _testResults,
            ) &&
            (identical(other.workoutLocation, workoutLocation) ||
                other.workoutLocation == workoutLocation) &&
            (identical(other.runningPreference, runningPreference) ||
                other.runningPreference == runningPreference) &&
            (identical(other.city, city) || other.city == city));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    weight,
    height,
    age,
    dateOfBirth,
    gender,
    goal,
    intensity,
    const DeepCollectionEquality().hash(_medicalRestrictions),
    const DeepCollectionEquality().hash(_exerciseRestrictions),
    activityLevel,
    targetWeight,
    targetDate,
    testWeekCompleted,
    const DeepCollectionEquality().hash(_testResults),
    workoutLocation,
    runningPreference,
    city,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserProfileImplCopyWith<_$UserProfileImpl> get copyWith =>
      __$$UserProfileImplCopyWithImpl<_$UserProfileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserProfileImplToJson(this);
  }
}

abstract class _UserProfile extends UserProfile {
  const factory _UserProfile({
    required final double weight,
    required final double height,
    required final int age,
    final DateTime? dateOfBirth,
    required final Gender gender,
    required final FitnessGoal goal,
    required final IntensityLevel intensity,
    final List<String> medicalRestrictions,
    final List<String> exerciseRestrictions,
    required final ActivityLevel activityLevel,
    final double? targetWeight,
    final DateTime? targetDate,
    final bool testWeekCompleted,
    final List<TestExerciseResult> testResults,
    final String? workoutLocation,
    final String? runningPreference,
    final String? city,
  }) = _$UserProfileImpl;
  const _UserProfile._() : super._();

  factory _UserProfile.fromJson(Map<String, dynamic> json) =
      _$UserProfileImpl.fromJson;

  @override
  double get weight;
  @override
  double get height;
  @override
  int get age;
  @override
  DateTime? get dateOfBirth;
  @override
  Gender get gender;
  @override
  FitnessGoal get goal;
  @override
  IntensityLevel get intensity;
  @override
  List<String> get medicalRestrictions;
  @override
  List<String> get exerciseRestrictions;
  @override
  ActivityLevel get activityLevel;
  @override
  double? get targetWeight;
  @override
  DateTime? get targetDate;
  @override
  bool get testWeekCompleted;
  @override
  List<TestExerciseResult> get testResults;
  @override
  String? get workoutLocation;
  @override
  String? get runningPreference;
  @override
  String? get city;
  @override
  @JsonKey(ignore: true)
  _$$UserProfileImplCopyWith<_$UserProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TestExerciseResult _$TestExerciseResultFromJson(Map<String, dynamic> json) {
  return _TestExerciseResult.fromJson(json);
}

/// @nodoc
mixin _$TestExerciseResult {
  String get exerciseName => throw _privateConstructorUsedError;
  MuscleGroup get primaryMuscle => throw _privateConstructorUsedError;
  double get comfortableWeightKg => throw _privateConstructorUsedError;
  int get comfortableSets => throw _privateConstructorUsedError;
  int get comfortableReps => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TestExerciseResultCopyWith<TestExerciseResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TestExerciseResultCopyWith<$Res> {
  factory $TestExerciseResultCopyWith(
    TestExerciseResult value,
    $Res Function(TestExerciseResult) then,
  ) = _$TestExerciseResultCopyWithImpl<$Res, TestExerciseResult>;
  @useResult
  $Res call({
    String exerciseName,
    MuscleGroup primaryMuscle,
    double comfortableWeightKg,
    int comfortableSets,
    int comfortableReps,
    String? notes,
  });
}

/// @nodoc
class _$TestExerciseResultCopyWithImpl<$Res, $Val extends TestExerciseResult>
    implements $TestExerciseResultCopyWith<$Res> {
  _$TestExerciseResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? exerciseName = null,
    Object? primaryMuscle = null,
    Object? comfortableWeightKg = null,
    Object? comfortableSets = null,
    Object? comfortableReps = null,
    Object? notes = freezed,
  }) {
    return _then(
      _value.copyWith(
            exerciseName: null == exerciseName
                ? _value.exerciseName
                : exerciseName // ignore: cast_nullable_to_non_nullable
                      as String,
            primaryMuscle: null == primaryMuscle
                ? _value.primaryMuscle
                : primaryMuscle // ignore: cast_nullable_to_non_nullable
                      as MuscleGroup,
            comfortableWeightKg: null == comfortableWeightKg
                ? _value.comfortableWeightKg
                : comfortableWeightKg // ignore: cast_nullable_to_non_nullable
                      as double,
            comfortableSets: null == comfortableSets
                ? _value.comfortableSets
                : comfortableSets // ignore: cast_nullable_to_non_nullable
                      as int,
            comfortableReps: null == comfortableReps
                ? _value.comfortableReps
                : comfortableReps // ignore: cast_nullable_to_non_nullable
                      as int,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TestExerciseResultImplCopyWith<$Res>
    implements $TestExerciseResultCopyWith<$Res> {
  factory _$$TestExerciseResultImplCopyWith(
    _$TestExerciseResultImpl value,
    $Res Function(_$TestExerciseResultImpl) then,
  ) = __$$TestExerciseResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String exerciseName,
    MuscleGroup primaryMuscle,
    double comfortableWeightKg,
    int comfortableSets,
    int comfortableReps,
    String? notes,
  });
}

/// @nodoc
class __$$TestExerciseResultImplCopyWithImpl<$Res>
    extends _$TestExerciseResultCopyWithImpl<$Res, _$TestExerciseResultImpl>
    implements _$$TestExerciseResultImplCopyWith<$Res> {
  __$$TestExerciseResultImplCopyWithImpl(
    _$TestExerciseResultImpl _value,
    $Res Function(_$TestExerciseResultImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? exerciseName = null,
    Object? primaryMuscle = null,
    Object? comfortableWeightKg = null,
    Object? comfortableSets = null,
    Object? comfortableReps = null,
    Object? notes = freezed,
  }) {
    return _then(
      _$TestExerciseResultImpl(
        exerciseName: null == exerciseName
            ? _value.exerciseName
            : exerciseName // ignore: cast_nullable_to_non_nullable
                  as String,
        primaryMuscle: null == primaryMuscle
            ? _value.primaryMuscle
            : primaryMuscle // ignore: cast_nullable_to_non_nullable
                  as MuscleGroup,
        comfortableWeightKg: null == comfortableWeightKg
            ? _value.comfortableWeightKg
            : comfortableWeightKg // ignore: cast_nullable_to_non_nullable
                  as double,
        comfortableSets: null == comfortableSets
            ? _value.comfortableSets
            : comfortableSets // ignore: cast_nullable_to_non_nullable
                  as int,
        comfortableReps: null == comfortableReps
            ? _value.comfortableReps
            : comfortableReps // ignore: cast_nullable_to_non_nullable
                  as int,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TestExerciseResultImpl implements _TestExerciseResult {
  const _$TestExerciseResultImpl({
    required this.exerciseName,
    required this.primaryMuscle,
    required this.comfortableWeightKg,
    required this.comfortableSets,
    required this.comfortableReps,
    this.notes,
  });

  factory _$TestExerciseResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$TestExerciseResultImplFromJson(json);

  @override
  final String exerciseName;
  @override
  final MuscleGroup primaryMuscle;
  @override
  final double comfortableWeightKg;
  @override
  final int comfortableSets;
  @override
  final int comfortableReps;
  @override
  final String? notes;

  @override
  String toString() {
    return 'TestExerciseResult(exerciseName: $exerciseName, primaryMuscle: $primaryMuscle, comfortableWeightKg: $comfortableWeightKg, comfortableSets: $comfortableSets, comfortableReps: $comfortableReps, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TestExerciseResultImpl &&
            (identical(other.exerciseName, exerciseName) ||
                other.exerciseName == exerciseName) &&
            (identical(other.primaryMuscle, primaryMuscle) ||
                other.primaryMuscle == primaryMuscle) &&
            (identical(other.comfortableWeightKg, comfortableWeightKg) ||
                other.comfortableWeightKg == comfortableWeightKg) &&
            (identical(other.comfortableSets, comfortableSets) ||
                other.comfortableSets == comfortableSets) &&
            (identical(other.comfortableReps, comfortableReps) ||
                other.comfortableReps == comfortableReps) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    exerciseName,
    primaryMuscle,
    comfortableWeightKg,
    comfortableSets,
    comfortableReps,
    notes,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TestExerciseResultImplCopyWith<_$TestExerciseResultImpl> get copyWith =>
      __$$TestExerciseResultImplCopyWithImpl<_$TestExerciseResultImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$TestExerciseResultImplToJson(this);
  }
}

abstract class _TestExerciseResult implements TestExerciseResult {
  const factory _TestExerciseResult({
    required final String exerciseName,
    required final MuscleGroup primaryMuscle,
    required final double comfortableWeightKg,
    required final int comfortableSets,
    required final int comfortableReps,
    final String? notes,
  }) = _$TestExerciseResultImpl;

  factory _TestExerciseResult.fromJson(Map<String, dynamic> json) =
      _$TestExerciseResultImpl.fromJson;

  @override
  String get exerciseName;
  @override
  MuscleGroup get primaryMuscle;
  @override
  double get comfortableWeightKg;
  @override
  int get comfortableSets;
  @override
  int get comfortableReps;
  @override
  String? get notes;
  @override
  @JsonKey(ignore: true)
  _$$TestExerciseResultImplCopyWith<_$TestExerciseResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
