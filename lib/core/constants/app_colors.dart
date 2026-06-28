import 'package:flutter/material.dart';

/// Semantic color constants — use these instead of hardcoded `Color(0x...)` values.
/// For theme-adaptive colors, use `AppTheme.of(context)` / `ThemePalette`.
class SemanticColors {
  SemanticColors._();

  // ── Muscle visualization ──────────────────────────────────────────────────
  static const primaryMuscle   = Color(0xFFE8453C); // red — primary muscles, errors
  static const secondaryMuscle = Color(0xFF4FA3E0); // blue — secondary muscles, info
  static const tapHighlight    = Color(0xFFFFB300); // amber — tap/highlight zone
  static const muscleOverlay   = Color(0x55FFFFFF); // white 33% — map overlay

  // ── Technique & workout ───────────────────────────────────────────────────
  static const technique       = Color(0xFFFF9500); // orange — technique cues
  static const progression     = Color(0xFF4CAF50); // green — progression, success
  static const weightGuideline = Color(0xFF4FA3E0); // blue — weight loading

  // ── Difficulty levels ─────────────────────────────────────────────────────
  static const difficultyBeginner    = Color(0xFF22D3A5); // green
  static const difficultyIntermediate = Color(0xFFF5A623); // amber
  static const difficultyAdvanced    = Color(0xFFFF4466); // red

  // ── Import workflow ───────────────────────────────────────────────────────
  static const importSuccess  = Color(0xFF4CAF50); // green — success
  static const importWarning  = Color(0xFFFF9500); // orange — warning
  static const importInfo     = Color(0xFF4FA3E0); // blue — info
  static const importFlex     = Color(0xFFAB47BC); // purple — flexibility
  static const importError    = Color(0xFFE84444); // red — error
  static const importWater    = Color(0xFF26C6DA); // cyan — water/sync

  // ── Dashboard cards ───────────────────────────────────────────────────────
  static const cardioRed      = Color(0xFFEF4444); // red — cardio indicator
  static const featurePill    = Color(0xFF3D5AFE); // indigo — feature pills
  static const cardDark       = Color(0xFF1A2A3A); // dark bg — card gradient
  static const cardDarker     = Color(0xFF0A1826); // darker bg — card gradient

  // ── Misc ──────────────────────────────────────────────────────────────────
  static const googleBlue     = Color(0xFF4285F4); // Google sign-in blue
}
