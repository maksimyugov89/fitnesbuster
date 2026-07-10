import 'package:fitnesbuster/core/constants/firebase_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('client uses the production named Firestore database', () {
    expect(FirebaseConfig.firestoreDatabaseId, 'fitnesbuster');
  });
}
