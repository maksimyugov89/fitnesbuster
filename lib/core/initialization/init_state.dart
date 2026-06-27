import 'package:flutter/foundation.dart';

/// Signals that the full app initialization (after Firebase) has completed.
final ValueNotifier<bool> initializationComplete = ValueNotifier(false);
