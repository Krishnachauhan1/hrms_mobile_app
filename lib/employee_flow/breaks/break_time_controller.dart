import 'package:employee_app/api_service.dart';
import 'package:employee_app/apis.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class BreakTypeOption {
  final dynamic id;
  final String name;
  final int durationMinutes;

  BreakTypeOption({
    required this.id,
    required this.name,
    required this.durationMinutes,
  });

  factory BreakTypeOption.fromJson(Map<String, dynamic> json) {
    return BreakTypeOption(
      id: json['id'] ?? json['organization_break_type_id'],
      name: json['name']?.toString() ?? 'Break',
      durationMinutes:
          int.tryParse(json['duration_minutes']?.toString() ?? '0') ?? 0,
    );
  }

  String get durationLabel =>
      durationMinutes > 0 ? '$durationMinutes min' : 'No limit';
}

class BreakTimeController extends GetxController {
  final _timeFmt = DateFormat('h:mm a');

  bool isLoading = true;
  bool isSubmitting = false;

  bool isCheckedIn = false;
  bool isOnBreak = false;
  String? loginAt;
  String? logoutAt;
  String? breakStartAt;
  String? activeBreakTypeName;

  List<BreakTypeOption> breakTypes = [];
  BreakTypeOption? selectedBreakType;

  String? errorMessage;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    isLoading = true;
    errorMessage = null;
    update();
    await Future.wait([
      _fetchAttendanceState(),
      fetchBreakTypes(),
      _fetchActiveBreak(),
    ]);
    isLoading = false;
    update();
  }

  void selectBreakType(BreakTypeOption? type) {
    selectedBreakType = type;
    update();
  }

  Future<void> _fetchAttendanceState() async {
    try {
      final id = await ApiService.getEmployeeId();
      if (id == null) return;

      final res = await ApiService.get(Apis.attendanceStatus(id));
      if (res is! Map) return;

      final data = res['data'] is Map
          ? Map<String, dynamic>.from(res['data'] as Map)
          : res;

      final status = (data['status'] ?? '').toString().toLowerCase();
      const checkedInStatuses = {
        'checked_in',
        'logged_in',
        'present',
        'on_duty',
      };
      const checkedOutStatuses = {
        'checked_out',
        'logged_out',
        'absent',
        'not_checked_in',
      };

      if (checkedInStatuses.contains(status)) {
        isCheckedIn = true;
      } else if (checkedOutStatuses.contains(status)) {
        isCheckedIn = false;
      } else {
        isCheckedIn =
            data['is_checked_in'] == true ||
            data['checked_in'] == true ||
            data['is_logged_in'] == true ||
            (data['login_at'] != null &&
                (data['logout_at'] == null ||
                    data['logout_at'].toString().isEmpty));
      }

      loginAt = data['login_at']?.toString();
      logoutAt = data['logout_at']?.toString();
    } catch (e) {
      debugPrint('attendance status: $e');
      await _fetchTodayFallback();
    }
  }

  Future<void> _fetchTodayFallback() async {
    try {
      final res = await ApiService.get(Apis.attendanceToday);
      if (res is! Map) return;
      final raw = res['data'];
      final list = raw is List ? raw : (raw is Map ? [raw] : <dynamic>[]);
      if (list.isEmpty) {
        isCheckedIn = false;
        return;
      }
      final today = list.first;
      if (today is! Map) return;
      final map = Map<String, dynamic>.from(today);
      loginAt = map['login_at']?.toString();
      logoutAt = map['logout_at']?.toString();
      isCheckedIn =
          loginAt != null &&
          loginAt!.isNotEmpty &&
          (logoutAt == null || logoutAt!.isEmpty);
    } catch (e) {
      debugPrint('attendance today: $e');
    }
  }

  Future<void> fetchBreakTypes() async {
    try {
      final res = await ApiService.get(Apis.breakTypes);
      final list = _extractList(res, keys: ['data', 'break_types', 'types']);
      breakTypes = list
          .where((e) => _isActive(e))
          .map((e) => BreakTypeOption.fromJson(e))
          .toList();
      if (selectedBreakType != null &&
          !breakTypes.any((t) => t.id == selectedBreakType!.id)) {
        selectedBreakType = breakTypes.isNotEmpty ? breakTypes.first : null;
      } else if (selectedBreakType == null && breakTypes.isNotEmpty) {
        selectedBreakType = breakTypes.first;
      }
    } catch (e) {
      debugPrint('fetchBreakTypes: $e');
      breakTypes = [];
    }
  }

  Future<void> _fetchActiveBreak() async {
    try {
      final res = await ApiService.get(Apis.breaksToday);
      final list = _extractList(res, keys: ['data', 'breaks']);
      if (list.isEmpty) {
        isOnBreak = false;
        breakStartAt = null;
        activeBreakTypeName = null;
        return;
      }

      final id = await ApiService.getEmployeeId();
      Map<String, dynamic>? mine;
      for (final item in list) {
        final map = Map<String, dynamic>.from(item);
        final empId =
            map['employee_id'] ??
            (map['employee'] is Map ? map['employee']['id'] : null);
        if (id != null && empId != null && empId.toString() != id.toString()) {
          continue;
        }
        mine = map;
        break;
      }
      mine ??= Map<String, dynamic>.from(list.first);

      final start = mine['break_start'] ?? mine['started_at'];
      final end = mine['break_end'] ?? mine['ended_at'];
      final status = mine['break_status']?.toString().toLowerCase();

      isOnBreak =
          status == 'on_break' ||
          status == 'active' ||
          (start != null &&
              start.toString().isNotEmpty &&
              (end == null || end.toString().isEmpty));

      breakStartAt = start?.toString();
      activeBreakTypeName =
          mine['break_type_name']?.toString() ??
          (mine['organization_break_type'] is Map
              ? mine['organization_break_type']['name']?.toString()
              : null);

      if (isOnBreak && breakTypes.isNotEmpty) {
        final typeId =
            mine['organization_break_type_id'] ?? mine['break_type_id'];
        try {
          selectedBreakType = breakTypes.firstWhere(
            (t) => t.id.toString() == typeId.toString(),
          );
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('fetchActiveBreak: $e');
    }
  }

  Future<Position?> _getLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError('Please enable location services.');
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _showError('Location permission is required.');
      return null;
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
  }

  Future<void> punchIn() async {
    if (isSubmitting) return;
    isSubmitting = true;
    update();
    try {
      final position = await _getLocation();
      if (position == null) {
        isSubmitting = false;
        update();
        return;
      }

      // Backend accepts login_type: face | qr (not "app")
      final res = await ApiService.postMultipart(
        Apis.attendanceLogin,
        fields: {
          'login_type': 'face',
          'latitude': position.latitude.toString(),
          'longitude': position.longitude.toString(),
        },
        filePath: '',
      );

      if (res != null && _isSuccess(res)) {
        isCheckedIn = true;
        loginAt = DateTime.now().toIso8601String();
        logoutAt = null;
        _showSuccess(_msg(res, 'Checked in successfully'));
        await loadAll();
      } else {
        _showError(_msg(res, 'Check-in failed'));
      }
    } on ApiException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('logout') ||
          msg.contains('already') ||
          msg.contains('logged in') ||
          e.statusCode == 400) {
        isCheckedIn = true;
        _showError('You are already checked in.');
        await loadAll();
      } else if (msg.contains('login type') || msg.contains('login_type')) {
        _showError('Use Attendance tab for face/QR check-in, or contact HR.');
      } else {
        _showError(e.message);
      }
    } catch (e) {
      _showError('Check-in failed. Try again.');
      debugPrint('punchIn: $e');
    }
    isSubmitting = false;
    update();
  }

  Future<void> punchOut() async {
    if (isOnBreak) {
      _showError('End your break before checking out.');
      return;
    }
    if (isSubmitting) return;
    isSubmitting = true;
    update();
    try {
      final position = await _getLocation();
      if (position == null) {
        isSubmitting = false;
        update();
        return;
      }

      final res = await ApiService.postMultipart(
        Apis.attendanceLogout,
        fields: {
          'latitude': position.latitude.toString(),
          'longitude': position.longitude.toString(),
        },
        filePath: '',
      );

      if (res != null && _isSuccess(res)) {
        isCheckedIn = false;
        isOnBreak = false;
        logoutAt = DateTime.now().toIso8601String();
        _showSuccess(_msg(res, 'Checked out successfully'));
        await loadAll();
      } else {
        _showError(_msg(res, 'Check-out failed'));
      }
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Check-out failed. Try again.');
      debugPrint('punchOut: $e');
    }
    isSubmitting = false;
    update();
  }

  Future<void> startBreak() async {
    if (!isCheckedIn) {
      _showError('Please check in before starting a break.');
      return;
    }
    if (isOnBreak) {
      _showError('You are already on a break.');
      return;
    }
    if (selectedBreakType == null) {
      _showError('Please select a break type.');
      return;
    }
    if (isSubmitting) return;

    isSubmitting = true;
    update();
    try {
      final res = await ApiService.post(
        Apis.breaksStart,
        body: {
          'organization_break_type_id': selectedBreakType!.id is int
              ? selectedBreakType!.id
              : int.tryParse(selectedBreakType!.id.toString()) ??
                    selectedBreakType!.id,
        },
      );

      if (_isSuccess(res)) {
        isOnBreak = true;
        breakStartAt = DateTime.now().toIso8601String();
        activeBreakTypeName = selectedBreakType!.name;
        _showSuccess(_msg(res, 'Break started'));
        await _fetchActiveBreak();
      } else {
        _showError(_msg(res, 'Could not start break'));
      }
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Could not start break.');
      debugPrint('startBreak: $e');
    }
    isSubmitting = false;
    update();
  }

  Future<void> endBreak() async {
    if (!isOnBreak) {
      _showError('No active break to end.');
      return;
    }
    if (isSubmitting) return;

    isSubmitting = true;
    update();
    try {
      final res = await ApiService.post(Apis.breaksEnd, body: {});

      if (_isSuccess(res)) {
        isOnBreak = false;
        breakStartAt = null;
        activeBreakTypeName = null;
        _showSuccess(_msg(res, 'Break ended'));
        await _fetchActiveBreak();
      } else {
        _showError(_msg(res, 'Could not end break'));
      }
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Could not end break.');
      debugPrint('endBreak: $e');
    }
    isSubmitting = false;
    update();
  }

  String formatTime(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      return _timeFmt.format(DateTime.parse(raw).toLocal());
    } catch (_) {
      return raw;
    }
  }

  String? get breakElapsed {
    if (!isOnBreak || breakStartAt == null) return null;
    try {
      final start = DateTime.parse(breakStartAt!).toLocal();
      final diff = DateTime.now().difference(start);
      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      if (h > 0) return '${h}h ${m}m';
      return '${m}m';
    } catch (_) {
      return null;
    }
  }

  bool _isActive(Map<String, dynamic> b) {
    final v = b['is_active'];
    if (v == null) return true;
    if (v is bool) return v;
    if (v is int) return v == 1;
    return v.toString() != '0' && v.toString().toLowerCase() != 'false';
  }

  bool _isSuccess(dynamic res) =>
      res is Map && (res['success'] == true || res['status'] == true);

  String _msg(dynamic res, String fallback) {
    if (res is Map && res['message'] != null) {
      return res['message'].toString();
    }
    return fallback;
  }

  List<Map<String, dynamic>> _extractList(
    dynamic raw, {
    required List<String> keys,
  }) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (raw is Map) {
      for (final k in keys) {
        if (raw[k] is List) {
          return (raw[k] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
    }
    return [];
  }

  void _showSuccess(String msg) {
    Get.snackbar(
      'Success',
      msg,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFDCFCE7),
      colorText: const Color(0xFF16A34A),
      margin: const EdgeInsets.all(16),
      borderRadius: 10,
    );
  }

  void _showError(String msg) {
    Get.snackbar(
      'Error',
      msg,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFFEE2E2),
      colorText: const Color(0xFFDC2626),
      margin: const EdgeInsets.all(16),
      borderRadius: 10,
    );
  }
}
