import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'screens/alarm_ringing_screen.dart';
import 'screens/home_screen.dart';
import 'services/alarm_service.dart';
import 'services/storage_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  debugPrint('Background notification tap: ${notificationResponse.payload}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureLocalTimeZone();
  await StorageService.instance.init();
  await AlarmService.instance.init(_handleNotificationResponse);

  runApp(const WakeGuardApp());
}

Future<void> _configureLocalTimeZone() async {
  tz.initializeTimeZones();
  final String timeZoneName = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timeZoneName));
}

void _handleNotificationResponse(NotificationResponse response) {
  navigatorKey.currentState?.pushAndRemoveUntil(
    MaterialPageRoute<void>(
      builder: (_) => const AlarmRingingScreen(),
      settings: const RouteSettings(name: AlarmRingingScreen.routeName),
    ),
    (route) => false,
  );
}

class WakeGuardApp extends StatelessWidget {
  const WakeGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WakeGuard',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      routes: const {
        AlarmRingingScreen.routeName: AlarmRingingScreen.route,
      },
    );
  }
}
