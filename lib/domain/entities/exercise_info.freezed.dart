// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exercise_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ExerciseInfo _$ExerciseInfoFromJson(Map<String, dynamic> json) {
  return _ExerciseInfo.fromJson(json);
}

/// @nodoc
mixin _$ExerciseInfo {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get muscleGroup => throw _privateConstructorUsedError;
  String? get gifUrl => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ExerciseInfoCopyWith<ExerciseInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExerciseInfoCopyWith<$Res> {
  factory $ExerciseInfoCopyWith(
          ExerciseInfo value, $Res Function(ExerciseInfo) then) =
      _$ExerciseInfoCopyWithImpl<$Res, ExerciseInfo>;
  @useResult
  $Res call({String id, String name, String? muscleGroup, String? gifUrl});
}

/// @nodoc
class _$ExerciseInfoCopyWithImpl<$Res, $Val extends ExerciseInfo>
    implements $ExerciseInfoCopyWith<$Res> {
  _$ExerciseInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? muscleGroup = freezed,
    Object? gifUrl = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      muscleGroup: freezed == muscleGroup
          ? _value.muscleGroup
          : muscleGroup // ignore: cast_nullable_to_non_nullable
              as String?,
      gifUrl: freezed == gifUrl
          ? _value.gifUrl
          : gifUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExerciseInfoImplCopyWith<$Res>
    implements $ExerciseInfoCopyWith<$Res> {
  factory _$$ExerciseInfoImplCopyWith(
          _$ExerciseInfoImpl value, $Res Function(_$ExerciseInfoImpl) then) =
      __$$ExerciseInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, String? muscleGroup, String? gifUrl});
}

/// @nodoc
class __$$ExerciseInfoImplCopyWithImpl<$Res>
    extends _$ExerciseInfoCopyWithImpl<$Res, _$ExerciseInfoImpl>
    implements _$$ExerciseInfoImplCopyWith<$Res> {
  __$$ExerciseInfoImplCopyWithImpl(
      _$ExerciseInfoImpl _value, $Res Function(_$ExerciseInfoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? muscleGroup = freezed,
    Object? gifUrl = freezed,
  }) {
    return _then(_$ExerciseInfoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      muscleGroup: freezed == muscleGroup
          ? _value.muscleGroup
          : muscleGroup // ignore: cast_nullable_to_non_nullable
              as String?,
      gifUrl: freezed == gifUrl
          ? _value.gifUrl
          : gifUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExerciseInfoImpl implements _ExerciseInfo {
  const _$ExerciseInfoImpl(
      {required this.id, required this.name, this.muscleGroup, this.gifUrl});

  factory _$ExerciseInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExerciseInfoImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? muscleGroup;
  @override
  final String? gifUrl;

  @override
  String toString() {
    return 'ExerciseInfo(id: $id, name: $name, muscleGroup: $muscleGroup, gifUrl: $gifUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExerciseInfoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.muscleGroup, muscleGroup) ||
                other.muscleGroup == muscleGroup) &&
            (identical(other.gifUrl, gifUrl) || other.gifUrl == gifUrl));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, muscleGroup, gifUrl);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ExerciseInfoImplCopyWith<_$ExerciseInfoImpl> get copyWith =>
      __$$ExerciseInfoImplCopyWithImpl<_$ExerciseInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExerciseInfoImplToJson(
      this,
    );
  }
}

abstract class _ExerciseInfo implements ExerciseInfo {
  const factory _ExerciseInfo(
      {required final String id,
      required final String name,
      final String? muscleGroup,
      final String? gifUrl}) = _$ExerciseInfoImpl;

  factory _ExerciseInfo.fromJson(Map<String, dynamic> json) =
      _$ExerciseInfoImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get muscleGroup;
  @override
  String? get gifUrl;
  @override
  @JsonKey(ignore: true)
  _$$ExerciseInfoImplCopyWith<_$ExerciseInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
