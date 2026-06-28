import 'package:flutter_test/flutter_test.dart';
import 'package:fitnesbuster/domain/entities/entities.dart';

void main() {
  const male80kg175cm30 = UserProfile(
    weight: 80,
    height: 175,
    age: 30,
    gender: Gender.male,
    goal: FitnessGoal.loseWeight,
    intensity: IntensityLevel.balanced,
    activityLevel: ActivityLevel.moderatelyActive,
  );

  const female60kg160cm25 = UserProfile(
    weight: 60,
    height: 160,
    age: 25,
    gender: Gender.female,
    goal: FitnessGoal.maintain,
    intensity: IntensityLevel.balanced,
    activityLevel: ActivityLevel.lightlyActive,
  );

  group('UserProfile.bmi', () {
    test('calculates correctly for male 80kg 175cm', () {
      // 80 / (1.75 * 1.75) = 26.12
      expect(male80kg175cm30.bmi, closeTo(26.12, 0.01));
    });

    test('calculates correctly for female 60kg 160cm', () {
      // 60 / (1.60 * 1.60) = 23.44
      expect(female60kg160cm25.bmi, closeTo(23.44, 0.01));
    });

    test('returns 0 when height is 0', () {
      final p = male80kg175cm30.copyWith(height: 0);
      expect(p.bmi, 0);
    });
  });

  group('UserProfile.bmr', () {
    test('Mifflin-St Jeor male formula', () {
      // (10*80) + (6.25*175) - (5*30) + 5 = 1748.75
      expect(male80kg175cm30.bmr, closeTo(1748.75, 1.0));
    });

    test('Mifflin-St Jeor female formula', () {
      // (10*60) + (6.25*160) - (5*25) - 161 = 1314.0
      expect(female60kg160cm25.bmr, closeTo(1314.0, 1.0));
    });
  });

  group('UserProfile.tdee', () {
    test('moderately active multiplier is 1.55', () {
      expect(ActivityLevel.moderatelyActive.multiplier, 1.55);
      expect(male80kg175cm30.tdee,
          closeTo(male80kg175cm30.bmr * 1.55, 1.0));
    });
  });

  group('UserProfile.dailyCalorieTarget', () {
    test('loseWeight = TDEE - 500', () {
      expect(male80kg175cm30.dailyCalorieTarget,
          closeTo(male80kg175cm30.tdee - 500, 1.0));
    });

    test('maintain = TDEE', () {
      expect(female60kg160cm25.dailyCalorieTarget,
          closeTo(female60kg160cm25.tdee, 1.0));
    });

    test('gainWeight = TDEE + 500', () {
      final p = male80kg175cm30.copyWith(goal: FitnessGoal.gainWeight);
      expect(p.dailyCalorieTarget, closeTo(p.tdee + 500, 1.0));
    });
  });

  group('UserProfile.copyWith', () {
    test('returns new instance with updated fields', () {
      final updated = male80kg175cm30.copyWith(weight: 75, age: 31);
      expect(updated.weight, 75);
      expect(updated.age, 31);
      expect(updated.height, male80kg175cm30.height);
      expect(updated.gender, male80kg175cm30.gender);
    });
  });

  group('UserEntity.copyWith', () {
    final user = UserEntity(
      id: '1',
      name: 'Alice',
      email: 'alice@example.com',
      createdAt: DateTime(2024),
    );

    test('updates name', () {
      expect(user.copyWith(name: 'Bob').name, 'Bob');
    });

    test('clearAvatar sets avatarUrl to null', () {
      final withAvatar = user.copyWith(avatarUrl: 'http://img.jpg');
      expect(withAvatar.copyWith(avatarUrl: null).avatarUrl, isNull);
    });
  });

  group('FoodItem.nutritionForGrams', () {
    const item = FoodItem(
      id: 'f1',
      name: 'Chicken',
      nutrition: NutritionPer100g(
        calories: 165,
        protein: 31,
        carbs: 0,
        fat: 3.6,
      ),
    );

    test('scales nutrition for 200g', () {
      final n = item.nutritionForGrams(200);
      expect(n.calories, closeTo(330, 0.01));
      expect(n.protein, closeTo(62, 0.01));
    });

    test('scales nutrition for 50g', () {
      final n = item.nutritionForGrams(50);
      expect(n.calories, closeTo(82.5, 0.01));
    });
  });
}
