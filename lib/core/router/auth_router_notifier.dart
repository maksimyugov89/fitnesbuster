import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fitnesbuster/bloc/auth/auth_bloc.dart';
import 'package:fitnesbuster/core/di/injection.dart' show sl;

/// Notifies GoRouter when auth state changes (Firebase + AuthBloc).
class AuthRouterNotifier extends ChangeNotifier {
  late final StreamSubscription<User?> _firebaseSub;
  late final StreamSubscription<AuthState> _blocSub;

  AuthRouterNotifier() {
    _firebaseSub = FirebaseAuth.instance
        .authStateChanges()
        .listen((_) => notifyListeners());
    _blocSub = sl<AuthBloc>().stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _firebaseSub.cancel();
    _blocSub.cancel();
    super.dispose();
  }
}
