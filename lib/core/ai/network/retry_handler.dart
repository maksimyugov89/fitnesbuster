import 'dart:async';
import 'package:fitnesbuster/core/ai/ai_exception.dart';

/// Generic retry wrapper with exponential backoff.
Future<T> withRetry<T>(
  Future<T> Function() operation, {
  int maxRetries = 3,
  bool Function(AiException)? shouldRethrow,
  Duration Function(int attempt)? delay,
}) async {
  AiException? lastError;
  for (int attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await operation();
    } on AiException catch (e) {
      lastError = e;
      if (shouldRethrow?.call(e) == true) rethrow;
      if (attempt < maxRetries) {
        await Future.delayed(
          delay?.call(attempt) ?? Duration(seconds: attempt * 2),
        );
      }
    }
  }
  throw lastError!;
}
