import 'package:flutter_test/flutter_test.dart';
import 'package:fitnesbuster/domain/entities/user_entities.dart';

void main() {
  test('UserEntity defaults missing entitlement to free', () {
    final user = UserEntity(
      id: 'uid',
      name: 'Test',
      email: 'test@example.com',
      createdAt: DateTime(2026),
    );

    expect(user.entitlement.tier, 'free');
    expect(user.entitlement.source, 'admin');
    expect(user.entitlement.expiresAt, isNull);
  });

  test('Entitlement JSON round-trip preserves premium access', () {
    final expiry = DateTime.utc(2027, 1, 1);
    final entitlement = Entitlement(
      tier: 'premium',
      source: 'admin',
      expiresAt: expiry,
    );

    expect(Entitlement.fromJson(entitlement.toJson()), entitlement);
  });
}
