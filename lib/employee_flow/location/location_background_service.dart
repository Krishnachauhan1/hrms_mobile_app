import 'dart:async';
import 'dart:ui';

import 'package:employee_app/employee_flow/location/location_sync_task.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationBackgroundService {
  LocationBackgroundService._();

  static const int _notificationId = 8810;
  static const String _channelId = 'location_tracking';
  static const String _logTag = '[LocationBG]';

  static void _log(String message) => debugPrint('$_logTag $message');

  static Future<void> initialize() async {
    _log('initialize() — configuring background service');
    final notifications = FlutterLocalNotificationsPlugin();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await notifications.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
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
    _log('initialize() — done');
  }

  /// Restart the foreground service when tracking was left on (e.g. after OS kill).
  static Future<void> resumeIfNeeded() async {
    final enabled = await LocationSyncTask.isTrackingEnabled();
    _log('resumeIfNeeded() — trackingEnabled=$enabled');
    if (!enabled) return;
    await _ensureLocationPermissions();
    final service = FlutterBackgroundService();
    final running = await service.isRunning();
    _log('resumeIfNeeded() — serviceRunning=$running');
    if (!running) {
      await service.startService();
      _log('resumeIfNeeded() — service started');
    } else {
      service.invoke('runNow');
      _log('resumeIfNeeded() — invoked runNow');
    }
  }

  static Future<void> start() async {
    _log('start() — enabling tracking');
    await _ensureLocationPermissions();
    await LocationSyncTask.setTrackingEnabled(true);
    final service = FlutterBackgroundService();
    final running = await service.isRunning();
    if (!running) {
      await service.startService();
      _log('start() — foreground service started');
    } else {
      service.invoke('runNow');
      _log('start() — service already running, invoked runNow');
    }
    await LocationSyncTask.run(force: true);
  }

  static Future<void> stop() async {
    _log('stop() — disabling tracking');
    await LocationSyncTask.setTrackingEnabled(false);
    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      service.invoke('stopService');
      _log('stop() — stopService invoked');
    } else {
      _log('stop() — service was not running');
    }
  }

  @pragma('vm:entry-point')
  static Future<bool> _onIosBackground(ServiceInstance service) async {
    _log('iOS background wake — running sync');
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    await LocationSyncTask.run();
    _log('iOS background wake — sync finished');
    return true;
  }

  @pragma('vm:entry-point')
  static void _onStart(ServiceInstance service) async {
    _log('service onStart — isolate started');
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
      _log('tick(force=$force) — started');
      if (!await LocationSyncTask.isTrackingEnabled()) {
        _log('tick() — tracking disabled, stopping service');
        timer?.cancel();
        service.stopSelf();
        return;
      }
      await LocationSyncTask.run(force: force);
      if (service is AndroidServiceInstance) {
        final snap = await LocationSyncTask.readSnapshot();
        final sent = snap.lastSentAt?.toLocal().toString().split('.').first ??
            'pending';
        service.setForegroundNotificationInfo(
          title: 'Quick Salary',
          content: snap.hasCoordinates
              ? 'Location active · ${snap.coordinatesText} · $sent'
              : 'Attendance location active · last sync $sent',
        );
        _log(
          'tick() — notification updated · coords=${snap.coordinatesText} · '
          'lastSent=$sent · error=${snap.lastError ?? "none"}',
        );
      }
      _log('tick(force=$force) — finished');
    }

    if (service is AndroidServiceInstance) {
      await service.setAsForegroundService();
      _log('service onStart — Android foreground mode active');
    }

    service.on('stopService').listen((_) {
      _log('stopService event received');
      timer?.cancel();
      service.stopSelf();
    });

    service.on('runNow').listen((_) {
      _log('runNow event received');
      tick(force: true);
    });

    await tick(force: true);

    final firstDelay = untilNext10MinBoundary();
    _log(
      'timer scheduled — first tick in ${firstDelay.inMinutes}m '
      '${firstDelay.inSeconds % 60}s, then every '
      '${LocationSyncTask.refreshInterval.inMinutes} min',
    );
    // Align to wall-clock 10-minute boundaries to match admin expectations.
    timer = Timer(firstDelay, () {
      tick();
      timer = Timer.periodic(LocationSyncTask.refreshInterval, (_) => tick());
    });
  }

  static Future<void> _ensureLocationPermissions() async {
    final gpsOn = await Geolocator.isLocationServiceEnabled();
    _log('permissions — GPS enabled=$gpsOn');
    if (!gpsOn) return;

    var status = await Permission.location.status;
    _log('permissions — location=$status');
    if (!status.isGranted) {
      status = await Permission.location.request();
      _log('permissions — location after request=$status');
    }
    if (!status.isGranted) return;

    // Android: "Allow all the time" for updates when app is in background
    final always = await Permission.locationAlways.status;
    _log('permissions — locationAlways=$always');
    if (!always.isGranted) {
      final requested = await Permission.locationAlways.request();
      _log('permissions — locationAlways after request=$requested');
    }
  }
}
