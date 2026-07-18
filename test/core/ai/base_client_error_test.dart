import 'package:fitnesbuster/core/ai/ai_exception.dart';
import 'package:fitnesbuster/core/ai/base_client.dart';
import 'package:fitnesbuster/core/ai/network/retry_handler.dart';
import 'package:fitnesbuster/core/localization/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mapFirebaseFunctionsException', () {
    test('maps auth and quota errors to non-retryable AI exceptions', () {
      final auth = mapFirebaseFunctionsException('unauthenticated', null);
      final quota = mapFirebaseFunctionsException('resource-exhausted', null);

      expect(auth.statusCode, 401);
      expect(auth.message, contains('Войдите'));
      expect(shouldNotRetryAiException(auth), isTrue);
      expect(quota.statusCode, 429);
      expect(quota.message, contains('Слишком много'));
      expect(shouldNotRetryAiException(quota), isTrue);
    });

    test('maps transient functions errors to retryable AI exceptions', () {
      for (final code in ['deadline-exceeded', 'unavailable', 'internal']) {
        final exception = mapFirebaseFunctionsException(code, null);

        expect(exception.statusCode, isIn([500, 503, 504]));
        expect(exception.message, AppLocalizations.tl('aiUnavailableRetry'));
        expect(shouldNotRetryAiException(exception), isFalse);
      }
    });

    test('uses fallback message for unknown functions errors', () {
      final exception = mapFirebaseFunctionsException('unknown', 'Raw failure');

      expect(exception.statusCode, isNull);
      expect(exception.message, 'Raw failure');
      expect(shouldNotRetryAiException(exception), isFalse);
    });
  });

  group('withRetry classifier', () {
    test('retries retryable AI exceptions up to max retries', () async {
      var attempts = 0;

      await expectLater(
        withRetry<void>(
          () async {
            attempts++;
            throw const AiException('temporary', statusCode: 503);
          },
          maxRetries: 3,
          shouldRethrow: shouldNotRetryAiException,
          delay: (_) => Duration.zero,
        ),
        throwsA(isA<AiException>()),
      );

      expect(attempts, 3);
    });

    test('does not retry non-retryable AI exceptions', () async {
      var attempts = 0;

      await expectLater(
        withRetry<void>(
          () async {
            attempts++;
            throw const AiException('bad request', statusCode: 400);
          },
          maxRetries: 3,
          shouldRethrow: shouldNotRetryAiException,
          delay: (_) => Duration.zero,
        ),
        throwsA(isA<AiException>()),
      );

      expect(attempts, 1);
    });
  });
}
