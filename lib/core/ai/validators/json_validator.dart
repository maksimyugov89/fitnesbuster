import 'dart:convert';
import 'package:fitnesbuster/core/ai/ai_exception.dart';
import 'package:fitnesbuster/core/utils/app_logger.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';

/// Strips markdown code fences from AI JSON responses.
String extractJson(String response) {
  final trimmed = response.trim();
  final full = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(trimmed);
  String body;
  if (full != null) {
    body = full.group(1)!.trim();
  } else {
    final open = RegExp(r'^```(?:json)?\s*').firstMatch(trimmed);
    if (open != null) {
      body = trimmed.substring(open.end).trim();
    } else {
      body = trimmed;
    }
  }
  final objEnd = body.lastIndexOf('}');
  final arrEnd = body.lastIndexOf(']');
  final lastJsonChar = objEnd > arrEnd ? objEnd : arrEnd;
  if (lastJsonChar >= 0 && lastJsonChar < body.length - 1) {
    body = body.substring(0, lastJsonChar + 1);
  }
  try {
    jsonDecode(body);
  } catch (_) {}
  return body;
}

/// Validates workout plan JSON structure. Ensures `plan` list exists and normalizes fields.
String validateWorkoutJson(String raw) {
  Map<String, dynamic> data;
  try {
    data = jsonDecode(raw) as Map<String, dynamic>;
  } catch (e) {
    appLogger.d('[DeepSeek] Malformed workout JSON: $raw', error: e);
    throw AiException(AppLocalizations.tl('aiInvalidWorkoutJson'));
  }

  final plan = data['plan'];
  if (plan == null || plan is! List || plan.isEmpty) {
    appLogger.d('[DeepSeek] Missing or empty "plan" in workout JSON: $raw');
    throw AiException(AppLocalizations.tl('aiWorkoutPlanMissing'));
  }

  for (final item in plan) {
    if (item is! Map<String, dynamic>) continue;
    item['focus'] ??= item['name'] ?? '';
    if (item['exercises'] is! List) item['exercises'] = <dynamic>[];
  }

  return jsonEncode(data);
}

/// Validates meal plan JSON structure. Ensures `meals` list, bridges field renames.
String validateMealJson(String raw) {
  Map<String, dynamic> data;
  try {
    data = jsonDecode(raw) as Map<String, dynamic>;
  } catch (e) {
    appLogger.d('[DeepSeek] Malformed meal JSON: $raw', error: e);
    throw AiException(AppLocalizations.tl('aiInvalidMealJson'));
  }

  final meals = data['meals'];
  if (meals == null || meals is! List || meals.isEmpty) {
    appLogger.d('[DeepSeek] Missing "meals" in meal JSON: $raw');
    throw AiException(AppLocalizations.tl('aiMealPlanMissing'));
  }

  data['calories'] ??= data['total_calories'] ?? 0;
  data['recommendations'] ??= data['daily_tips'] ?? '';
  data['water_target_ml'] ??= data['daily_targets']?['water_ml'] ?? 2500;

  for (final meal in meals) {
    if (meal is! Map<String, dynamic>) continue;
    final foods = meal['foods'];
    if (foods is List) {
      final flat = <String>[];
      for (final f in foods) {
        if (f is String) {
          flat.add(f);
        } else if (f is Map<String, dynamic>) {
          flat.add(f['name'] as String? ?? f.toString());
        }
      }
      meal['foods'] = flat;
    }
    meal['type'] ??=
        meal['meal_type'] ?? AppLocalizations.tl('mealTypeFallback');
  }

  return jsonEncode(data);
}
