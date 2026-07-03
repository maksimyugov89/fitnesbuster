import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fitnesbuster/bloc/onboarding/onboarding_bloc.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/core/utils/age_calculator.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});
  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen>
    with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _page = 0;
  late AnimationController _fadeCtrl;

  String _name = '';
  DateTime _dateOfBirth = DateTime.now().subtract(
    const Duration(days: 365 * 25),
  );
  double _weight = 75.0;
  double _height = 175.0;
  Gender _gender = Gender.male;
  ActivityLevel _activity = ActivityLevel.moderatelyActive;
  final List<String> _restrictions = [];
  String _city = '';

  final List<String> _commonRestrictions = const [
    'Аллергия на орехи',
    'Непереносимость лактозы',
    'Без глютена',
    'Вегетарианец',
    'Без красного мяса',
    'Диабетическая диета',
    'Низкое содержание соли',
    'Веган',
    'Кето',
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 4) {
      HapticFeedback.lightImpact();
      _fadeCtrl.reverse().then((_) {
        _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        setState(() => _page++);
        _fadeCtrl.forward();
      });
    } else {
      context.read<OnboardingBloc>().add(
        OnboardingSetProfile(
          name: _name,
          dateOfBirth: _dateOfBirth,
          weight: _weight,
          height: _height,
          gender: _gender,
          activity: _activity,
          restrictions: _restrictions,
          city: _city,
        ),
      );
      context.read<OnboardingBloc>().add(const OnboardingFinalize());
    }
  }

  void _back() {
    if (_page > 0) {
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => _page--);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return BlocListener<OnboardingBloc, OnboardingState>(
      listener: (context, state) {
        if (state is OnboardingComplete) {
          context.go('/dashboard');
        } else if (state is OnboardingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: BlocBuilder<OnboardingBloc, OnboardingState>(
          builder: (context, state) {
            final loading =
                state is OnboardingGeneratingPlan || state is OnboardingSaving;
            return Stack(
              children: [
                SafeArea(
                  child: Column(
                    children: [
                      _topBar(colors),
                      Expanded(
                        child: PageView(
                          controller: _pageCtrl,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _PageBasicInfo(
                              name: _name,
                              dateOfBirth: _dateOfBirth,
                              gender: _gender,
                              onNameChanged: (v) => setState(() => _name = v),
                              onDateOfBirthChanged: (v) =>
                                  setState(() => _dateOfBirth = v),
                              onGenderChanged: (v) =>
                                  setState(() => _gender = v),
                            ),
                            _PageBodyStats(
                              weight: _weight,
                              height: _height,
                              onWeightChanged: (v) =>
                                  setState(() => _weight = v),
                              onHeightChanged: (v) =>
                                  setState(() => _height = v),
                            ),
                            _PageActivity(
                              activity: _activity,
                              onChanged: (v) => setState(() => _activity = v),
                            ),
                            _PageRestrictions(
                              restrictions: _restrictions,
                              commonRestrictions: _commonRestrictions,
                              onToggle: (r) => setState(() {
                                if (_restrictions.contains(r)) {
                                  _restrictions.remove(r);
                                } else {
                                  _restrictions.add(r);
                                }
                              }),
                            ),
                            _PageCity(
                              city: _city,
                              onChanged: (v) => setState(() => _city = v),
                            ),
                          ],
                        ),
                      ),
                      _bottomArea(colors),
                    ],
                  ),
                ),
                if (loading)
                  const Positioned.fill(child: _AiGeneratingOverlay()),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _topBar(dynamic colors) {
    final l10n = context.l10n;
    final titles = [
      l10n.step1About,
      l10n.step2Params,
      l10n.step3Activity,
      l10n.step4Restrictions,
      l10n.step5Location,
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _back,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: colors.textPrimary,
                    size: 20,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${_page + 1} of 5',
                style: TextStyle(color: colors.textMuted, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_page + 1) / 5,
              backgroundColor: colors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(titles[_page], style: AppTextStyles.displayM),
          ),
        ],
      ),
    );
  }

  Widget _bottomArea(dynamic colors) {
    final l10n = context.l10n;
    final labels = [
      l10n.continueLabel,
      l10n.continueLabel,
      l10n.continueLabel,
      l10n.continueLabel,
      l10n.startProgramBtn,
    ];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _next,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.textPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            labels[_page],
            style: const TextStyle(
              fontFamily: 'Syne',
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// Page 1: Basic Info
class _PageBasicInfo extends StatelessWidget {
  final String name;
  final DateTime dateOfBirth;
  final Gender gender;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<DateTime> onDateOfBirthChanged;
  final ValueChanged<Gender> onGenderChanged;

  const _PageBasicInfo({
    required this.name,
    required this.dateOfBirth,
    required this.gender,
    required this.onNameChanged,
    required this.onDateOfBirthChanged,
    required this.onGenderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _InputField(
            label: context.l10n.nameFieldLabel,
            hint: context.l10n.nameHint,
            icon: Icons.person_outline_rounded,
            onChanged: onNameChanged,
          ),
          const SizedBox(height: 20),
          _GenderSelector(selected: gender, onChanged: onGenderChanged),
          const SizedBox(height: 20),
          _DateOfBirthField(
            dateOfBirth: dateOfBirth,
            onChanged: onDateOfBirthChanged,
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label, hint;
  final IconData icon;
  final ValueChanged<String> onChanged;

  const _InputField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelL),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.textPrimary.withValues(alpha: 0.06),
            ),
          ),
          child: TextField(
            onChanged: onChanged,
            style: TextStyle(color: colors.textPrimary, fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: colors.textMuted),
              prefixIcon: Icon(icon, color: colors.textMuted, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GenderSelector extends StatelessWidget {
  final Gender selected;
  final ValueChanged<Gender> onChanged;
  const _GenderSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.onbGenderTitle, style: AppTextStyles.labelL),
        const SizedBox(height: 10),
        Row(
          children: [
            _GenderCard(
              label: context.l10n.genderMale,
              emoji: '♂',
              gender: Gender.male,
              selected: selected,
              onTap: onChanged,
            ),
            const SizedBox(width: 12),
            _GenderCard(
              label: context.l10n.genderFemale,
              emoji: '♀',
              gender: Gender.female,
              selected: selected,
              onTap: onChanged,
            ),
          ],
        ),
      ],
    );
  }
}

class _GenderCard extends StatelessWidget {
  final String label, emoji;
  final Gender gender, selected;
  final ValueChanged<Gender> onTap;
  const _GenderCard({
    required this.label,
    required this.emoji,
    required this.gender,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final isSel = gender == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap(gender);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 80,
          decoration: BoxDecoration(
            color: isSel
                ? colors.primary.withValues(alpha: 0.15)
                : colors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSel
                  ? colors.primary
                  : colors.textPrimary.withValues(alpha: 0.06),
              width: isSel ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSel ? colors.primary : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateOfBirthField extends StatelessWidget {
  final DateTime dateOfBirth;
  final ValueChanged<DateTime> onChanged;
  const _DateOfBirthField({required this.dateOfBirth, required this.onChanged});

  Future<void> _pick(BuildContext context, ThemePalette colors) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: dateOfBirth,
      firstDate: now.subtract(const Duration(days: 365 * 80)),
      lastDate: now.subtract(const Duration(days: 365 * 14)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: colors.primary,
            surface: colors.surfaceCard,
            onSurface: colors.textPrimary,
          ),
          dialogTheme: DialogThemeData(backgroundColor: colors.surfaceCard),
        ),
        child: child!,
      ),
    );
    if (picked != null) onChanged(picked);
  }

  String _format(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final age = calculateAge(dateOfBirth);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.onbAgeTitle, style: AppTextStyles.labelL),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => _pick(context, colors),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.textPrimary.withValues(alpha: 0.06),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(Icons.cake_outlined, color: colors.textMuted, size: 20),
                const SizedBox(width: 14),
                Text(
                  _format(dateOfBirth),
                  style: TextStyle(color: colors.textPrimary, fontSize: 16),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$age',
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Page 2: Body Stats
class _PageBodyStats extends StatelessWidget {
  final double weight, height;
  final ValueChanged<double> onWeightChanged, onHeightChanged;
  const _PageBodyStats({
    required this.weight,
    required this.height,
    required this.onWeightChanged,
    required this.onHeightChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _NumericSlider(
            label: context.l10n.onbWeightTitle,
            value: weight,
            min: 40,
            max: 200,
            unit: 'kg',
            onChanged: onWeightChanged,
          ),
          const SizedBox(height: 28),
          _NumericSlider(
            label: context.l10n.onbHeightTitle,
            value: height,
            min: 140,
            max: 220,
            unit: 'cm',
            onChanged: onHeightChanged,
          ),
          const SizedBox(height: 28),
          _BmiCard(weight: weight, height: height),
        ],
      ),
    );
  }
}

class _NumericSlider extends StatelessWidget {
  final String label, unit;
  final double value, min, max;
  final ValueChanged<double> onChanged;
  const _NumericSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: AppTextStyles.labelL),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${value.toStringAsFixed(1)} $unit',
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: colors.primary,
            inactiveTrackColor: colors.surfaceLight,
            thumbColor: colors.primary,
            overlayColor: colors.primary.withValues(alpha: 0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            trackHeight: 6,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) * 2).round(),
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${min.toInt()} $unit',
              style: TextStyle(fontSize: 11, color: colors.textMuted),
            ),
            Text(
              '${max.toInt()} $unit',
              style: TextStyle(fontSize: 11, color: colors.textMuted),
            ),
          ],
        ),
      ],
    );
  }
}

class _BmiCard extends StatelessWidget {
  final double weight, height;
  const _BmiCard({required this.weight, required this.height});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final bmi = height > 0 ? weight / ((height / 100) * (height / 100)) : 0;
    String category;
    Color bmiColor;
    final l10n = context.l10n;
    if (bmi < 18.5) {
      category = l10n.bmiUnderweight;
      bmiColor = colors.info;
    } else if (bmi < 25) {
      category = l10n.bmiNormal;
      bmiColor = colors.success;
    } else if (bmi < 30) {
      category = l10n.bmiOverweight;
      bmiColor = colors.warning;
    } else {
      category = l10n.bmiObese;
      bmiColor = colors.error;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bmiColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bmiColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.bmiTitle,
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                bmi.toStringAsFixed(1),
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: bmiColor,
                ),
              ),
              Text(
                category,
                style: TextStyle(
                  color: bmiColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const Spacer(),
          Icon(Icons.monitor_weight_outlined, color: bmiColor, size: 48),
        ],
      ),
    );
  }
}

// Page 3: Activity
class _PageActivity extends StatelessWidget {
  final ActivityLevel activity;
  final ValueChanged<ActivityLevel> onChanged;
  const _PageActivity({required this.activity, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: ActivityLevel.values.map((lvl) {
          final isSel = activity == lvl;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(lvl);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSel
                      ? colors.primary.withValues(alpha: 0.1)
                      : colors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSel
                        ? colors.primary
                        : colors.textPrimary.withValues(alpha: 0.06),
                    width: isSel ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSel ? colors.primary : colors.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          _emoji(lvl),
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        lvl.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSel ? colors.primary : colors.textSecondary,
                        ),
                      ),
                    ),
                    if (isSel)
                      Icon(
                        Icons.check_circle_rounded,
                        color: colors.primary,
                        size: 22,
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _emoji(ActivityLevel l) {
    switch (l) {
      case ActivityLevel.sedentary:
        return '🪑';
      case ActivityLevel.lightlyActive:
        return '🚶';
      case ActivityLevel.moderatelyActive:
        return '🏃';
      case ActivityLevel.veryActive:
        return '🔥';
      case ActivityLevel.extraActive:
        return '⚡';
    }
  }
}

// Page 5: City / Location
class _PageCity extends StatefulWidget {
  final String city;
  final ValueChanged<String> onChanged;
  const _PageCity({required this.city, required this.onChanged});

  @override
  State<_PageCity> createState() => _PageCityState();
}

class _PageCityState extends State<_PageCity> {
  late final TextEditingController _ctrl;
  bool _detecting = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.city);
    _ctrl.addListener(() => widget.onChanged(_ctrl.text.trim()));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _detectCity() async {
    setState(() {
      _detecting = true;
      _errorMsg = null;
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMsg = context.l10n.geoDisabledMsg;
          _detecting = false;
        });
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMsg = context.l10n.geoPermissionDeniedMsg;
          _detecting = false;
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=${pos.latitude}&lon=${pos.longitude}&format=json&accept-language=ru',
      );
      final resp = await http
          .get(uri, headers: {'User-Agent': 'FitnesBuster/1.0'})
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final addr = data['address'] as Map<String, dynamic>?;
        final city =
            addr?['city'] as String? ??
            addr?['town'] as String? ??
            addr?['village'] as String? ??
            addr?['municipality'] as String? ??
            addr?['county'] as String?;
        if (city != null && city.isNotEmpty) {
          _ctrl.text = city;
          widget.onChanged(city);
          setState(() {
            _detecting = false;
          });
          return;
        }
      }
      setState(() {
        _errorMsg = context.l10n.geoCityNotFoundMsg;
        _detecting = false;
      });
    } catch (_) {
      setState(() {
        _errorMsg = context.l10n.geoErrorMsg;
        _detecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.locationNote,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 20),

          // Auto-detect button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _detecting ? null : _detectCity,
              icon: _detecting
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.primary,
                      ),
                    )
                  : Icon(
                      Icons.my_location_rounded,
                      size: 18,
                      color: colors.primary,
                    ),
              label: Text(
                _detecting ? l10n.detectingLabel : l10n.detectAutoBtn,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colors.primary.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          if (_errorMsg != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.error.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: colors.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMsg!,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.error,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: colors.textPrimary.withValues(alpha: 0.1),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  l10n.enterManuallyLabel,
                  style: TextStyle(fontSize: 11, color: colors.textMuted),
                ),
              ),
              Expanded(
                child: Divider(
                  color: colors.textPrimary.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Manual input
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.textPrimary.withValues(alpha: 0.06),
              ),
            ),
            child: TextField(
              controller: _ctrl,
              style: TextStyle(color: colors.textPrimary, fontSize: 16),
              decoration: InputDecoration(
                hintText: l10n.locationHint,
                hintStyle: TextStyle(color: colors.textMuted),
                prefixIcon: Icon(
                  Icons.location_city_rounded,
                  color: colors.textMuted,
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.info.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: colors.info, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.locationNote,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.info,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Text(
            l10n.locationSkipNote,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// Page 4: Restrictions
class _PageRestrictions extends StatelessWidget {
  final List<String> restrictions;
  final List<String> commonRestrictions;
  final ValueChanged<String> onToggle;
  const _PageRestrictions({
    required this.restrictions,
    required this.commonRestrictions,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final l10n = context.l10n;
    final displayLabels = [
      l10n.dietNutsAllergy,
      l10n.dietLactose,
      l10n.dietGlutenFree,
      l10n.dietVegetarian,
      l10n.dietNoRedMeat,
      l10n.dietDiabetic,
      l10n.dietLowSalt,
      l10n.dietVegan,
      l10n.dietKeto,
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.restrictionsNote1,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.info.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: colors.info, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.restrictionsNote2,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.info,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(commonRestrictions.length, (index) {
              final r = commonRestrictions[index];
              final displayLabel = index < displayLabels.length
                  ? displayLabels[index]
                  : r;
              final isSel = restrictions.contains(r);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onToggle(r);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSel
                        ? colors.accentOrange.withValues(alpha: 0.15)
                        : colors.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSel
                          ? colors.accentOrange
                          : colors.textPrimary.withValues(alpha: 0.08),
                      width: isSel ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSel)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: colors.accentOrange,
                          ),
                        ),
                      Text(
                        displayLabel,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSel
                              ? colors.accentOrange
                              : colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          if (restrictions.isEmpty)
            Text(
              l10n.restrictionsNote3,
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── AI Generating Overlay ──────────────────────────────────────────────────

class _AiGeneratingOverlay extends StatefulWidget {
  const _AiGeneratingOverlay();

  @override
  State<_AiGeneratingOverlay> createState() => _AiGeneratingOverlayState();
}

class _AiGeneratingOverlayState extends State<_AiGeneratingOverlay>
    with TickerProviderStateMixin {
  // Background gradient pulse
  late AnimationController _bgCtrl;
  late Animation<double> _bgAnim;

  // Brain icon pulse
  late AnimationController _iconCtrl;
  late Animation<double> _iconScale;

  // Fitness facts ticker
  late AnimationController _factCtrl;
  int _factIndex = 0;
  Timer? _factTimer;

  // Progress steps
  // 0 = waiting, 1 = in-progress, 2 = done
  final List<int> _stepState = [1, 0, 0, 0];
  final List<Timer?> _stepTimers = [null, null, null, null];

  List<String> _steps = const [];
  List<String> _facts = const [];

  @override
  void initState() {
    super.initState();

    // Background gradient pulse (3 s cycle)
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut);

    // Icon scale pulse (1.5 s cycle)
    _iconCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _iconScale = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _iconCtrl, curve: Curves.easeInOut));

    // Facts ticker: advance every 4 s
    _factCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _factTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      if (_facts.isNotEmpty) {
        setState(() => _factIndex = (_factIndex + 1) % _facts.length);
      }
    });

    // Step progression schedule
    // Step 0 starts in-progress immediately, completes at 3 s
    _stepTimers[0] = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _stepState[0] = 2; // step 0 done
        _stepState[1] = 1; // step 1 in-progress
      });
    });
    // Step 1 completes at 7 s
    _stepTimers[1] = Timer(const Duration(seconds: 7), () {
      if (!mounted) return;
      setState(() {
        _stepState[1] = 2;
        _stepState[2] = 1;
      });
    });
    // Step 2 completes at 12 s
    _stepTimers[2] = Timer(const Duration(seconds: 12), () {
      if (!mounted) return;
      setState(() {
        _stepState[2] = 2;
        _stepState[3] = 1;
      });
    });
    // Step 3 stays in-progress indefinitely
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _iconCtrl.dispose();
    _factCtrl.dispose();
    _factTimer?.cancel();
    for (final t in _stepTimers) {
      t?.cancel();
    }
    super.dispose();
  }

  // Build a single step row
  Widget _buildStep(int index, dynamic colors) {
    final state = _stepState[index];
    final isVisible = state > 0;

    Widget leading;
    if (state == 2) {
      // Done
      leading = Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: Color(0xFF22C55E),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
      );
    } else if (state == 1) {
      // In progress
      leading = SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: colors.primary,
        ),
      );
    } else {
      // Waiting
      leading = Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }

    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                _steps[index],
                style: TextStyle(
                  color: state == 2
                      ? Colors.white.withValues(alpha: 0.5)
                      : state == 1
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.25),
                  fontSize: 14,
                  fontWeight: state == 1 ? FontWeight.w600 : FontWeight.w400,
                  decoration: state == 2 ? TextDecoration.lineThrough : null,
                  decorationColor: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final l10n = context.l10n;
    _steps = [
      l10n.generatingAnalyzing,
      l10n.generatingWorkout,
      l10n.generatingMeal,
      l10n.generatingFinalizing,
    ];
    _facts = [
      l10n.funFact1,
      l10n.funFact2,
      l10n.funFact3,
      l10n.funFact4,
      l10n.funFact5,
      l10n.funFact6,
    ];

    return AnimatedBuilder(
      animation: _bgAnim,
      builder: (context, child) {
        final gradient = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0A0A0F),
            Color.lerp(
              const Color(0xFF1A0A2E),
              const Color(0xFF0A1F1A),
              _bgAnim.value,
            )!,
          ],
        );

        return Container(
          decoration: BoxDecoration(gradient: gradient),
          child: child,
        );
      },
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // ── Pulsing brain icon ──
              ScaleTransition(
                scale: _iconScale,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.purple.withValues(alpha: 0.12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purpleAccent.withValues(alpha: 0.4),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.psychology_rounded,
                    size: 80,
                    color: Colors.purpleAccent,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Title ──
              Text(
                l10n.aiPlanCreating,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Syne',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.about30sec,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 40),

              // ── Progress steps ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < _steps.length; i++)
                      _buildStep(i, colors),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // ── Facts ticker ──
              if (_facts.isNotEmpty)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: Text(
                    _facts[_factIndex % _facts.length],
                    key: ValueKey<int>(_factIndex),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
