import 'package:employee_app/employee_flow/location/location_background_service.dart';
import 'package:employee_app/employee_flow/location/location_sync_task.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Background location — check-in par hamesha force refresh.
class FieldLocationController extends GetxController {
  static const String _logTag = '[LocationBG]';
  static void _log(String message) => debugPrint('$_logTag $message');

  /// Service start (background timer). Safe to call multiple times.
  Future<void> start() async {
    _log('FieldLocationController.start()');
    await LocationBackgroundService.start();
  }

  void stop() {
    _log('FieldLocationController.stop()');
    LocationBackgroundService.stop();
  }

  static void stopIfRegistered() {
    if (Get.isRegistered<FieldLocationController>()) {
      Get.find<FieldLocationController>().stop();
    }
  }

  /// Check-in / manual — hamesha turant POST try kare (10 min interval ignore).
  Future<void> refreshNow() async {
    _log('FieldLocationController.refreshNow()');
    await LocationSyncTask.run(force: true);
  }

  /// Check-in ke baad: service + turant location bhejo (retry agar server slow ho).
  Future<void> syncOnCheckIn() async {
    _log('FieldLocationController.syncOnCheckIn()');
    await start();
    await refreshNow();
    final snap = await LocationSyncTask.readSnapshot();
    if (snap.lastError != null || snap.lastSentAt == null) {
      _log('syncOnCheckIn() — retrying after 4s (error=${snap.lastError})');
      await Future.delayed(const Duration(seconds: 4));
      await refreshNow();
    } else {
      _log('syncOnCheckIn() — first sync OK');
    }
  }

  // Face check-in: background service sends location every 10 min until checkout.
}
