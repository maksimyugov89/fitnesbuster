import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/core/theme/app_images.dart';

const mealIcons = {
  'breakfast': AppImages.breakfast,
  'lunch': AppImages.lunch,
  'dinner': AppImages.dinner,
  'snack': AppImages.snack,
  'pre_workout': AppImages.workoutsTab,
  'post_workout': AppImages.energy,
  'evening_snack': AppImages.dinner,
  'morning_snack': AppImages.snack,
};

Map<String, String> localizedMealLabels() => {
  'breakfast': AppLocalizations.tl('breakfast'),
  'lunch': AppLocalizations.tl('lunch'),
  'dinner': AppLocalizations.tl('dinner'),
  'snack': AppLocalizations.tl('snack'),
  'pre_workout': AppLocalizations.tl('mealPreWorkout'),
  'post_workout': AppLocalizations.tl('mealPostWorkout'),
  'evening_snack': AppLocalizations.tl('mealEveningSnack'),
  'morning_snack': AppLocalizations.tl('mealMorningSnack'),
};

const mealColors = {
  'breakfast': Color(0xFFFFAB40),
  'lunch': Color(0xFF26C6DA),
  'dinner': Color(0xFF7E57C2),
  'snack': Color(0xFF66BB6A),
  'pre_workout': Color(0xFFEF5350),
  'post_workout': Color(0xFFFF7043),
  'evening_snack': Color(0xFFAB47BC),
  'morning_snack': Color(0xFF42A5F5),
};
