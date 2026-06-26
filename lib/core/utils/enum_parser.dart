import 'package:fitnesbuster/domain/entities/entities.dart';

FitnessGoal parseFitnessGoal(String? g) {
  switch (g) {
    case 'loseWeight': return FitnessGoal.loseWeight;
    case 'gainWeight': return FitnessGoal.gainWeight;
    case 'maintain': return FitnessGoal.maintain;
    case 'beachBody': return FitnessGoal.beachBody;
    case 'sportPerformance': return FitnessGoal.sportPerformance;
    default: return FitnessGoal.loseWeight;
  }
}

IntensityLevel parseIntensityLevel(String? i) {
  switch (i) {
    case 'hardcore': return IntensityLevel.hardcore;
    case 'intensive': return IntensityLevel.intensive;
    case 'balanced': return IntensityLevel.balanced;
    case 'gradual': return IntensityLevel.gradual;
    case 'relaxed': return IntensityLevel.relaxed;
    default: return IntensityLevel.balanced;
  }
}

ActivityLevel parseActivityLevel(String? a) {
  switch (a) {
    case 'sedentary': return ActivityLevel.sedentary;
    case 'lightlyActive': return ActivityLevel.lightlyActive;
    case 'moderatelyActive': return ActivityLevel.moderatelyActive;
    case 'veryActive': return ActivityLevel.veryActive;
    case 'extraActive': return ActivityLevel.extraActive;
    default: return ActivityLevel.sedentary;
  }
}

Gender parseGender(String? g) => g == 'male' ? Gender.male : Gender.female;
