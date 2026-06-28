// ignore_for_file: argument_type_not_assignable
// Mocks generated manually for integration_test/onboarding_test.dart
import 'package:mockito/mockito.dart';
import 'package:fitnesbuster/domain/repositories/i_auth_repository.dart';
import 'package:fitnesbuster/domain/repositories/i_user_repository.dart';
import 'package:fitnesbuster/domain/repositories/i_settings_repository.dart';
import 'package:fitnesbuster/domain/services/i_health_connect_service.dart';
import 'package:fitnesbuster/domain/services/i_gamification_service.dart';
import 'package:fitnesbuster/core/services/i_social_service.dart';
import 'package:fitnesbuster/core/services/onboarding_workflow_service.dart';

class MockIAuthRepository extends Mock implements IAuthRepository {}
class MockIUserRepository extends Mock implements IUserRepository {}
class MockISettingsRepository extends Mock implements ISettingsRepository {}
class MockIHealthConnectService extends Mock implements IHealthConnectService {}
class MockISocialService extends Mock implements ISocialService {}
class MockIGamificationService extends Mock implements IGamificationService {}
class MockOnboardingWorkflowService extends Mock implements OnboardingWorkflowService {}
