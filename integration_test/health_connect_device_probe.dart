import 'package:fitnesbuster/core/health/health_connect_service.dart';
import 'package:fitnesbuster/core/health/health_data_mapper.dart';
import 'package:fitnesbuster/core/services/recovery_score_service.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HealthConnectDeviceProbe());
}

class HealthConnectDeviceProbe extends StatelessWidget {
  const HealthConnectDeviceProbe({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _ProbeScreen(),
    );
  }
}

class _ProbeScreen extends StatefulWidget {
  const _ProbeScreen();

  @override
  State<_ProbeScreen> createState() => _ProbeScreenState();
}

class _ProbeScreenState extends State<_ProbeScreen> {
  bool _loading = false;
  bool? _initialized;
  SyncedHealthData? _data;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  Future<void> _sync() async {
    setState(() {
      _loading = true;
      _initialized = null;
      _data = null;
    });

    final service = HealthConnectService();
    final initialized = await service.initialize();
    final data = initialized ? await service.readAllToday() : null;
    service.dispose();

    if (!mounted) return;
    setState(() {
      _loading = false;
      _initialized = initialized;
      _data = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    final aiData = _data == null ? null : healthDataFromSynced(_data!);
    final recovery = _data == null
        ? null
        : RecoveryScoreService.calculate(
            sleepMinutes: _data!.sleepMinutes,
            hrv: _data!.heartRateVariability,
            restingHr: _data!.restingHeartRate,
          );
    return Scaffold(
      appBar: AppBar(title: const Text('Health Connect device probe')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('initialized=${_initialized ?? 'pending'}'),
          if (_loading) const LinearProgressIndicator(),
          if (_data case final data?) ...[
            Text('steps=${data.steps}'),
            Text('activeCalories=${data.caloriesBurned.toStringAsFixed(2)}'),
            Text(
              'totalCalories=${data.totalCaloriesBurned.toStringAsFixed(2)}',
            ),
            Text('heartRateAvg=${data.heartRateAvg}'),
            Text('restingHeartRate=${data.restingHeartRate}'),
            Text(
              'heartRateVariability='
              '${data.heartRateVariability?.toStringAsFixed(2)}',
            ),
            Text('respiratoryRate=${data.respiratoryRate?.toStringAsFixed(2)}'),
            Text('weightKg=${data.weight?.toStringAsFixed(2)}'),
            Text('heightM=${data.height?.toStringAsFixed(2)}'),
            Text('distanceKm=${data.distanceKm?.toStringAsFixed(2)}'),
            Text('waterMl=${data.waterIntakeMl?.toStringAsFixed(2)}'),
            Text('sleepMinutes=${data.sleepMinutes}'),
            Text('workoutCount=${data.workoutCount}'),
            Text('aiSteps=${aiData?.steps}'),
            Text('aiWeightKg=${aiData?.weight?.toStringAsFixed(2)}'),
            Text('aiHrvMs=${aiData?.heartRateVariability?.toStringAsFixed(2)}'),
            Text('recoveryScore=${recovery?.score}'),
            Text('recoveryLevel=${recovery?.level.name}'),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loading ? null : _sync,
            child: const Text('SYNC'),
          ),
        ],
      ),
    );
  }
}
