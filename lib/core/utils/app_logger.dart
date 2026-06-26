import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Global structured logger. In release builds only warnings and above are emitted.
final appLogger = Logger(
  level: kReleaseMode ? Level.warning : Level.trace,
  printer: PrettyPrinter(
    methodCount: 0,
    noBoxingByDefault: true,
    colors: false,
  ),
);
