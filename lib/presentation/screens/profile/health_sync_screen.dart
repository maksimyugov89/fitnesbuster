import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/theme/app_images.dart';
import 'package:fitnesbuster/core/health/health_connect_service.dart';
import 'package:fitnesbuster/bloc/health/health_sync_bloc.dart';

/// Health Connect sync screen — data from all fitness apps via Google Health Connect.
class HealthSyncScreen extends StatefulWidget {
  const HealthSyncScreen({super.key});

  @override
  State<HealthSyncScreen> createState() => _HealthSyncScreenState();
}

class _HealthSyncScreenState extends State<HealthSyncScreen> {
  late final HealthSyncBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = HealthSyncBloc(hcService: HealthConnectService());
    _bloc.add(const HealthSyncInitializeRequested());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  void _sync() {
    _bloc.add(const HealthSyncReadToday());
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<HealthSyncBloc, HealthSyncState>(
        listener: (context, state) {
          if (state is HealthSyncStateLoaded) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Синхронизировано! Шаги: ${state.data.steps}, Калории: ${state.data.caloriesBurned.toStringAsFixed(0)}',
                ),
                backgroundColor: colors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is HealthSyncStateError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: colors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is HealthSyncStateError &&
              state.message.contains('не установлен')) {
            return _buildNotInstalled(colors);
          }

          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text('Синхронизация', style: AppTextStyles.titleM),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop(),
              ),
            ),
            body: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildHeader(colors),
                const SizedBox(height: 24),

                if (state is HealthSyncStateLoading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  const Text('Данные за сегодня', style: AppTextStyles.titleL),
                  const SizedBox(height: 12),

                  if (state is HealthSyncStateLoaded) ...[
                    _buildDataGrid(colors, state.data, state.lastSyncAt),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colors.surfaceCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colors.textPrimary.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.sync_rounded,
                            size: 48,
                            color: colors.textMuted.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Нажмите «Синхронизировать» для загрузки данных',
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.textMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: state is HealthSyncStateLoading ? null : _sync,
                      icon: state is HealthSyncStateLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.sync_rounded, size: 20),
                      label: Text(
                        state is HealthSyncStateLoading
                            ? 'Синхронизация...'
                            : 'Синхронизировать с Health Connect',
                        style: const TextStyle(
                          fontFamily: 'Syne',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.textOnPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Данные загружаются из Health Connect (Здоровье и спорт)',
                      style: TextStyle(fontSize: 11, color: colors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'При первом запуске Android покажет системный запрос доступа только к выбранным данным здоровья.',
                      style: TextStyle(fontSize: 11, color: colors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotInstalled(dynamic colors) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Синхронизация', style: AppTextStyles.titleM),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 40),
          AppIcon(
            asset: AppImages.healthIntegration,
            glowColor: colors.primary,
            size: 72,
          ),
          const SizedBox(height: 20),
          const Text(
            'Health Connect не установлен',
            style: AppTextStyles.titleL,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Для синхронизации данных о здоровье необходимо установить приложение «Health Connect (Здоровье и спорт)» из Google Play.',
            style: TextStyle(
              fontSize: 13,
              color: colors.textMuted,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () async {
                await launchUrl(
                  Uri.parse(
                    'https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata',
                  ),
                );
              },
              icon: const Icon(Icons.download_rounded, size: 20),
              label: const Text(
                'Установить Health Connect',
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.textOnPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(dynamic colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppIcon(
            asset: AppImages.bluetoothDevices,
            glowColor: Colors.white,
            size: 56,
          ),
          const SizedBox(height: 16),
          const Text(
            'Health Connect',
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Синхронизация с фитнес-приложениями через Google Health Connect',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _ProviderBadge('Google Fit'),
              SizedBox(width: 8),
              _ProviderBadge('Samsung Health'),
              SizedBox(width: 8),
              _ProviderBadge('Mi Fitness'),
              SizedBox(width: 8),
              _ProviderBadge('и другие'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataGrid(
    dynamic colors,
    SyncedHealthData data,
    DateTime lastSync,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _DataTile(
                icon: AppImages.steps,
                label: 'Шаги',
                value: '${data.steps}',
                color: colors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DataTile(
                icon: AppImages.calorieCounter,
                label: 'Калории',
                value: '${data.caloriesBurned.toInt()}',
                unit: 'ккал',
                color: colors.accentOrange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DataTile(
                icon: AppImages.heartRate,
                label: 'Пульс',
                value: data.heartRateAvg?.toString() ?? '—',
                unit: 'уд/мин',
                color: colors.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DataTile(
                icon: AppImages.weightTracker,
                label: 'Вес',
                value: data.weight?.toStringAsFixed(1) ?? '—',
                unit: 'кг',
                color: colors.accentPurple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DataTile(
                icon: AppImages.sleep,
                label: 'Сон',
                value: _sleepText(data.sleepMinutes),
                color: colors.info,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DataTile(
                icon: AppImages.water,
                label: 'Вода',
                value: data.waterIntakeMl?.toStringAsFixed(0) ?? '—',
                unit: 'мл',
                color: colors.primaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DataTile(
                icon: AppImages.route,
                label: 'Дистанция',
                value: (data.distanceKm ?? 0).toStringAsFixed(1),
                unit: 'км',
                color: colors.success,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Последняя синхронизация: ${_formatTime(lastSync)}',
          style: TextStyle(fontSize: 11, color: colors.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _sleepText(int? minutes) {
    if (minutes == null || minutes == 0) return '—';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    // ignore: unnecessary_brace_in_string_interps — Cyrillic suffix requires braces
    return '${h}ч ${m}м';
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'только что';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин. назад';
    if (diff.inHours < 24) return '${diff.inHours} ч. назад';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _ProviderBadge extends StatelessWidget {
  final String label;
  const _ProviderBadge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: Colors.white.withValues(alpha: 0.9),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DataTile extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final String? unit;
  final Color color;
  const _DataTile({
    required this.icon,
    required this.label,
    required this.value,
    this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.textPrimary.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: AppIcon(asset: icon, glowColor: color, size: 53),
              ),
              const Spacer(),
              if (unit != null)
                Text(
                  unit!,
                  style: TextStyle(fontSize: 10, color: colors.textMuted),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: colors.textMuted)),
        ],
      ),
    );
  }
}
