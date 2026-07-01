// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'health_entities.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

HealthData _$HealthDataFromJson(Map<String, dynamic> json) {
  return _HealthData.fromJson(json);
}

/// @nodoc
mixin _$HealthData {
  String get userId => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  int? get steps => throw _privateConstructorUsedError;
  double? get caloriesBurned => throw _privateConstructorUsedError;
  int? get heartRateAvg => throw _privateConstructorUsedError;
  int? get heartRateResting => throw _privateConstructorUsedError;
  double? get weight => throw _privateConstructorUsedError;
  double? get bodyFatPercent => throw _privateConstructorUsedError;
  int? get sleepMinutes => throw _privateConstructorUsedError;
  double? get waterIntakeMl => throw _privateConstructorUsedError;
  double? get distanceKm => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $HealthDataCopyWith<HealthData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HealthDataCopyWith<$Res> {
  factory $HealthDataCopyWith(
    HealthData value,
    $Res Function(HealthData) then,
  ) = _$HealthDataCopyWithImpl<$Res, HealthData>;
  @useResult
  $Res call({
    String userId,
    DateTime date,
    int? steps,
    double? caloriesBurned,
    int? heartRateAvg,
    int? heartRateResting,
    double? weight,
    double? bodyFatPercent,
    int? sleepMinutes,
    double? waterIntakeMl,
    double? distanceKm,
  });
}

/// @nodoc
class _$HealthDataCopyWithImpl<$Res, $Val extends HealthData>
    implements $HealthDataCopyWith<$Res> {
  _$HealthDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? date = null,
    Object? steps = freezed,
    Object? caloriesBurned = freezed,
    Object? heartRateAvg = freezed,
    Object? heartRateResting = freezed,
    Object? weight = freezed,
    Object? bodyFatPercent = freezed,
    Object? sleepMinutes = freezed,
    Object? waterIntakeMl = freezed,
    Object? distanceKm = freezed,
  }) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            steps: freezed == steps
                ? _value.steps
                : steps // ignore: cast_nullable_to_non_nullable
                      as int?,
            caloriesBurned: freezed == caloriesBurned
                ? _value.caloriesBurned
                : caloriesBurned // ignore: cast_nullable_to_non_nullable
                      as double?,
            heartRateAvg: freezed == heartRateAvg
                ? _value.heartRateAvg
                : heartRateAvg // ignore: cast_nullable_to_non_nullable
                      as int?,
            heartRateResting: freezed == heartRateResting
                ? _value.heartRateResting
                : heartRateResting // ignore: cast_nullable_to_non_nullable
                      as int?,
            weight: freezed == weight
                ? _value.weight
                : weight // ignore: cast_nullable_to_non_nullable
                      as double?,
            bodyFatPercent: freezed == bodyFatPercent
                ? _value.bodyFatPercent
                : bodyFatPercent // ignore: cast_nullable_to_non_nullable
                      as double?,
            sleepMinutes: freezed == sleepMinutes
                ? _value.sleepMinutes
                : sleepMinutes // ignore: cast_nullable_to_non_nullable
                      as int?,
            waterIntakeMl: freezed == waterIntakeMl
                ? _value.waterIntakeMl
                : waterIntakeMl // ignore: cast_nullable_to_non_nullable
                      as double?,
            distanceKm: freezed == distanceKm
                ? _value.distanceKm
                : distanceKm // ignore: cast_nullable_to_non_nullable
                      as double?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$HealthDataImplCopyWith<$Res>
    implements $HealthDataCopyWith<$Res> {
  factory _$$HealthDataImplCopyWith(
    _$HealthDataImpl value,
    $Res Function(_$HealthDataImpl) then,
  ) = __$$HealthDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String userId,
    DateTime date,
    int? steps,
    double? caloriesBurned,
    int? heartRateAvg,
    int? heartRateResting,
    double? weight,
    double? bodyFatPercent,
    int? sleepMinutes,
    double? waterIntakeMl,
    double? distanceKm,
  });
}

/// @nodoc
class __$$HealthDataImplCopyWithImpl<$Res>
    extends _$HealthDataCopyWithImpl<$Res, _$HealthDataImpl>
    implements _$$HealthDataImplCopyWith<$Res> {
  __$$HealthDataImplCopyWithImpl(
    _$HealthDataImpl _value,
    $Res Function(_$HealthDataImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? date = null,
    Object? steps = freezed,
    Object? caloriesBurned = freezed,
    Object? heartRateAvg = freezed,
    Object? heartRateResting = freezed,
    Object? weight = freezed,
    Object? bodyFatPercent = freezed,
    Object? sleepMinutes = freezed,
    Object? waterIntakeMl = freezed,
    Object? distanceKm = freezed,
  }) {
    return _then(
      _$HealthDataImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        steps: freezed == steps
            ? _value.steps
            : steps // ignore: cast_nullable_to_non_nullable
                  as int?,
        caloriesBurned: freezed == caloriesBurned
            ? _value.caloriesBurned
            : caloriesBurned // ignore: cast_nullable_to_non_nullable
                  as double?,
        heartRateAvg: freezed == heartRateAvg
            ? _value.heartRateAvg
            : heartRateAvg // ignore: cast_nullable_to_non_nullable
                  as int?,
        heartRateResting: freezed == heartRateResting
            ? _value.heartRateResting
            : heartRateResting // ignore: cast_nullable_to_non_nullable
                  as int?,
        weight: freezed == weight
            ? _value.weight
            : weight // ignore: cast_nullable_to_non_nullable
                  as double?,
        bodyFatPercent: freezed == bodyFatPercent
            ? _value.bodyFatPercent
            : bodyFatPercent // ignore: cast_nullable_to_non_nullable
                  as double?,
        sleepMinutes: freezed == sleepMinutes
            ? _value.sleepMinutes
            : sleepMinutes // ignore: cast_nullable_to_non_nullable
                  as int?,
        waterIntakeMl: freezed == waterIntakeMl
            ? _value.waterIntakeMl
            : waterIntakeMl // ignore: cast_nullable_to_non_nullable
                  as double?,
        distanceKm: freezed == distanceKm
            ? _value.distanceKm
            : distanceKm // ignore: cast_nullable_to_non_nullable
                  as double?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$HealthDataImpl implements _HealthData {
  const _$HealthDataImpl({
    required this.userId,
    required this.date,
    this.steps,
    this.caloriesBurned,
    this.heartRateAvg,
    this.heartRateResting,
    this.weight,
    this.bodyFatPercent,
    this.sleepMinutes,
    this.waterIntakeMl,
    this.distanceKm,
  });

  factory _$HealthDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$HealthDataImplFromJson(json);

  @override
  final String userId;
  @override
  final DateTime date;
  @override
  final int? steps;
  @override
  final double? caloriesBurned;
  @override
  final int? heartRateAvg;
  @override
  final int? heartRateResting;
  @override
  final double? weight;
  @override
  final double? bodyFatPercent;
  @override
  final int? sleepMinutes;
  @override
  final double? waterIntakeMl;
  @override
  final double? distanceKm;

  @override
  String toString() {
    return 'HealthData(userId: $userId, date: $date, steps: $steps, caloriesBurned: $caloriesBurned, heartRateAvg: $heartRateAvg, heartRateResting: $heartRateResting, weight: $weight, bodyFatPercent: $bodyFatPercent, sleepMinutes: $sleepMinutes, waterIntakeMl: $waterIntakeMl, distanceKm: $distanceKm)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HealthDataImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.steps, steps) || other.steps == steps) &&
            (identical(other.caloriesBurned, caloriesBurned) ||
                other.caloriesBurned == caloriesBurned) &&
            (identical(other.heartRateAvg, heartRateAvg) ||
                other.heartRateAvg == heartRateAvg) &&
            (identical(other.heartRateResting, heartRateResting) ||
                other.heartRateResting == heartRateResting) &&
            (identical(other.weight, weight) || other.weight == weight) &&
            (identical(other.bodyFatPercent, bodyFatPercent) ||
                other.bodyFatPercent == bodyFatPercent) &&
            (identical(other.sleepMinutes, sleepMinutes) ||
                other.sleepMinutes == sleepMinutes) &&
            (identical(other.waterIntakeMl, waterIntakeMl) ||
                other.waterIntakeMl == waterIntakeMl) &&
            (identical(other.distanceKm, distanceKm) ||
                other.distanceKm == distanceKm));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    userId,
    date,
    steps,
    caloriesBurned,
    heartRateAvg,
    heartRateResting,
    weight,
    bodyFatPercent,
    sleepMinutes,
    waterIntakeMl,
    distanceKm,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$HealthDataImplCopyWith<_$HealthDataImpl> get copyWith =>
      __$$HealthDataImplCopyWithImpl<_$HealthDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HealthDataImplToJson(this);
  }
}

abstract class _HealthData implements HealthData {
  const factory _HealthData({
    required final String userId,
    required final DateTime date,
    final int? steps,
    final double? caloriesBurned,
    final int? heartRateAvg,
    final int? heartRateResting,
    final double? weight,
    final double? bodyFatPercent,
    final int? sleepMinutes,
    final double? waterIntakeMl,
    final double? distanceKm,
  }) = _$HealthDataImpl;

  factory _HealthData.fromJson(Map<String, dynamic> json) =
      _$HealthDataImpl.fromJson;

  @override
  String get userId;
  @override
  DateTime get date;
  @override
  int? get steps;
  @override
  double? get caloriesBurned;
  @override
  int? get heartRateAvg;
  @override
  int? get heartRateResting;
  @override
  double? get weight;
  @override
  double? get bodyFatPercent;
  @override
  int? get sleepMinutes;
  @override
  double? get waterIntakeMl;
  @override
  double? get distanceKm;
  @override
  @JsonKey(ignore: true)
  _$$HealthDataImplCopyWith<_$HealthDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ProgressEntry _$ProgressEntryFromJson(Map<String, dynamic> json) {
  return _ProgressEntry.fromJson(json);
}

/// @nodoc
mixin _$ProgressEntry {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  double? get weight => throw _privateConstructorUsedError;
  double? get bodyFatPercent => throw _privateConstructorUsedError;
  Map<String, double>? get measurements => throw _privateConstructorUsedError;
  String? get photoUrl => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ProgressEntryCopyWith<ProgressEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProgressEntryCopyWith<$Res> {
  factory $ProgressEntryCopyWith(
    ProgressEntry value,
    $Res Function(ProgressEntry) then,
  ) = _$ProgressEntryCopyWithImpl<$Res, ProgressEntry>;
  @useResult
  $Res call({
    String id,
    String userId,
    DateTime date,
    double? weight,
    double? bodyFatPercent,
    Map<String, double>? measurements,
    String? photoUrl,
    String? notes,
  });
}

/// @nodoc
class _$ProgressEntryCopyWithImpl<$Res, $Val extends ProgressEntry>
    implements $ProgressEntryCopyWith<$Res> {
  _$ProgressEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? date = null,
    Object? weight = freezed,
    Object? bodyFatPercent = freezed,
    Object? measurements = freezed,
    Object? photoUrl = freezed,
    Object? notes = freezed,
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
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            weight: freezed == weight
                ? _value.weight
                : weight // ignore: cast_nullable_to_non_nullable
                      as double?,
            bodyFatPercent: freezed == bodyFatPercent
                ? _value.bodyFatPercent
                : bodyFatPercent // ignore: cast_nullable_to_non_nullable
                      as double?,
            measurements: freezed == measurements
                ? _value.measurements
                : measurements // ignore: cast_nullable_to_non_nullable
                      as Map<String, double>?,
            photoUrl: freezed == photoUrl
                ? _value.photoUrl
                : photoUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
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
abstract class _$$ProgressEntryImplCopyWith<$Res>
    implements $ProgressEntryCopyWith<$Res> {
  factory _$$ProgressEntryImplCopyWith(
    _$ProgressEntryImpl value,
    $Res Function(_$ProgressEntryImpl) then,
  ) = __$$ProgressEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    DateTime date,
    double? weight,
    double? bodyFatPercent,
    Map<String, double>? measurements,
    String? photoUrl,
    String? notes,
  });
}

/// @nodoc
class __$$ProgressEntryImplCopyWithImpl<$Res>
    extends _$ProgressEntryCopyWithImpl<$Res, _$ProgressEntryImpl>
    implements _$$ProgressEntryImplCopyWith<$Res> {
  __$$ProgressEntryImplCopyWithImpl(
    _$ProgressEntryImpl _value,
    $Res Function(_$ProgressEntryImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? date = null,
    Object? weight = freezed,
    Object? bodyFatPercent = freezed,
    Object? measurements = freezed,
    Object? photoUrl = freezed,
    Object? notes = freezed,
  }) {
    return _then(
      _$ProgressEntryImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        weight: freezed == weight
            ? _value.weight
            : weight // ignore: cast_nullable_to_non_nullable
                  as double?,
        bodyFatPercent: freezed == bodyFatPercent
            ? _value.bodyFatPercent
            : bodyFatPercent // ignore: cast_nullable_to_non_nullable
                  as double?,
        measurements: freezed == measurements
            ? _value._measurements
            : measurements // ignore: cast_nullable_to_non_nullable
                  as Map<String, double>?,
        photoUrl: freezed == photoUrl
            ? _value.photoUrl
            : photoUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
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
class _$ProgressEntryImpl implements _ProgressEntry {
  const _$ProgressEntryImpl({
    required this.id,
    required this.userId,
    required this.date,
    this.weight,
    this.bodyFatPercent,
    final Map<String, double>? measurements,
    this.photoUrl,
    this.notes,
  }) : _measurements = measurements;

  factory _$ProgressEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProgressEntryImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final DateTime date;
  @override
  final double? weight;
  @override
  final double? bodyFatPercent;
  final Map<String, double>? _measurements;
  @override
  Map<String, double>? get measurements {
    final value = _measurements;
    if (value == null) return null;
    if (_measurements is EqualUnmodifiableMapView) return _measurements;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final String? photoUrl;
  @override
  final String? notes;

  @override
  String toString() {
    return 'ProgressEntry(id: $id, userId: $userId, date: $date, weight: $weight, bodyFatPercent: $bodyFatPercent, measurements: $measurements, photoUrl: $photoUrl, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProgressEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.weight, weight) || other.weight == weight) &&
            (identical(other.bodyFatPercent, bodyFatPercent) ||
                other.bodyFatPercent == bodyFatPercent) &&
            const DeepCollectionEquality().equals(
              other._measurements,
              _measurements,
            ) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    date,
    weight,
    bodyFatPercent,
    const DeepCollectionEquality().hash(_measurements),
    photoUrl,
    notes,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ProgressEntryImplCopyWith<_$ProgressEntryImpl> get copyWith =>
      __$$ProgressEntryImplCopyWithImpl<_$ProgressEntryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProgressEntryImplToJson(this);
  }
}

abstract class _ProgressEntry implements ProgressEntry {
  const factory _ProgressEntry({
    required final String id,
    required final String userId,
    required final DateTime date,
    final double? weight,
    final double? bodyFatPercent,
    final Map<String, double>? measurements,
    final String? photoUrl,
    final String? notes,
  }) = _$ProgressEntryImpl;

  factory _ProgressEntry.fromJson(Map<String, dynamic> json) =
      _$ProgressEntryImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  DateTime get date;
  @override
  double? get weight;
  @override
  double? get bodyFatPercent;
  @override
  Map<String, double>? get measurements;
  @override
  String? get photoUrl;
  @override
  String? get notes;
  @override
  @JsonKey(ignore: true)
  _$$ProgressEntryImplCopyWith<_$ProgressEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
