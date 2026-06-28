import 'package:fitnesbuster/domain/entities/entities.dart';
import 'package:fitnesbuster/domain/services/i_deepseek_service.dart';
import 'package:fitnesbuster/domain/repositories/i_user_repository.dart';
import 'package:fitnesbuster/domain/repositories/i_auth_repository.dart';
import 'package:fitnesbuster/core/utils/app_logger.dart';

class CompleteTestWeekUseCase {
  final IAuthRepository _authRepo;
  final IUserRepository _userRepo;
  final IDeepSeekService _aiService;

  CompleteTestWeekUseCase({
    required IAuthRepository authRepo,
    required IUserRepository userRepo,
    required IDeepSeekService aiService,
  })  : _authRepo = authRepo,
        _userRepo = userRepo,
        _aiService = aiService;

  Future<void> execute(TestWeekResult testResult) async {
    final uid = _authRepo.currentUser?.id;
    if (uid == null) return;

    UserProfile? profile;
    try {
      final user = await _userRepo.getUser(uid);
      profile = user.profile;
    } catch (e, st) {
      appLogger.w('[CompleteTestWeekUseCase] getUser failed', error: e, stackTrace: st);
    }

    if (profile != null) {
      try {
        final refined = await _aiService.refineWorkoutPlan(profile, testResult.exercises);
        await _userRepo.updateWorkoutPlan(userId: uid, workoutPlanJson: refined);
      } catch (e, st) {
        appLogger.w('[CompleteTestWeekUseCase] AI refinement failed', error: e, stackTrace: st);
      }
    }

    await _userRepo.saveTestWeekCompleted(userId: uid);
  }
}
