// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'nutrition_entities.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

NutritionPer100g _$NutritionPer100gFromJson(Map<String, dynamic> json) {
  return _NutritionPer100g.fromJson(json);
}

/// @nodoc
mixin _$NutritionPer100g {
  double get calories => throw _privateConstructorUsedError;
  double get protein => throw _privateConstructorUsedError;
  double get carbs => throw _privateConstructorUsedError;
  double get fat => throw _privateConstructorUsedError;
  double? get fiber => throw _privateConstructorUsedError;
  double? get sugar => throw _privateConstructorUsedError;
  double? get sodium => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $NutritionPer100gCopyWith<NutritionPer100g> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NutritionPer100gCopyWith<$Res> {
  factory $NutritionPer100gCopyWith(
          NutritionPer100g value, $Res Function(NutritionPer100g) then) =
      _$NutritionPer100gCopyWithImpl<$Res, NutritionPer100g>;
  @useResult
  $Res call(
      {double calories,
      double protein,
      double carbs,
      double fat,
      double? fiber,
      double? sugar,
      double? sodium});
}

/// @nodoc
class _$NutritionPer100gCopyWithImpl<$Res, $Val extends NutritionPer100g>
    implements $NutritionPer100gCopyWith<$Res> {
  _$NutritionPer100gCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? calories = null,
    Object? protein = null,
    Object? carbs = null,
    Object? fat = null,
    Object? fiber = freezed,
    Object? sugar = freezed,
    Object? sodium = freezed,
  }) {
    return _then(_value.copyWith(
      calories: null == calories
          ? _value.calories
          : calories // ignore: cast_nullable_to_non_nullable
              as double,
      protein: null == protein
          ? _value.protein
          : protein // ignore: cast_nullable_to_non_nullable
              as double,
      carbs: null == carbs
          ? _value.carbs
          : carbs // ignore: cast_nullable_to_non_nullable
              as double,
      fat: null == fat
          ? _value.fat
          : fat // ignore: cast_nullable_to_non_nullable
              as double,
      fiber: freezed == fiber
          ? _value.fiber
          : fiber // ignore: cast_nullable_to_non_nullable
              as double?,
      sugar: freezed == sugar
          ? _value.sugar
          : sugar // ignore: cast_nullable_to_non_nullable
              as double?,
      sodium: freezed == sodium
          ? _value.sodium
          : sodium // ignore: cast_nullable_to_non_nullable
              as double?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NutritionPer100gImplCopyWith<$Res>
    implements $NutritionPer100gCopyWith<$Res> {
  factory _$$NutritionPer100gImplCopyWith(_$NutritionPer100gImpl value,
          $Res Function(_$NutritionPer100gImpl) then) =
      __$$NutritionPer100gImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double calories,
      double protein,
      double carbs,
      double fat,
      double? fiber,
      double? sugar,
      double? sodium});
}

/// @nodoc
class __$$NutritionPer100gImplCopyWithImpl<$Res>
    extends _$NutritionPer100gCopyWithImpl<$Res, _$NutritionPer100gImpl>
    implements _$$NutritionPer100gImplCopyWith<$Res> {
  __$$NutritionPer100gImplCopyWithImpl(_$NutritionPer100gImpl _value,
      $Res Function(_$NutritionPer100gImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? calories = null,
    Object? protein = null,
    Object? carbs = null,
    Object? fat = null,
    Object? fiber = freezed,
    Object? sugar = freezed,
    Object? sodium = freezed,
  }) {
    return _then(_$NutritionPer100gImpl(
      calories: null == calories
          ? _value.calories
          : calories // ignore: cast_nullable_to_non_nullable
              as double,
      protein: null == protein
          ? _value.protein
          : protein // ignore: cast_nullable_to_non_nullable
              as double,
      carbs: null == carbs
          ? _value.carbs
          : carbs // ignore: cast_nullable_to_non_nullable
              as double,
      fat: null == fat
          ? _value.fat
          : fat // ignore: cast_nullable_to_non_nullable
              as double,
      fiber: freezed == fiber
          ? _value.fiber
          : fiber // ignore: cast_nullable_to_non_nullable
              as double?,
      sugar: freezed == sugar
          ? _value.sugar
          : sugar // ignore: cast_nullable_to_non_nullable
              as double?,
      sodium: freezed == sodium
          ? _value.sodium
          : sodium // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NutritionPer100gImpl implements _NutritionPer100g {
  const _$NutritionPer100gImpl(
      {required this.calories,
      required this.protein,
      required this.carbs,
      required this.fat,
      this.fiber,
      this.sugar,
      this.sodium});

  factory _$NutritionPer100gImpl.fromJson(Map<String, dynamic> json) =>
      _$$NutritionPer100gImplFromJson(json);

  @override
  final double calories;
  @override
  final double protein;
  @override
  final double carbs;
  @override
  final double fat;
  @override
  final double? fiber;
  @override
  final double? sugar;
  @override
  final double? sodium;

  @override
  String toString() {
    return 'NutritionPer100g(calories: $calories, protein: $protein, carbs: $carbs, fat: $fat, fiber: $fiber, sugar: $sugar, sodium: $sodium)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NutritionPer100gImpl &&
            (identical(other.calories, calories) ||
                other.calories == calories) &&
            (identical(other.protein, protein) || other.protein == protein) &&
            (identical(other.carbs, carbs) || other.carbs == carbs) &&
            (identical(other.fat, fat) || other.fat == fat) &&
            (identical(other.fiber, fiber) || other.fiber == fiber) &&
            (identical(other.sugar, sugar) || other.sugar == sugar) &&
            (identical(other.sodium, sodium) || other.sodium == sodium));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, calories, protein, carbs, fat, fiber, sugar, sodium);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$NutritionPer100gImplCopyWith<_$NutritionPer100gImpl> get copyWith =>
      __$$NutritionPer100gImplCopyWithImpl<_$NutritionPer100gImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NutritionPer100gImplToJson(
      this,
    );
  }
}

abstract class _NutritionPer100g implements NutritionPer100g {
  const factory _NutritionPer100g(
      {required final double calories,
      required final double protein,
      required final double carbs,
      required final double fat,
      final double? fiber,
      final double? sugar,
      final double? sodium}) = _$NutritionPer100gImpl;

  factory _NutritionPer100g.fromJson(Map<String, dynamic> json) =
      _$NutritionPer100gImpl.fromJson;

  @override
  double get calories;
  @override
  double get protein;
  @override
  double get carbs;
  @override
  double get fat;
  @override
  double? get fiber;
  @override
  double? get sugar;
  @override
  double? get sodium;
  @override
  @JsonKey(ignore: true)
  _$$NutritionPer100gImplCopyWith<_$NutritionPer100gImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FoodItem _$FoodItemFromJson(Map<String, dynamic> json) {
  return _FoodItem.fromJson(json);
}

/// @nodoc
mixin _$FoodItem {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get brand => throw _privateConstructorUsedError;
  String? get barcode => throw _privateConstructorUsedError;
  NutritionPer100g get nutrition => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FoodItemCopyWith<FoodItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FoodItemCopyWith<$Res> {
  factory $FoodItemCopyWith(FoodItem value, $Res Function(FoodItem) then) =
      _$FoodItemCopyWithImpl<$Res, FoodItem>;
  @useResult
  $Res call(
      {String id,
      String name,
      String? brand,
      String? barcode,
      NutritionPer100g nutrition,
      String? imageUrl});

  $NutritionPer100gCopyWith<$Res> get nutrition;
}

/// @nodoc
class _$FoodItemCopyWithImpl<$Res, $Val extends FoodItem>
    implements $FoodItemCopyWith<$Res> {
  _$FoodItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? brand = freezed,
    Object? barcode = freezed,
    Object? nutrition = null,
    Object? imageUrl = freezed,
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
      brand: freezed == brand
          ? _value.brand
          : brand // ignore: cast_nullable_to_non_nullable
              as String?,
      barcode: freezed == barcode
          ? _value.barcode
          : barcode // ignore: cast_nullable_to_non_nullable
              as String?,
      nutrition: null == nutrition
          ? _value.nutrition
          : nutrition // ignore: cast_nullable_to_non_nullable
              as NutritionPer100g,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $NutritionPer100gCopyWith<$Res> get nutrition {
    return $NutritionPer100gCopyWith<$Res>(_value.nutrition, (value) {
      return _then(_value.copyWith(nutrition: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$FoodItemImplCopyWith<$Res>
    implements $FoodItemCopyWith<$Res> {
  factory _$$FoodItemImplCopyWith(
          _$FoodItemImpl value, $Res Function(_$FoodItemImpl) then) =
      __$$FoodItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String? brand,
      String? barcode,
      NutritionPer100g nutrition,
      String? imageUrl});

  @override
  $NutritionPer100gCopyWith<$Res> get nutrition;
}

/// @nodoc
class __$$FoodItemImplCopyWithImpl<$Res>
    extends _$FoodItemCopyWithImpl<$Res, _$FoodItemImpl>
    implements _$$FoodItemImplCopyWith<$Res> {
  __$$FoodItemImplCopyWithImpl(
      _$FoodItemImpl _value, $Res Function(_$FoodItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? brand = freezed,
    Object? barcode = freezed,
    Object? nutrition = null,
    Object? imageUrl = freezed,
  }) {
    return _then(_$FoodItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      brand: freezed == brand
          ? _value.brand
          : brand // ignore: cast_nullable_to_non_nullable
              as String?,
      barcode: freezed == barcode
          ? _value.barcode
          : barcode // ignore: cast_nullable_to_non_nullable
              as String?,
      nutrition: null == nutrition
          ? _value.nutrition
          : nutrition // ignore: cast_nullable_to_non_nullable
              as NutritionPer100g,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FoodItemImpl extends _FoodItem {
  const _$FoodItemImpl(
      {required this.id,
      required this.name,
      this.brand,
      this.barcode,
      required this.nutrition,
      this.imageUrl})
      : super._();

  factory _$FoodItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$FoodItemImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? brand;
  @override
  final String? barcode;
  @override
  final NutritionPer100g nutrition;
  @override
  final String? imageUrl;

  @override
  String toString() {
    return 'FoodItem(id: $id, name: $name, brand: $brand, barcode: $barcode, nutrition: $nutrition, imageUrl: $imageUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FoodItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.brand, brand) || other.brand == brand) &&
            (identical(other.barcode, barcode) || other.barcode == barcode) &&
            (identical(other.nutrition, nutrition) ||
                other.nutrition == nutrition) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, brand, barcode, nutrition, imageUrl);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FoodItemImplCopyWith<_$FoodItemImpl> get copyWith =>
      __$$FoodItemImplCopyWithImpl<_$FoodItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FoodItemImplToJson(
      this,
    );
  }
}

abstract class _FoodItem extends FoodItem {
  const factory _FoodItem(
      {required final String id,
      required final String name,
      final String? brand,
      final String? barcode,
      required final NutritionPer100g nutrition,
      final String? imageUrl}) = _$FoodItemImpl;
  const _FoodItem._() : super._();

  factory _FoodItem.fromJson(Map<String, dynamic> json) =
      _$FoodItemImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get brand;
  @override
  String? get barcode;
  @override
  NutritionPer100g get nutrition;
  @override
  String? get imageUrl;
  @override
  @JsonKey(ignore: true)
  _$$FoodItemImplCopyWith<_$FoodItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FoodEntry _$FoodEntryFromJson(Map<String, dynamic> json) {
  return _FoodEntry.fromJson(json);
}

/// @nodoc
mixin _$FoodEntry {
  FoodItem get food => throw _privateConstructorUsedError;
  double get grams => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FoodEntryCopyWith<FoodEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FoodEntryCopyWith<$Res> {
  factory $FoodEntryCopyWith(FoodEntry value, $Res Function(FoodEntry) then) =
      _$FoodEntryCopyWithImpl<$Res, FoodEntry>;
  @useResult
  $Res call({FoodItem food, double grams});

  $FoodItemCopyWith<$Res> get food;
}

/// @nodoc
class _$FoodEntryCopyWithImpl<$Res, $Val extends FoodEntry>
    implements $FoodEntryCopyWith<$Res> {
  _$FoodEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? food = null,
    Object? grams = null,
  }) {
    return _then(_value.copyWith(
      food: null == food
          ? _value.food
          : food // ignore: cast_nullable_to_non_nullable
              as FoodItem,
      grams: null == grams
          ? _value.grams
          : grams // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $FoodItemCopyWith<$Res> get food {
    return $FoodItemCopyWith<$Res>(_value.food, (value) {
      return _then(_value.copyWith(food: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$FoodEntryImplCopyWith<$Res>
    implements $FoodEntryCopyWith<$Res> {
  factory _$$FoodEntryImplCopyWith(
          _$FoodEntryImpl value, $Res Function(_$FoodEntryImpl) then) =
      __$$FoodEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({FoodItem food, double grams});

  @override
  $FoodItemCopyWith<$Res> get food;
}

/// @nodoc
class __$$FoodEntryImplCopyWithImpl<$Res>
    extends _$FoodEntryCopyWithImpl<$Res, _$FoodEntryImpl>
    implements _$$FoodEntryImplCopyWith<$Res> {
  __$$FoodEntryImplCopyWithImpl(
      _$FoodEntryImpl _value, $Res Function(_$FoodEntryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? food = null,
    Object? grams = null,
  }) {
    return _then(_$FoodEntryImpl(
      food: null == food
          ? _value.food
          : food // ignore: cast_nullable_to_non_nullable
              as FoodItem,
      grams: null == grams
          ? _value.grams
          : grams // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FoodEntryImpl extends _FoodEntry {
  const _$FoodEntryImpl({required this.food, required this.grams}) : super._();

  factory _$FoodEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$FoodEntryImplFromJson(json);

  @override
  final FoodItem food;
  @override
  final double grams;

  @override
  String toString() {
    return 'FoodEntry(food: $food, grams: $grams)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FoodEntryImpl &&
            (identical(other.food, food) || other.food == food) &&
            (identical(other.grams, grams) || other.grams == grams));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, food, grams);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FoodEntryImplCopyWith<_$FoodEntryImpl> get copyWith =>
      __$$FoodEntryImplCopyWithImpl<_$FoodEntryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FoodEntryImplToJson(
      this,
    );
  }
}

abstract class _FoodEntry extends FoodEntry {
  const factory _FoodEntry(
      {required final FoodItem food,
      required final double grams}) = _$FoodEntryImpl;
  const _FoodEntry._() : super._();

  factory _FoodEntry.fromJson(Map<String, dynamic> json) =
      _$FoodEntryImpl.fromJson;

  @override
  FoodItem get food;
  @override
  double get grams;
  @override
  @JsonKey(ignore: true)
  _$$FoodEntryImplCopyWith<_$FoodEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MealLog _$MealLogFromJson(Map<String, dynamic> json) {
  return _MealLog.fromJson(json);
}

/// @nodoc
mixin _$MealLog {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  MealType get mealType => throw _privateConstructorUsedError;
  List<FoodEntry> get foods => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MealLogCopyWith<MealLog> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MealLogCopyWith<$Res> {
  factory $MealLogCopyWith(MealLog value, $Res Function(MealLog) then) =
      _$MealLogCopyWithImpl<$Res, MealLog>;
  @useResult
  $Res call(
      {String id,
      String userId,
      DateTime date,
      MealType mealType,
      List<FoodEntry> foods});
}

/// @nodoc
class _$MealLogCopyWithImpl<$Res, $Val extends MealLog>
    implements $MealLogCopyWith<$Res> {
  _$MealLogCopyWithImpl(this._value, this._then);

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
    Object? mealType = null,
    Object? foods = null,
  }) {
    return _then(_value.copyWith(
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
      mealType: null == mealType
          ? _value.mealType
          : mealType // ignore: cast_nullable_to_non_nullable
              as MealType,
      foods: null == foods
          ? _value.foods
          : foods // ignore: cast_nullable_to_non_nullable
              as List<FoodEntry>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MealLogImplCopyWith<$Res> implements $MealLogCopyWith<$Res> {
  factory _$$MealLogImplCopyWith(
          _$MealLogImpl value, $Res Function(_$MealLogImpl) then) =
      __$$MealLogImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      DateTime date,
      MealType mealType,
      List<FoodEntry> foods});
}

/// @nodoc
class __$$MealLogImplCopyWithImpl<$Res>
    extends _$MealLogCopyWithImpl<$Res, _$MealLogImpl>
    implements _$$MealLogImplCopyWith<$Res> {
  __$$MealLogImplCopyWithImpl(
      _$MealLogImpl _value, $Res Function(_$MealLogImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? date = null,
    Object? mealType = null,
    Object? foods = null,
  }) {
    return _then(_$MealLogImpl(
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
      mealType: null == mealType
          ? _value.mealType
          : mealType // ignore: cast_nullable_to_non_nullable
              as MealType,
      foods: null == foods
          ? _value._foods
          : foods // ignore: cast_nullable_to_non_nullable
              as List<FoodEntry>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MealLogImpl extends _MealLog {
  const _$MealLogImpl(
      {required this.id,
      required this.userId,
      required this.date,
      required this.mealType,
      required final List<FoodEntry> foods})
      : _foods = foods,
        super._();

  factory _$MealLogImpl.fromJson(Map<String, dynamic> json) =>
      _$$MealLogImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final DateTime date;
  @override
  final MealType mealType;
  final List<FoodEntry> _foods;
  @override
  List<FoodEntry> get foods {
    if (_foods is EqualUnmodifiableListView) return _foods;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_foods);
  }

  @override
  String toString() {
    return 'MealLog(id: $id, userId: $userId, date: $date, mealType: $mealType, foods: $foods)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MealLogImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.mealType, mealType) ||
                other.mealType == mealType) &&
            const DeepCollectionEquality().equals(other._foods, _foods));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, userId, date, mealType,
      const DeepCollectionEquality().hash(_foods));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MealLogImplCopyWith<_$MealLogImpl> get copyWith =>
      __$$MealLogImplCopyWithImpl<_$MealLogImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MealLogImplToJson(
      this,
    );
  }
}

abstract class _MealLog extends MealLog {
  const factory _MealLog(
      {required final String id,
      required final String userId,
      required final DateTime date,
      required final MealType mealType,
      required final List<FoodEntry> foods}) = _$MealLogImpl;
  const _MealLog._() : super._();

  factory _MealLog.fromJson(Map<String, dynamic> json) = _$MealLogImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  DateTime get date;
  @override
  MealType get mealType;
  @override
  List<FoodEntry> get foods;
  @override
  @JsonKey(ignore: true)
  _$$MealLogImplCopyWith<_$MealLogImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MealPlan _$MealPlanFromJson(Map<String, dynamic> json) {
  return _MealPlan.fromJson(json);
}

/// @nodoc
mixin _$MealPlan {
  MealType get type => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  List<MealPlanItem> get items => throw _privateConstructorUsedError;
  int get targetCalories => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MealPlanCopyWith<MealPlan> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MealPlanCopyWith<$Res> {
  factory $MealPlanCopyWith(MealPlan value, $Res Function(MealPlan) then) =
      _$MealPlanCopyWithImpl<$Res, MealPlan>;
  @useResult
  $Res call(
      {MealType type,
      String title,
      List<MealPlanItem> items,
      int targetCalories});
}

/// @nodoc
class _$MealPlanCopyWithImpl<$Res, $Val extends MealPlan>
    implements $MealPlanCopyWith<$Res> {
  _$MealPlanCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? title = null,
    Object? items = null,
    Object? targetCalories = null,
  }) {
    return _then(_value.copyWith(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as MealType,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<MealPlanItem>,
      targetCalories: null == targetCalories
          ? _value.targetCalories
          : targetCalories // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MealPlanImplCopyWith<$Res>
    implements $MealPlanCopyWith<$Res> {
  factory _$$MealPlanImplCopyWith(
          _$MealPlanImpl value, $Res Function(_$MealPlanImpl) then) =
      __$$MealPlanImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {MealType type,
      String title,
      List<MealPlanItem> items,
      int targetCalories});
}

/// @nodoc
class __$$MealPlanImplCopyWithImpl<$Res>
    extends _$MealPlanCopyWithImpl<$Res, _$MealPlanImpl>
    implements _$$MealPlanImplCopyWith<$Res> {
  __$$MealPlanImplCopyWithImpl(
      _$MealPlanImpl _value, $Res Function(_$MealPlanImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? title = null,
    Object? items = null,
    Object? targetCalories = null,
  }) {
    return _then(_$MealPlanImpl(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as MealType,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<MealPlanItem>,
      targetCalories: null == targetCalories
          ? _value.targetCalories
          : targetCalories // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MealPlanImpl implements _MealPlan {
  const _$MealPlanImpl(
      {required this.type,
      required this.title,
      required final List<MealPlanItem> items,
      required this.targetCalories})
      : _items = items;

  factory _$MealPlanImpl.fromJson(Map<String, dynamic> json) =>
      _$$MealPlanImplFromJson(json);

  @override
  final MealType type;
  @override
  final String title;
  final List<MealPlanItem> _items;
  @override
  List<MealPlanItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final int targetCalories;

  @override
  String toString() {
    return 'MealPlan(type: $type, title: $title, items: $items, targetCalories: $targetCalories)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MealPlanImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.title, title) || other.title == title) &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.targetCalories, targetCalories) ||
                other.targetCalories == targetCalories));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, type, title,
      const DeepCollectionEquality().hash(_items), targetCalories);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MealPlanImplCopyWith<_$MealPlanImpl> get copyWith =>
      __$$MealPlanImplCopyWithImpl<_$MealPlanImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MealPlanImplToJson(
      this,
    );
  }
}

abstract class _MealPlan implements MealPlan {
  const factory _MealPlan(
      {required final MealType type,
      required final String title,
      required final List<MealPlanItem> items,
      required final int targetCalories}) = _$MealPlanImpl;

  factory _MealPlan.fromJson(Map<String, dynamic> json) =
      _$MealPlanImpl.fromJson;

  @override
  MealType get type;
  @override
  String get title;
  @override
  List<MealPlanItem> get items;
  @override
  int get targetCalories;
  @override
  @JsonKey(ignore: true)
  _$$MealPlanImplCopyWith<_$MealPlanImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MealPlanItem _$MealPlanItemFromJson(Map<String, dynamic> json) {
  return _MealPlanItem.fromJson(json);
}

/// @nodoc
mixin _$MealPlanItem {
  FoodItem get food => throw _privateConstructorUsedError;
  double get grams => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MealPlanItemCopyWith<MealPlanItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MealPlanItemCopyWith<$Res> {
  factory $MealPlanItemCopyWith(
          MealPlanItem value, $Res Function(MealPlanItem) then) =
      _$MealPlanItemCopyWithImpl<$Res, MealPlanItem>;
  @useResult
  $Res call({FoodItem food, double grams, String? note});

  $FoodItemCopyWith<$Res> get food;
}

/// @nodoc
class _$MealPlanItemCopyWithImpl<$Res, $Val extends MealPlanItem>
    implements $MealPlanItemCopyWith<$Res> {
  _$MealPlanItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? food = null,
    Object? grams = null,
    Object? note = freezed,
  }) {
    return _then(_value.copyWith(
      food: null == food
          ? _value.food
          : food // ignore: cast_nullable_to_non_nullable
              as FoodItem,
      grams: null == grams
          ? _value.grams
          : grams // ignore: cast_nullable_to_non_nullable
              as double,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $FoodItemCopyWith<$Res> get food {
    return $FoodItemCopyWith<$Res>(_value.food, (value) {
      return _then(_value.copyWith(food: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MealPlanItemImplCopyWith<$Res>
    implements $MealPlanItemCopyWith<$Res> {
  factory _$$MealPlanItemImplCopyWith(
          _$MealPlanItemImpl value, $Res Function(_$MealPlanItemImpl) then) =
      __$$MealPlanItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({FoodItem food, double grams, String? note});

  @override
  $FoodItemCopyWith<$Res> get food;
}

/// @nodoc
class __$$MealPlanItemImplCopyWithImpl<$Res>
    extends _$MealPlanItemCopyWithImpl<$Res, _$MealPlanItemImpl>
    implements _$$MealPlanItemImplCopyWith<$Res> {
  __$$MealPlanItemImplCopyWithImpl(
      _$MealPlanItemImpl _value, $Res Function(_$MealPlanItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? food = null,
    Object? grams = null,
    Object? note = freezed,
  }) {
    return _then(_$MealPlanItemImpl(
      food: null == food
          ? _value.food
          : food // ignore: cast_nullable_to_non_nullable
              as FoodItem,
      grams: null == grams
          ? _value.grams
          : grams // ignore: cast_nullable_to_non_nullable
              as double,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MealPlanItemImpl implements _MealPlanItem {
  const _$MealPlanItemImpl(
      {required this.food, required this.grams, this.note});

  factory _$MealPlanItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$MealPlanItemImplFromJson(json);

  @override
  final FoodItem food;
  @override
  final double grams;
  @override
  final String? note;

  @override
  String toString() {
    return 'MealPlanItem(food: $food, grams: $grams, note: $note)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MealPlanItemImpl &&
            (identical(other.food, food) || other.food == food) &&
            (identical(other.grams, grams) || other.grams == grams) &&
            (identical(other.note, note) || other.note == note));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, food, grams, note);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MealPlanItemImplCopyWith<_$MealPlanItemImpl> get copyWith =>
      __$$MealPlanItemImplCopyWithImpl<_$MealPlanItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MealPlanItemImplToJson(
      this,
    );
  }
}

abstract class _MealPlanItem implements MealPlanItem {
  const factory _MealPlanItem(
      {required final FoodItem food,
      required final double grams,
      final String? note}) = _$MealPlanItemImpl;

  factory _MealPlanItem.fromJson(Map<String, dynamic> json) =
      _$MealPlanItemImpl.fromJson;

  @override
  FoodItem get food;
  @override
  double get grams;
  @override
  String? get note;
  @override
  @JsonKey(ignore: true)
  _$$MealPlanItemImplCopyWith<_$MealPlanItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DailyNutritionPlan _$DailyNutritionPlanFromJson(Map<String, dynamic> json) {
  return _DailyNutritionPlan.fromJson(json);
}

/// @nodoc
mixin _$DailyNutritionPlan {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  double get targetCalories => throw _privateConstructorUsedError;
  double get targetProtein => throw _privateConstructorUsedError;
  double get targetCarbs => throw _privateConstructorUsedError;
  double get targetFat => throw _privateConstructorUsedError;
  List<MealPlan> get meals => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DailyNutritionPlanCopyWith<DailyNutritionPlan> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DailyNutritionPlanCopyWith<$Res> {
  factory $DailyNutritionPlanCopyWith(
          DailyNutritionPlan value, $Res Function(DailyNutritionPlan) then) =
      _$DailyNutritionPlanCopyWithImpl<$Res, DailyNutritionPlan>;
  @useResult
  $Res call(
      {String id,
      String userId,
      DateTime date,
      double targetCalories,
      double targetProtein,
      double targetCarbs,
      double targetFat,
      List<MealPlan> meals});
}

/// @nodoc
class _$DailyNutritionPlanCopyWithImpl<$Res, $Val extends DailyNutritionPlan>
    implements $DailyNutritionPlanCopyWith<$Res> {
  _$DailyNutritionPlanCopyWithImpl(this._value, this._then);

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
    Object? targetCalories = null,
    Object? targetProtein = null,
    Object? targetCarbs = null,
    Object? targetFat = null,
    Object? meals = null,
  }) {
    return _then(_value.copyWith(
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
      targetCalories: null == targetCalories
          ? _value.targetCalories
          : targetCalories // ignore: cast_nullable_to_non_nullable
              as double,
      targetProtein: null == targetProtein
          ? _value.targetProtein
          : targetProtein // ignore: cast_nullable_to_non_nullable
              as double,
      targetCarbs: null == targetCarbs
          ? _value.targetCarbs
          : targetCarbs // ignore: cast_nullable_to_non_nullable
              as double,
      targetFat: null == targetFat
          ? _value.targetFat
          : targetFat // ignore: cast_nullable_to_non_nullable
              as double,
      meals: null == meals
          ? _value.meals
          : meals // ignore: cast_nullable_to_non_nullable
              as List<MealPlan>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DailyNutritionPlanImplCopyWith<$Res>
    implements $DailyNutritionPlanCopyWith<$Res> {
  factory _$$DailyNutritionPlanImplCopyWith(_$DailyNutritionPlanImpl value,
          $Res Function(_$DailyNutritionPlanImpl) then) =
      __$$DailyNutritionPlanImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      DateTime date,
      double targetCalories,
      double targetProtein,
      double targetCarbs,
      double targetFat,
      List<MealPlan> meals});
}

/// @nodoc
class __$$DailyNutritionPlanImplCopyWithImpl<$Res>
    extends _$DailyNutritionPlanCopyWithImpl<$Res, _$DailyNutritionPlanImpl>
    implements _$$DailyNutritionPlanImplCopyWith<$Res> {
  __$$DailyNutritionPlanImplCopyWithImpl(_$DailyNutritionPlanImpl _value,
      $Res Function(_$DailyNutritionPlanImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? date = null,
    Object? targetCalories = null,
    Object? targetProtein = null,
    Object? targetCarbs = null,
    Object? targetFat = null,
    Object? meals = null,
  }) {
    return _then(_$DailyNutritionPlanImpl(
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
      targetCalories: null == targetCalories
          ? _value.targetCalories
          : targetCalories // ignore: cast_nullable_to_non_nullable
              as double,
      targetProtein: null == targetProtein
          ? _value.targetProtein
          : targetProtein // ignore: cast_nullable_to_non_nullable
              as double,
      targetCarbs: null == targetCarbs
          ? _value.targetCarbs
          : targetCarbs // ignore: cast_nullable_to_non_nullable
              as double,
      targetFat: null == targetFat
          ? _value.targetFat
          : targetFat // ignore: cast_nullable_to_non_nullable
              as double,
      meals: null == meals
          ? _value._meals
          : meals // ignore: cast_nullable_to_non_nullable
              as List<MealPlan>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DailyNutritionPlanImpl implements _DailyNutritionPlan {
  const _$DailyNutritionPlanImpl(
      {required this.id,
      required this.userId,
      required this.date,
      required this.targetCalories,
      required this.targetProtein,
      required this.targetCarbs,
      required this.targetFat,
      required final List<MealPlan> meals})
      : _meals = meals;

  factory _$DailyNutritionPlanImpl.fromJson(Map<String, dynamic> json) =>
      _$$DailyNutritionPlanImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final DateTime date;
  @override
  final double targetCalories;
  @override
  final double targetProtein;
  @override
  final double targetCarbs;
  @override
  final double targetFat;
  final List<MealPlan> _meals;
  @override
  List<MealPlan> get meals {
    if (_meals is EqualUnmodifiableListView) return _meals;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_meals);
  }

  @override
  String toString() {
    return 'DailyNutritionPlan(id: $id, userId: $userId, date: $date, targetCalories: $targetCalories, targetProtein: $targetProtein, targetCarbs: $targetCarbs, targetFat: $targetFat, meals: $meals)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DailyNutritionPlanImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.targetCalories, targetCalories) ||
                other.targetCalories == targetCalories) &&
            (identical(other.targetProtein, targetProtein) ||
                other.targetProtein == targetProtein) &&
            (identical(other.targetCarbs, targetCarbs) ||
                other.targetCarbs == targetCarbs) &&
            (identical(other.targetFat, targetFat) ||
                other.targetFat == targetFat) &&
            const DeepCollectionEquality().equals(other._meals, _meals));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      date,
      targetCalories,
      targetProtein,
      targetCarbs,
      targetFat,
      const DeepCollectionEquality().hash(_meals));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DailyNutritionPlanImplCopyWith<_$DailyNutritionPlanImpl> get copyWith =>
      __$$DailyNutritionPlanImplCopyWithImpl<_$DailyNutritionPlanImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DailyNutritionPlanImplToJson(
      this,
    );
  }
}

abstract class _DailyNutritionPlan implements DailyNutritionPlan {
  const factory _DailyNutritionPlan(
      {required final String id,
      required final String userId,
      required final DateTime date,
      required final double targetCalories,
      required final double targetProtein,
      required final double targetCarbs,
      required final double targetFat,
      required final List<MealPlan> meals}) = _$DailyNutritionPlanImpl;

  factory _DailyNutritionPlan.fromJson(Map<String, dynamic> json) =
      _$DailyNutritionPlanImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  DateTime get date;
  @override
  double get targetCalories;
  @override
  double get targetProtein;
  @override
  double get targetCarbs;
  @override
  double get targetFat;
  @override
  List<MealPlan> get meals;
  @override
  @JsonKey(ignore: true)
  _$$DailyNutritionPlanImplCopyWith<_$DailyNutritionPlanImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
