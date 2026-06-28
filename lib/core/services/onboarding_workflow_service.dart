import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/domain/services/i_deepseek_service.dart';
import 'package:fitnesbuster/domain/repositories/i_user_repository.dart';
import 'package:fitnesbuster/core/utils/app_logger.dart';

class OnboardingWorkflowService {
  final IDeepSeekService _aiService;
  final IUserRepository _userRepo;

  OnboardingWorkflowService({
    required IDeepSeekService aiService,
    required IUserRepository userRepo,
  })  : _aiService = aiService,
        _userRepo = userRepo;

  Future<({String workoutPlanJson, String mealPlanJson})> generatePlans({
    required String userId,
    required UserProfile profile,
    String? city,
  }) async {
    final workoutPlan = await _aiService.generateWorkoutPlan(profile);
    final mealPlan = await _aiService.generateMealPlan(
      profile,
      city: city,
    );

    try {
      await _userRepo.saveAiPlans(
        userId: userId,
        workoutPlanJson: workoutPlan,
        mealPlanJson: mealPlan,
      );
    } catch (e, st) {
      appLogger.w('[OnboardingWorkflowService] AI plans save failed', error: e, stackTrace: st);
    }

    return (workoutPlanJson: workoutPlan, mealPlanJson: mealPlan);
  }
}
