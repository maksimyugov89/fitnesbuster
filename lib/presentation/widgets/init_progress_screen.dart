import 'package:flutter/material.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:fitnesbuster/core/initialization/app_initializer.dart';

class InitProgressScreen extends StatefulWidget {
  final VoidCallback onRetry;

  const InitProgressScreen({super.key, required this.onRetry});

  @override
  State<InitProgressScreen> createState() => _InitProgressScreenState();
}

class _InitProgressScreenState extends State<InitProgressScreen> {
  String _currentStage = '';
  String? _error;
  bool _errorMode = false;

  @override
  void initState() {
    super.initState();
    _runInit();
  }

  Future<void> _runInit() async {
    final initializer = AppInitializer();
    try {
      await initializer.initialize(
        onProgress: (stage) {
          if (mounted) setState(() => _currentStage = stage);
        },
      );
      if (mounted && !_errorMode) {
        widget.onRetry();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _errorMode = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_errorMode) ...[
                const Icon(Icons.error_outline_rounded, color: Colors.orangeAccent, size: 64),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.tl('appInitError'),
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _error ?? '',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() { _errorMode = false; _error = null; _currentStage = ''; });
                    _runInit();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.black,
                  ),
                  child: Text(AppLocalizations.tl('retry')),
                ),
              ] else ...[
                const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(color: Colors.orangeAccent, strokeWidth: 2.5)),
                const SizedBox(height: 24),
                Text(
                  _stageLabel(_currentStage),
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _stageLabel(String stage) {
    switch (stage) {
      case 'Firebase': return 'Firebase...';
      case 'Storage': return 'Storage...';
      case 'Services': return 'Services...';
      case 'Exercises': return 'Exercises...';
      case 'Locale': return 'Locale...';
      default: return '';
    }
  }
}
