import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/theme/app_images.dart';

class AvatarPreset {
  final String iconAsset;
  final String label;
  final List<Color> gradientColors;
  const AvatarPreset(this.iconAsset, this.label, this.gradientColors);
}

const kAvatarPresets = [
  AvatarPreset(AppImages.workoutsTab, 'Атлет', [
    Color(0xFF6C63FF),
    Color(0xFF3D5AFE),
  ]),
  AvatarPreset(AppImages.steps, 'Бегун', [
    Color(0xFF00BFA5),
    Color(0xFF00695C),
  ]),
  AvatarPreset(AppImages.yoga, 'Йога', [Color(0xFFAB47BC), Color(0xFF6A1B9A)]),
  AvatarPreset(AppImages.cycling, 'Велосипед', [
    Color(0xFFFF7043),
    Color(0xFFBF360C),
  ]),
  AvatarPreset(AppImages.boxing, 'Бокс', [
    Color(0xFFEF5350),
    Color(0xFFB71C1C),
  ]),
  AvatarPreset(AppImages.swimming, 'Плавание', [
    Color(0xFF29B6F6),
    Color(0xFF01579B),
  ]),
  AvatarPreset(AppImages.climbing, 'Скалолаз', [
    Color(0xFFFFCA28),
    Color(0xFFE65100),
  ]),
  AvatarPreset(AppImages.gymnastics, 'Гимнастика', [
    Color(0xFFEC407A),
    Color(0xFF880E4F),
  ]),
  AvatarPreset(AppImages.energy, 'Энергия', [
    Color(0xFF26C6DA),
    Color(0xFF006064),
  ]),
  AvatarPreset(AppImages.achievements, 'Чемпион', [
    Color(0xFF66BB6A),
    Color(0xFF1B5E20),
  ]),
];
