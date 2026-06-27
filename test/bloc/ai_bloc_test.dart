import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:fitnesbuster/bloc/ai/ai_bloc.dart';
import 'package:fitnesbuster/core/ai/deepseek_service.dart' show AiException;
import 'package:fitnesbuster/domain/services/i_deepseek_service.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';

import 'ai_bloc_test.mocks.dart';

@GenerateMocks([IDeepSeekService])
void main() {
  late MockIDeepSeekService aiService;

  const tProfile = UserProfile(
    weight: 80,
    height: 175,
    age: 30,
    gender: Gender.male,
    goal: FitnessGoal.loseWeight,
    intensity: IntensityLevel.balanced,
    activityLevel: ActivityLevel.moderatelyActive,
  );

  setUp(() => aiService = MockIDeepSeekService());

  test('initial state is AiStateInitial', () {
    final bloc = AiBloc(aiService: aiService);
    expect(bloc.state, const AiStateInitial());
    bloc.close();
  });

  group('AiGenerateWorkoutPlan', () {
    blocTest<AiBloc, AiState>(
      'emits Loading then Loaded on success',
      build: () => AiBloc(aiService: aiService),
      setUp: () {
        when(aiService.generateWorkoutPlan(any))
            .thenAnswer((_) async => '{"days": []}');
      },
      act: (b) => b.add(const AiGenerateWorkoutPlan(profile: tProfile)),
      expect: () => [
        const AiStateLoading(),
        isA<AiStateLoaded>()
            .having((s) => s.type, 'type', AiResultType.workoutPlan)
            .having((s) => s.result, 'result', '{"days": []}'),
      ],
    );

    blocTest<AiBloc, AiState>(
      'emits Loading then Error on AiException',
      build: () => AiBloc(aiService: aiService),
      setUp: () {
        when(aiService.generateWorkoutPlan(any))
            .thenThrow(const AiException('API key not set'));
      },
      act: (b) => b.add(const AiGenerateWorkoutPlan(profile: tProfile)),
      expect: () => [
        const AiStateLoading(),
        const AiStateError(message: 'API key not set'),
      ],
    );

    blocTest<AiBloc, AiState>(
      'emits Loading then generic Error on unknown exception',
      build: () => AiBloc(aiService: aiService),
      setUp: () {
        when(aiService.generateWorkoutPlan(any)).thenThrow(Exception('timeout'));
      },
      act: (b) => b.add(const AiGenerateWorkoutPlan(profile: tProfile)),
      expect: () => [
        const AiStateLoading(),
        const AiStateError(
          message: 'Не удалось сгенерировать программу. Попробуйте снова.',
        ),
      ],
    );
  });

  group('AiGenerateMealPlan', () {
    blocTest<AiBloc, AiState>(
      'emits Loading then Loaded on success',
      build: () => AiBloc(aiService: aiService),
      setUp: () {
        when(aiService.generateMealPlan(any))
            .thenAnswer((_) async => '{"meals": []}');
      },
      act: (b) => b.add(const AiGenerateMealPlan(profile: tProfile)),
      expect: () => [
        const AiStateLoading(),
        isA<AiStateLoaded>().having((s) => s.type, 'type', AiResultType.mealPlan),
      ],
    );
  });

  group('AiAskQuestion', () {
    blocTest<AiBloc, AiState>(
      'emits Loading then Loaded on success',
      build: () => AiBloc(aiService: aiService),
      setUp: () {
        when(aiService.askQuestion(any, profile: anyNamed('profile')))
            .thenAnswer((_) async => 'Great answer!');
      },
      act: (b) => b.add(const AiAskQuestion(question: 'How many reps?')),
      expect: () => [
        const AiStateLoading(),
        isA<AiStateLoaded>()
            .having((s) => s.type, 'type', AiResultType.answer)
            .having((s) => s.result, 'result', 'Great answer!'),
      ],
    );
  });

  group('AiReset', () {
    blocTest<AiBloc, AiState>(
      'resets to AiStateInitial from any state',
      build: () => AiBloc(aiService: aiService),
      seed: () => const AiStateError(message: 'some error'),
      act: (b) => b.add(const AiReset()),
      expect: () => [const AiStateInitial()],
    );
  });
}
