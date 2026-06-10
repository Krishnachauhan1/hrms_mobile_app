import 'dart:async';
import 'dart:ui';

import 'package:employee_app/employee_flow/location/location_sync_task.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationBackgroundService {
  LocationBackgroundService._();

  static const int _notificationId = 8810;
  static const String _channelId = 'location_tracking';

  static Future<void> initialize() async {
    final notifications = FlutterLocalNotificationsPlugin();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await notifications.initialize(
      settings: const InitializationSettings(
        android: android,
        iOS: ios,
      ),
    );

    await notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            'Location tracking',
            description: 'Updates your work location every 10 minutes',
            importance: Importance.low,
          ),
        );

    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        // If Android kills the process, auto-start helps keep tracking consistent.
        // Tracking is still gated by SharedPreferences flag in LocationSyncTask.
        autoStart: true,
        autoStartOnBoot: true,
        isForegroundMode: true,
        notificationChannelId: _channelId,
        initialNotificationTitle: 'Quick Salary',
        initialNotificationContent: 'Attendance active',
        foregroundServiceNotificationId: _notificationId,
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );
  }

  static Future<void> start() async {
    await _ensureLocationPermissions();
    await LocationSyncTask.setTrackingEnabled(true);
    final service = FlutterBackgroundService();
    if (!await service.isRunning()) {
      await service.startService();
    } else {
      service.invoke('runNow');
    }
    await LocationSyncTask.run(force: true);
  }

  static Future<void> stop() async {
    await LocationSyncTask.setTrackingEnabled(false);
    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      service.invoke('stopService');
    }
  }

  @pragma('vm:entry-point')
  static Future<bool> _onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    await LocationSyncTask.run();
    return true;
  }

  @pragma('vm:entry-point')
  static void _onStart(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    Timer? timer;

    Duration untilNext10MinBoundary() {
      final now = DateTime.now();
      final roundedDown = DateTime(
        now.year,
        now.month,
        now.day,
        now.hour,
        (now.minute ~/ 10) * 10,
      );
      final next = roundedDown.add(const Duration(minutes: 10));
      final diff = next.difference(now);
      // Minimum 5 seconds to avoid tight loops
      if (diff.inSeconds < 5) return const Duration(seconds: 5);
      return diff;
    }

    Future<void> tick({bool force = false}) async {
      if (!await LocationSyncTask.isTrackingEnabled()) {
        service.stopSelf();
        return;
      }
      await LocationSyncTask.run(force: force);
    }

    if (service is AndroidServiceInstance) {
      await service.setAsForegroundService();
    }

    service.on('stopService').listen((_) {
      timer?.cancel();
      service.stopSelf();
    });

    service.on('runNow').listen((_) => tick(force: true));

    await tick(force: true);

    // Align to wall-clock 10-minute boundaries to match admin expectations.
    timer = Timer(untilNext10MinBoundary(), () {
      tick();
      timer = Timer.periodic(LocationSyncTask.refreshInterval, (_) => tick());
    });
  }

  static Future<void> _ensureLocationPermissions() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;

    var status = await Permission.location.status;
    if (!status.isGranted) {
      status = await Permission.location.request();
    }
    if (!status.isGranted) return;

    // Android: "Allow all the time" for updates when app is in background
    final always = await Permission.locationAlways.status;
    if (!always.isGranted) {
      await Permission.locationAlways.request();
    }
  }
}
