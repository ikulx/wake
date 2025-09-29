import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class AlarmService {
  AlarmService._();

  static final AlarmService instance = AlarmService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const int _alarmNotificationId = 1001;

  Future<void> init(
    void Function(NotificationResponse) onNotificationResponse,
  ) async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  @pragma('vm:entry-point')
  static void notificationTapBackground(NotificationResponse response) {
    debugPrint('Notification tapped in background: ${response.payload}');
  }

  Future<void> scheduleAlarm({
    required tz.TZDateTime scheduledDate,
    required bool repeats,
  }) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'wake_guard_alarm_channel',
      'Alarme',
      channelDescription: 'Benachrichtigungen für WakeGuard Alarme',
      priority: Priority.high,
      importance: Importance.max,
      playSound: true,
      fullScreenIntent: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentSound: true,
      presentAlert: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      _alarmNotificationId,
      'WakeGuard Alarm',
      'Zeit zum Aufstehen! Scanne den Code zum Stoppen.',
      scheduledDate,
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents:
          repeats ? DateTimeComponents.time : null,
    );
  }

  Future<void> cancelAlarm() async {
    await _notificationsPlugin.cancel(_alarmNotificationId);
  }
}
