// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'body_measurement.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

BodyMeasurement _$BodyMeasurementFromJson(Map<String, dynamic> json) {
  return _BodyMeasurement.fromJson(json);
}

/// @nodoc
mixin _$BodyMeasurement {
  @JsonKey(fromJson: _dateFromMillis, toJson: _dateToMillis)
  DateTime get date => throw _privateConstructorUsedError;
  double? get chestCm => throw _privateConstructorUsedError;
  double? get waistCm => throw _privateConstructorUsedError;
  double? get hipsCm => throw _privateConstructorUsedError;
  double? get bodyFatPercent => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $BodyMeasurementCopyWith<BodyMeasurement> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BodyMeasurementCopyWith<$Res> {
  factory $BodyMeasurementCopyWith(
    BodyMeasurement value,
    $Res Function(BodyMeasurement) then,
  ) = _$BodyMeasurementCopyWithImpl<$Res, BodyMeasurement>;
  @useResult
  $Res call({
    @JsonKey(fromJson: _dateFromMillis, toJson: _dateToMillis) DateTime date,
    double? chestCm,
    double? waistCm,
    double? hipsCm,
    double? bodyFatPercent,
  });
}

/// @nodoc
class _$BodyMeasurementCopyWithImpl<$Res, $Val extends BodyMeasurement>
    implements $BodyMeasurementCopyWith<$Res> {
  _$BodyMeasurementCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? chestCm = freezed,
    Object? waistCm = freezed,
    Object? hipsCm = freezed,
    Object? bodyFatPercent = freezed,
  }) {
    return _then(
      _value.copyWith(
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            chestCm: freezed == chestCm
                ? _value.chestCm
                : chestCm // ignore: cast_nullable_to_non_nullable
                      as double?,
            waistCm: freezed == waistCm
                ? _value.waistCm
                : waistCm // ignore: cast_nullable_to_non_nullable
                      as double?,
            hipsCm: freezed == hipsCm
                ? _value.hipsCm
                : hipsCm // ignore: cast_nullable_to_non_nullable
                      as double?,
            bodyFatPercent: freezed == bodyFatPercent
                ? _value.bodyFatPercent
                : bodyFatPercent // ignore: cast_nullable_to_non_nullable
                      as double?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BodyMeasurementImplCopyWith<$Res>
    implements $BodyMeasurementCopyWith<$Res> {
  factory _$$BodyMeasurementImplCopyWith(
    _$BodyMeasurementImpl value,
    $Res Function(_$BodyMeasurementImpl) then,
  ) = __$$BodyMeasurementImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(fromJson: _dateFromMillis, toJson: _dateToMillis) DateTime date,
    double? chestCm,
    double? waistCm,
    double? hipsCm,
    double? bodyFatPercent,
  });
}

/// @nodoc
class __$$BodyMeasurementImplCopyWithImpl<$Res>
    extends _$BodyMeasurementCopyWithImpl<$Res, _$BodyMeasurementImpl>
    implements _$$BodyMeasurementImplCopyWith<$Res> {
  __$$BodyMeasurementImplCopyWithImpl(
    _$BodyMeasurementImpl _value,
    $Res Function(_$BodyMeasurementImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? chestCm = freezed,
    Object? waistCm = freezed,
    Object? hipsCm = freezed,
    Object? bodyFatPercent = freezed,
  }) {
    return _then(
      _$BodyMeasurementImpl(
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        chestCm: freezed == chestCm
            ? _value.chestCm
            : chestCm // ignore: cast_nullable_to_non_nullable
                  as double?,
        waistCm: freezed == waistCm
            ? _value.waistCm
            : waistCm // ignore: cast_nullable_to_non_nullable
                  as double?,
        hipsCm: freezed == hipsCm
            ? _value.hipsCm
            : hipsCm // ignore: cast_nullable_to_non_nullable
                  as double?,
        bodyFatPercent: freezed == bodyFatPercent
            ? _value.bodyFatPercent
            : bodyFatPercent // ignore: cast_nullable_to_non_nullable
                  as double?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BodyMeasurementImpl extends _BodyMeasurement {
  const _$BodyMeasurementImpl({
    @JsonKey(fromJson: _dateFromMillis, toJson: _dateToMillis)
    required this.date,
    this.chestCm,
    this.waistCm,
    this.hipsCm,
    this.bodyFatPercent,
  }) : super._();

  factory _$BodyMeasurementImpl.fromJson(Map<String, dynamic> json) =>
      _$$BodyMeasurementImplFromJson(json);

  @override
  @JsonKey(fromJson: _dateFromMillis, toJson: _dateToMillis)
  final DateTime date;
  @override
  final double? chestCm;
  @override
  final double? waistCm;
  @override
  final double? hipsCm;
  @override
  final double? bodyFatPercent;

  @override
  String toString() {
    return 'BodyMeasurement(date: $date, chestCm: $chestCm, waistCm: $waistCm, hipsCm: $hipsCm, bodyFatPercent: $bodyFatPercent)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BodyMeasurementImpl &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.chestCm, chestCm) || other.chestCm == chestCm) &&
            (identical(other.waistCm, waistCm) || other.waistCm == waistCm) &&
            (identical(other.hipsCm, hipsCm) || other.hipsCm == hipsCm) &&
            (identical(other.bodyFatPercent, bodyFatPercent) ||
                other.bodyFatPercent == bodyFatPercent));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, date, chestCm, waistCm, hipsCm, bodyFatPercent);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BodyMeasurementImplCopyWith<_$BodyMeasurementImpl> get copyWith =>
      __$$BodyMeasurementImplCopyWithImpl<_$BodyMeasurementImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$BodyMeasurementImplToJson(this);
  }
}

abstract class _BodyMeasurement extends BodyMeasurement {
  const factory _BodyMeasurement({
    @JsonKey(fromJson: _dateFromMillis, toJson: _dateToMillis)
    required final DateTime date,
    final double? chestCm,
    final double? waistCm,
    final double? hipsCm,
    final double? bodyFatPercent,
  }) = _$BodyMeasurementImpl;
  const _BodyMeasurement._() : super._();

  factory _BodyMeasurement.fromJson(Map<String, dynamic> json) =
      _$BodyMeasurementImpl.fromJson;

  @override
  @JsonKey(fromJson: _dateFromMillis, toJson: _dateToMillis)
  DateTime get date;
  @override
  double? get chestCm;
  @override
  double? get waistCm;
  @override
  double? get hipsCm;
  @override
  double? get bodyFatPercent;
  @override
  @JsonKey(ignore: true)
  _$$BodyMeasurementImplCopyWith<_$BodyMeasurementImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
