/// Computes whole-years age from a date of birth relative to [now]
/// (defaults to `DateTime.now()`).
int calculateAge(DateTime dateOfBirth, {DateTime? now}) {
  final today = now ?? DateTime.now();
  int age = today.year - dateOfBirth.year;
  final hadBirthdayThisYear =
      (today.month > dateOfBirth.month) ||
      (today.month == dateOfBirth.month && today.day >= dateOfBirth.day);
  if (!hadBirthdayThisYear) age -= 1;
  return age;
}
