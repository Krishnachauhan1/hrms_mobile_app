import 'dart:async';

import 'package:employee_app/api_service.dart';
import 'package:employee_app/apis.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

class FieldLocationController extends GetxController
    with WidgetsBindingObserver {
  static const Duration refreshInterval = Duration(minutes: 10);

  Timer? _timer;
  Position? lastPosition;
  int? _employeeId;
  bool _isCheckedIn = false;
  bool _isRunning = false;
  DateTime? _lastSentAt;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> start() async {
    if (_isRunning) return;

    _employeeId = await ApiService.getEmployeeId();
    if (_employeeId == null) return;

    _isRunning = true;
    _timer?.cancel();
    await _refreshLocation(force: true);

    _timer = Timer.periodic(refreshInterval, (_) => _refreshLocation());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _isCheckedIn = false;
    _lastSentAt = null;
  }

  static void stopIfRegistered() {
    if (Get.isRegistered<FieldLocationController>()) {
      Get.find<FieldLocationController>().stop();
    }
  }

  Future<void> refreshNow() => _refreshLocation(force: true);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isRunning) return;
    if (state == AppLifecycleState.resumed) {
      final last = _lastSentAt;
      if (last == null || DateTime.now().difference(last) >= refreshInterval) {
        _refreshLocation(force: true);
      }
    }
  }

  Future<void> _refreshLocation({bool force = false}) async {
    _employeeId ??= await ApiService.getEmployeeId();
    final id = _employeeId;
    if (id == null) return;

    await _updateCheckInStatus(id);

    if (!_isCheckedIn) return;

    if (!force &&
        _lastSentAt != null &&
        DateTime.now().difference(_lastSentAt!) < refreshInterval) {
      return;
    }

    final position = await _getCurrentPosition();
    if (position == null) return;

    lastPosition = position;
    await _sendToServer(id, position);
    _lastSentAt = DateTime.now();
  }

  Future<void> _updateCheckInStatus(int employeeId) async {
    try {
      final res = await ApiService.get(Apis.attendanceStatus(employeeId));
      if (res is! Map) return;

      final status = (res['status'] ?? '').toString().toLowerCase();
      const checkedIn = {'checked_in', 'logged_in', 'present'};
      const checkedOut = {
        'checked_out',
        'logged_out',
        'absent',
        'not_checked_in',
        'not_logged_in',
      };

      if (checkedIn.contains(status)) {
        _isCheckedIn = true;
      } else if (checkedOut.contains(status)) {
        _isCheckedIn = false;
      }
    } catch (e) {
      debugPrint('FieldLocation: status check failed — $e');
    }
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } catch (e) {
      debugPrint('FieldLocation: position error — $e');
      return null;
    }
  }

  Future<void> _sendToServer(int employeeId, Position position) async {
    try {
      final orgId =
          int.tryParse(await ApiService.getOrganizationId() ?? '0') ?? 0;

      await ApiService.addEmployeeLocation(
        organizationId: orgId,
        employeeId: employeeId,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on ApiException catch (e) {
      debugPrint('FieldLocation: API error — ${e.message}');
    } catch (e) {
      debugPrint('FieldLocation: send failed — $e');
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    stop();
    super.onClose();
  }
}
