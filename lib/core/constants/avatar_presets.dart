import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/theme/app_images.dart';

class AvatarPreset {
  final String iconAsset;
  final String labelKey;
  final List<Color> gradientColors;
  const AvatarPreset(this.iconAsset, this.labelKey, this.gradientColors);
}

const kAvatarPresets = [
  AvatarPreset(AppImages.workoutsTab, 'avatarPresetAthlete', [
    Color(0xFF6C63FF),
    Color(0xFF3D5AFE),
  ]),
  AvatarPreset(AppImages.steps, 'avatarPresetRunner', [
    Color(0xFF00BFA5),
    Color(0xFF00695C),
  ]),
  AvatarPreset(AppImages.yoga, 'avatarPresetYoga', [
    Color(0xFFAB47BC),
    Color(0xFF6A1B9A),
  ]),
  AvatarPreset(AppImages.cycling, 'avatarPresetCycling', [
    Color(0xFFFF7043),
    Color(0xFFBF360C),
  ]),
  AvatarPreset(AppImages.boxing, 'avatarPresetBoxing', [
    Color(0xFFEF5350),
    Color(0xFFB71C1C),
  ]),
  AvatarPreset(AppImages.swimming, 'avatarPresetSwimming', [
    Color(0xFF29B6F6),
    Color(0xFF01579B),
  ]),
  AvatarPreset(AppImages.climbing, 'avatarPresetClimber', [
    Color(0xFFFFCA28),
    Color(0xFFE65100),
  ]),
  AvatarPreset(AppImages.gymnastics, 'avatarPresetGymnastics', [
    Color(0xFFEC407A),
    Color(0xFF880E4F),
  ]),
  AvatarPreset(AppImages.energy, 'avatarPresetEnergy', [
    Color(0xFF26C6DA),
    Color(0xFF006064),
  ]),
  AvatarPreset(AppImages.achievements, 'avatarPresetChampion', [
    Color(0xFF66BB6A),
    Color(0xFF1B5E20),
  ]),
];
