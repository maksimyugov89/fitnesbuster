import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fitnesbuster/core/router/app_router.dart';
import 'package:fitnesbuster/domain/services/i_fcm_service.dart';

class FcmService implements IFcmService {
  FcmService();

  @override
  Future<void> init() async {
    FirebaseMessaging.onMessage.listen(_onForeground);
    FirebaseMessaging.onMessageOpenedApp.listen(_onTap);

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _onTap(initial);
  }

  void _onForeground(RemoteMessage message) {
    // Foreground messages: no UI interruption — the user is already in the app.
    // A local notification popup could be added here if needed in future.
  }

  void _onTap(RemoteMessage message) {
    final route = _resolveRoute(message.data);
    if (route != null) AppRouter.router.go(route);
  }

  String? _resolveRoute(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    switch (type) {
      case 'workout':     return AppRouter.workoutPlan;
      case 'achievement': return AppRouter.progress;
      default:            return AppRouter.dashboard;
    }
  }
}
