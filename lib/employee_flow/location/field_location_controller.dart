import 'package:employee_app/employee_flow/location/location_background_service.dart';
import 'package:employee_app/employee_flow/location/location_sync_task.dart';
import 'package:get/get.dart';

/// Background location — check-in par hamesha force refresh.
class FieldLocationController extends GetxController {
  bool _isRunning = false;

  /// Service start (background timer). Safe to call multiple times.
  Future<void> start() async {
    _isRunning = true;
    await LocationBackgroundService.start();
  }

  void stop() {
    _isRunning = false;
    LocationBackgroundService.stop();
  }

  static void stopIfRegistered() {
    if (Get.isRegistered<FieldLocationController>()) {
      Get.find<FieldLocationController>().stop();
    }
  }

  /// Check-in / manual — hamesha turant POST try kare (10 min interval ignore).
  Future<void> refreshNow() async {
    await LocationSyncTask.run(force: true);
  }

  /// Check-in ke baad: service + turant location bhejo (retry agar server slow ho).
  Future<void> syncOnCheckIn() async {
    await start();
    await refreshNow();
    final snap = await LocationSyncTask.readSnapshot();
    if (snap.lastError != null || snap.lastSentAt == null) {
      await Future.delayed(const Duration(seconds: 4));
      await refreshNow();
    }
  }

  @override
  void onClose() {
    stop();
    super.onClose();
  }
}
