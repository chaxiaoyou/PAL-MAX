import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Delivers price alerts to the operating system.
///
/// Abstract so the evaluation logic can be tested without a platform channel,
/// and so iOS — where nothing is wired up yet — can be added without touching
/// the callers.
abstract class AlertNotifier {
  /// Whether the system will currently deliver a notification. Never prompts.
  Future<bool> notificationsAllowed();

  /// Prompts for permission when the platform needs it, and reports the answer.
  Future<bool> requestPermission();

  /// Posts one notification. [id] keeps repeated alerts for the same symbol
  /// from stacking up.
  Future<void> notify({
    required int id,
    required String title,
    required String body,
  });
}

/// Android implementation, over a method channel handled by MainActivity.
///
/// Written by hand rather than pulled from a plugin: the app module already
/// talks to Android this way for the home-screen widget, and the toolchain here
/// (AGP 9 / Kotlin 2.4) is new enough that a third-party plugin is a
/// compatibility gamble for something this small.
class PlatformAlertNotifier implements AlertNotifier {
  static const _channel = MethodChannel('NeedhamCapital/alerts');

  @override
  Future<bool> notificationsAllowed() async {
    if (!Platform.isAndroid) return false;
    try {
      final granted = await _channel.invokeMethod<bool>('allowed');
      return granted ?? false;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('alert permission check failed: $error\n$stackTrace');
      }
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      final granted = await _channel.invokeMethod<bool>('request');
      return granted ?? false;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('alert permission request failed: $error\n$stackTrace');
      }
      return false;
    }
  }

  @override
  Future<void> notify({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('notify', {
        'id': id,
        'title': title,
        'body': body,
      });
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('alert notification failed: $error\n$stackTrace');
      }
    }
  }
}
