import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Phase 6 — schedules real OS notifications for planner reminders (local only;
/// cross-device sync is a later phase). Every method is defensive: notification
/// failures must never crash the app or block planner edits.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const String _channelId = 'planner_reminders';
  static const String _channelName = 'Reminders';
  static const String _channelDescription =
      'Reminders for the goals and tasks in your planner.';

  /// Initializes the plugin (idempotent). The caller initializes the timezone
  /// database before this so [scheduleReminder] can build a [tz.TZDateTime].
  Future<void> init() async {
    if (_initialized) return;
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      // Permissions are requested explicitly later, not at init.
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        settings: const InitializationSettings(android: android, iOS: darwin),
      );
      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService init failed: $e');
    }
  }

  /// Asks the user for permission (Android 13+ POST_NOTIFICATIONS / iOS prompt).
  Future<bool> requestPermission() async {
    try {
      await init();
      if (defaultTargetPlatform == TargetPlatform.android) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        return await android?.requestNotificationsPermission() ?? false;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final ios = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        return await ios?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
      return false;
    } catch (e) {
      debugPrint('NotificationService permission request failed: $e');
      return false;
    }
  }

  /// Schedules a one-off reminder at [dueAt]. No-ops for past times. Uses an
  /// inexact schedule so we don't need the special exact-alarm permission.
  Future<void> scheduleReminder({
    required String planId,
    required String title,
    String? body,
    required DateTime dueAt,
  }) async {
    try {
      await init();
      final scheduled = tz.TZDateTime.from(dueAt, tz.local);
      if (!scheduled.isAfter(tz.TZDateTime.now(tz.local))) return;

      await _plugin.zonedSchedule(
        id: notificationIdFor(planId),
        title: title,
        body: body,
        scheduledDate: scheduled,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('NotificationService schedule failed: $e');
    }
  }

  Future<void> cancel(String planId) async {
    try {
      await _plugin.cancel(id: notificationIdFor(planId));
    } catch (e) {
      debugPrint('NotificationService cancel failed: $e');
    }
  }

  /// Maps a plan's UUID string to a stable, non-negative 32-bit notification id.
  static int notificationIdFor(String planId) => planId.hashCode & 0x7fffffff;
}
