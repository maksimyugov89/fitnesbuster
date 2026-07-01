// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nutrition_entities.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NutritionPer100gImpl _$$NutritionPer100gImplFromJson(
  Map<String, dynamic> json,
) => _$NutritionPer100gImpl(
  calories: (json['calories'] as num).toDouble(),
  protein: (json['protein'] as num).toDouble(),
  carbs: (json['carbs'] as num).toDouble(),
  fat: (json['fat'] as num).toDouble(),
  fiber: (json['fiber'] as num?)?.toDouble(),
  sugar: (json['sugar'] as num?)?.toDouble(),
  sodium: (json['sodium'] as num?)?.toDouble(),
);

Map<String, dynamic> _$$NutritionPer100gImplToJson(
  _$NutritionPer100gImpl instance,
) => <String, dynamic>{
  'calories': instance.calories,
  'protein': instance.protein,
  'carbs': instance.carbs,
  'fat': instance.fat,
  'fiber': instance.fiber,
  'sugar': instance.sugar,
  'sodium': instance.sodium,
};

_$FoodItemImpl _$$FoodItemImplFromJson(Map<String, dynamic> json) =>
    _$FoodItemImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      barcode: json['barcode'] as String?,
      nutrition: NutritionPer100g.fromJson(
        json['nutrition'] as Map<String, dynamic>,
      ),
      imageUrl: json['imageUrl'] as String?,
    );

Map<String, dynamic> _$$FoodItemImplToJson(_$FoodItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'brand': instance.brand,
      'barcode': instance.barcode,
      'nutrition': instance.nutrition,
      'imageUrl': instance.imageUrl,
    };

_$FoodEntryImpl _$$FoodEntryImplFromJson(Map<String, dynamic> json) =>
    _$FoodEntryImpl(
      food: FoodItem.fromJson(json['food'] as Map<String, dynamic>),
      grams: (json['grams'] as num).toDouble(),
    );

Map<String, dynamic> _$$FoodEntryImplToJson(_$FoodEntryImpl instance) =>
    <String, dynamic>{'food': instance.food, 'grams': instance.grams};

_$MealLogImpl _$$MealLogImplFromJson(Map<String, dynamic> json) =>
    _$MealLogImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      date: DateTime.parse(json['date'] as String),
      mealType: $enumDecode(_$MealTypeEnumMap, json['mealType']),
      foods: (json['foods'] as List<dynamic>)
          .map((e) => FoodEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$MealLogImplToJson(_$MealLogImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'date': instance.date.toIso8601String(),
      'mealType': _$MealTypeEnumMap[instance.mealType]!,
      'foods': instance.foods,
    };

const _$MealTypeEnumMap = {
  MealType.breakfast: 'breakfast',
  MealType.lunch: 'lunch',
  MealType.dinner: 'dinner',
  MealType.snack: 'snack',
};

_$MealPlanImpl _$$MealPlanImplFromJson(Map<String, dynamic> json) =>
    _$MealPlanImpl(
      type: $enumDecode(_$MealTypeEnumMap, json['type']),
      title: json['title'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => MealPlanItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      targetCalories: (json['targetCalories'] as num).toInt(),
    );

Map<String, dynamic> _$$MealPlanImplToJson(_$MealPlanImpl instance) =>
    <String, dynamic>{
      'type': _$MealTypeEnumMap[instance.type]!,
      'title': instance.title,
      'items': instance.items,
      'targetCalories': instance.targetCalories,
    };

_$MealPlanItemImpl _$$MealPlanItemImplFromJson(Map<String, dynamic> json) =>
    _$MealPlanItemImpl(
      food: FoodItem.fromJson(json['food'] as Map<String, dynamic>),
      grams: (json['grams'] as num).toDouble(),
      note: json['note'] as String?,
    );

Map<String, dynamic> _$$MealPlanItemImplToJson(_$MealPlanItemImpl instance) =>
    <String, dynamic>{
      'food': instance.food,
      'grams': instance.grams,
      'note': instance.note,
    };

_$DailyNutritionPlanImpl _$$DailyNutritionPlanImplFromJson(
  Map<String, dynamic> json,
) => _$DailyNutritionPlanImpl(
  id: json['id'] as String,
  userId: json['userId'] as String,
  date: DateTime.parse(json['date'] as String),
  targetCalories: (json['targetCalories'] as num).toDouble(),
  targetProtein: (json['targetProtein'] as num).toDouble(),
  targetCarbs: (json['targetCarbs'] as num).toDouble(),
  targetFat: (json['targetFat'] as num).toDouble(),
  meals: (json['meals'] as List<dynamic>)
      .map((e) => MealPlan.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$$DailyNutritionPlanImplToJson(
  _$DailyNutritionPlanImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'date': instance.date.toIso8601String(),
  'targetCalories': instance.targetCalories,
  'targetProtein': instance.targetProtein,
  'targetCarbs': instance.targetCarbs,
  'targetFat': instance.targetFat,
  'meals': instance.meals,
};
