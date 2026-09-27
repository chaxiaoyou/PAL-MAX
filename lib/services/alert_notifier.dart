import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Copy for one alert notification, already localized by the caller.
///
/// Android shows the channel name in system settings, so it travels with the
/// notification rather than being baked in when the service is constructed —
/// the service has no `BuildContext` and must not guess a language.
class AlertNotification {
  const AlertNotification({
    required this.title,
    required this.body,
    required this.channelName,
    required this.channelDescription,
  });

  final String title;
  final String body;
  final String channelName;
  final String channelDescription;
}

/// Delivery of price-alert notifications.
///
/// An interface rather than a direct plugin call so the trigger pipeline can be
/// tested without a platform channel, and so a future push/server path can be
/// dropped in without touching the shell.
abstract class AlertNotifier {
  /// Asks for the platform permission, returning whether notifications may be
  /// posted. Idempotent: the OS answers without prompting once decided.
  Future<bool> ensurePermission();

  Future<void> show(int id, AlertNotification notification);
}

/// `flutter_local_notifications` implementation.
class LocalAlertNotifier implements AlertNotifier {
  LocalAlertNotifier([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const _channelId = 'price_alerts';

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          // Permission is requested explicitly in `ensurePermission` so the
          // prompt appears when the user creates their first rule, not on
          // launch.
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialized = true;
  }

  @override
  Future<bool> ensurePermission() async {
    await _ensureInitialized();

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    // Desktop and tests: nothing to ask for.
    return true;
  }

  @override
  Future<void> show(int id, AlertNotification notification) async {
    await _ensureInitialized();
    await _plugin.show(
      id: id,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          notification.channelName,
          channelDescription: notification.channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}

final alertNotifierProvider = Provider<AlertNotifier>(
  (ref) => LocalAlertNotifier(),
);
