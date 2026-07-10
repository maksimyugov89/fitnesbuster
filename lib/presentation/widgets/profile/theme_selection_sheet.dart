import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/theme/theme_service.dart';

/// Bottom sheet for selecting app theme from 5 gradient-based themes.
class ThemeSelectionSheet extends StatefulWidget {
  const ThemeSelectionSheet({super.key});

  @override
  State<ThemeSelectionSheet> createState() => _ThemeSelectionSheetState();
}

class _ThemeSelectionSheetState extends State<ThemeSelectionSheet> {
  late AppThemeMode _selected;

  @override
  void initState() {
    super.initState();
    _selected = ThemeService.current;
  }

  Color _previewColor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.neonDark:
        return const Color(0xFFD4F53C);
      case AppThemeMode.oceanBlue:
        return const Color(0xFF00B4D8);
      case AppThemeMode.sunsetWarm:
        return const Color(0xFFFF6B35);
      case AppThemeMode.forestGreen:
        return const Color(0xFF2ECC71);
      case AppThemeMode.midnightPurple:
        return const Color(0xFF9B59B6);
      case AppThemeMode.cyberPunk:
        return const Color(0xFF00F0FF);
    }
  }

  List<Color> _gradientColors(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.neonDark:
        return const [Color(0xFFD4F53C), Color(0xFF0A0A0A)];
      case AppThemeMode.oceanBlue:
        return const [Color(0xFF00B4D8), Color(0xFF030B18)];
      case AppThemeMode.sunsetWarm:
        return const [Color(0xFFFF6B35), Color(0xFF0D0604)];
      case AppThemeMode.forestGreen:
        return const [Color(0xFF2ECC71), Color(0xFF040D04)];
      case AppThemeMode.midnightPurple:
        return const [Color(0xFF9B59B6), Color(0xFF06030D)];
      case AppThemeMode.cyberPunk:
        return const [Color(0xFF00F0FF), Color(0xFF050510)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.surfaceLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Выбор темы', style: AppTextStyles.titleL),
          const SizedBox(height: 4),
          Text(
            '5 уникальных тем с градиентами',
            style: TextStyle(fontSize: 13, color: colors.textMuted),
          ),
          const SizedBox(height: 20),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: AppThemeMode.values.length,
              itemBuilder: (_, i) {
                final mode = AppThemeMode.values[i];
                final isSelected = _selected == mode;
                final gradientColors = _gradientColors(mode);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Semantics(
                    label: '${mode.displayName} — ${mode.description}',
                    button: true,
                    child: GestureDetector(
                      onTap: () async {
                        HapticFeedback.mediumImpact();
                        setState(() => _selected = mode);
                        await ThemeService.setTheme(mode);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Тема "${mode.displayName}" применена',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              backgroundColor: _previewColor(mode),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? _previewColor(mode)
                                : Colors.white.withValues(alpha: 0.1),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: _previewColor(
                                      mode,
                                    ).withValues(alpha: 0.3),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            Image.asset(mode.iconAsset, width: 36, height: 36),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mode.displayName,
                                    style: const TextStyle(
                                      fontFamily: 'Syne',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    mode.description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withValues(
                                        alpha: 0.75,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check_rounded,
                                  color: _previewColor(mode),
                                  size: 18,
                                ),
                              )
                            else
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    width: 2,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
