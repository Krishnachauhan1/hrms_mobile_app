import 'dart:async';

import 'package:employee_app/hr_flow/location/admin_location_sync.dart';
import 'package:employee_app/hr_flow/models/employee_location_parser.dart';
import 'package:employee_app/hr_flow/models/employee_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class EmployeeDetailsController extends GetxController
    with WidgetsBindingObserver {
  Employee? employee;
  Timer? _timer;

  bool isLoadingLocation = false;
  String? locationError;
  double? latitude;
  double? longitude;
  DateTime? lastLocationAt;
  DateTime? lastFetchedAt;
  List<Map<String, dynamic>> locationHistory = [];

  static const Duration adminPollInterval = Duration(minutes: 1);

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);

    if (Get.arguments != null) {
      employee = Get.arguments as Employee;
    }

    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _timer?.cancel();
    fetchLatestLocation();
    _timer = Timer.periodic(adminPollInterval, (_) {
      fetchLatestLocation();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      fetchLatestLocation();
    }
  }

  Future<void> fetchLatestLocation() async {
    final emp = employee;
    if (emp == null) return;

    final empId = int.tryParse(emp.id);
    if (empId == null) return;

    isLoadingLocation = true;
    locationError = null;
    update();

    try {
      await AdminLocationSync.run();
      final cached = await AdminLocationSync.latestForEmployee(empId);

      if (cached != null) {
        _applyLocation(cached, history: [cached]);
        debugPrint(
          'AdminLocation: cache employee=$empId '
          'latest=${cached['created_at']}',
        );
        return;
      }

      locationError = 'No location found for this employee';
      latitude = null;
      longitude = null;
      lastLocationAt = null;
      locationHistory = [];
    } catch (e) {
      locationError = 'Failed to load location';
      debugPrint('AdminLocation: fetch error — $e');
    } finally {
      isLoadingLocation = false;
      update();
    }
  }

  void _applyLocation(
    Map<String, dynamic> latest, {
    List<Map<String, dynamic>>? history,
  }) {
    latitude = _readDouble(latest['latitude']);
    longitude = _readDouble(latest['longitude']);
    lastLocationAt = EmployeeLocationParser.locationTime(latest);
    lastFetchedAt = DateTime.now();
    locationHistory = history ?? [latest];
    locationError = null;
  }

  double? _readDouble(dynamic raw) {
    if (raw == null) return null;
    return double.tryParse(raw.toString());
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.onClose();
  }
}
