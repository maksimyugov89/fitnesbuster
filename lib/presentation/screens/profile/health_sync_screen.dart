import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fitnesbuster/core/theme/app_theme.dart' hide AppTheme;
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';
import 'package:fitnesbuster/core/theme/app_images.dart';
import 'package:fitnesbuster/core/health/health_connect_service.dart';
import 'package:fitnesbuster/bloc/health/health_sync_bloc.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';

/// Health Connect sync screen — data from all fitness apps via Google Health Connect.
class HealthSyncScreen extends StatefulWidget {
  const HealthSyncScreen({
    super.key,
    this.bloc,
    this.onOpenHealthConnectSettings,
  });

  final HealthSyncBloc? bloc;
  final VoidCallback? onOpenHealthConnectSettings;

  @override
  State<HealthSyncScreen> createState() => _HealthSyncScreenState();
}

class _HealthSyncScreenState extends State<HealthSyncScreen> {
  late final HealthSyncBloc _bloc;
  late final bool _ownsBloc;

  @override
  void initState() {
    super.initState();
    _ownsBloc = widget.bloc == null;
    _bloc = widget.bloc ?? HealthSyncBloc(hcService: HealthConnectService());
    if (_ownsBloc) _bloc.add(const HealthSyncInitializeRequested());
  }

  @override
  void dispose() {
    if (_ownsBloc) _bloc.close();
    super.dispose();
  }

  void _sync() {
    _bloc.add(const HealthSyncReadToday());
  }

  Future<void> _openHealthConnectSettings() async {
    final callback = widget.onOpenHealthConnectSettings;
    if (callback != null) {
      callback();
      return;
    }
    if (!Platform.isAndroid) return;
    const intent = AndroidIntent(
      action: 'android.health.connect.action.HEALTH_HOME_SETTINGS',
    );
    await intent.launch();
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
                  AppLocalizations.tlp('healthSyncSuccess', {
                    'steps': '${state.data.steps}',
                    'calories': state.data.caloriesBurned.toStringAsFixed(0),
                  }),
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
              state.kind == HealthSyncErrorKind.notInstalled) {
            return _buildNotInstalled(colors);
          }
          if (state is HealthSyncStateError &&
              state.kind == HealthSyncErrorKind.accessDenied) {
            return _buildAccessDenied(colors, state.message);
          }

          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(
                AppLocalizations.tl('healthSyncTitle'),
                style: AppTextStyles.titleM,
              ),
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
                  Text(
                    AppLocalizations.tl('healthTodayData'),
                    style: AppTextStyles.titleL,
                  ),
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
                            AppLocalizations.tl('healthSyncEmpty'),
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
                            ? AppLocalizations.tl('healthSyncing')
                            : AppLocalizations.tl('healthSyncAction'),
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
                      AppLocalizations.tl('healthSyncSource'),
                      style: TextStyle(fontSize: 11, color: colors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      AppLocalizations.tl('healthPermissionInfo'),
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
        title: Text(
          AppLocalizations.tl('healthSyncTitle'),
          style: AppTextStyles.titleM,
        ),
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
          Text(
            AppLocalizations.tl('healthNotInstalled'),
            style: AppTextStyles.titleL,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.tl('healthNotInstalledBody'),
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
              label: Text(
                AppLocalizations.tl('healthInstallConnect'),
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
        ],
      ),
    );
  }

  Widget _buildAccessDenied(dynamic colors, String message) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          AppLocalizations.tl('healthSyncTitle'),
          style: AppTextStyles.titleM,
        ),
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
          Icon(
            Icons.health_and_safety_rounded,
            size: 72,
            color: colors.primary,
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.tl('healthNoAccess'),
            style: AppTextStyles.titleL,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(fontSize: 14, color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openHealthConnectSettings,
            icon: const Icon(Icons.settings_rounded),
            label: Text(AppLocalizations.tl('healthOpenConnectSettings')),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _sync,
            child: Text(AppLocalizations.tl('healthCheckAgain')),
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
            AppLocalizations.tl('healthConnectSubtitle'),
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              const _ProviderBadge('Google Fit'),
              const SizedBox(width: 8),
              const _ProviderBadge('Samsung Health'),
              const SizedBox(width: 8),
              const _ProviderBadge('Mi Fitness'),
              const SizedBox(width: 8),
              _ProviderBadge(AppLocalizations.tl('healthOtherProviders')),
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
                label: AppLocalizations.tl('stepsTodayLabel'),
                value: '${data.steps}',
                color: colors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DataTile(
                icon: AppImages.calorieCounter,
                label: AppLocalizations.tl('healthCalories'),
                value: '${data.caloriesBurned.toInt()}',
                unit: AppLocalizations.tl('socialKcal'),
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
                label: AppLocalizations.tl('healthHeartRate'),
                value: data.heartRateAvg?.toString() ?? '—',
                unit: AppLocalizations.tl('bpmUnit'),
                color: colors.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DataTile(
                icon: AppImages.weightTracker,
                label: AppLocalizations.tl('weightLabel'),
                value: data.weight?.toStringAsFixed(1) ?? '—',
                unit: AppLocalizations.tl('dashboardKg'),
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
                label: AppLocalizations.tl('healthSleep'),
                value: _sleepText(data.sleepMinutes),
                color: colors.info,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DataTile(
                icon: AppImages.water,
                label: AppLocalizations.tl('waterHealthLabel'),
                value: data.waterIntakeMl?.toStringAsFixed(0) ?? '—',
                unit: AppLocalizations.tl('mlHealthUnit'),
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
                label: AppLocalizations.tl('healthDistance'),
                value: (data.distanceKm ?? 0).toStringAsFixed(1),
                unit: AppLocalizations.tl('kmUnit'),
                color: colors.success,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          AppLocalizations.tlp('healthLastSync', {
            'time': _formatTime(lastSync),
          }),
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
    return AppLocalizations.tlp('healthSleepDuration', {
      'hours': '$h',
      'minutes': '$m',
    });
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return AppLocalizations.tl('healthJustNow');
    if (diff.inMinutes < 60) {
      return AppLocalizations.tlp('healthMinutesAgo', {
        'minutes': '${diff.inMinutes}',
      });
    }
    if (diff.inHours < 24) {
      return AppLocalizations.tlp('healthHoursAgo', {
        'hours': '${diff.inHours}',
      });
    }
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
