import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:employee_app/employee_flow/employee_permission_controller.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:employee_app/api_service.dart';
import 'package:employee_app/apis.dart';
import 'package:intl/intl.dart';

class AttendanceRecord {
  final String date;
  // final String? loginTime;
  // final String? logoutTime;
  final String loginAt;
  final String? logoutAt;
  final String? totalHours;
  final bool isPresent;
  final String status;

  AttendanceRecord({
    required this.date,
    // this.loginTime,
    // this.logoutTime,
    required this.loginAt,
    this.logoutAt,
    this.totalHours,
    required this.isPresent,
    this.status = '',
  });

  static AttendanceRecord? tryFromJson(Map<String, dynamic> json) {
    try {
      final loginAt = json['login_at'] as String?;
      if (loginAt == null || loginAt.isEmpty) return null;

      final loginRaw =
          json['login_time'] ?? json['login_at'] ?? json['check_in'];
      final logoutRaw =
          json['logout_time'] ?? json['logout_at'] ?? json['check_out'];
      final bool present = loginRaw != null;
      String? totalHours;
      if (loginRaw != null && logoutRaw != null) {
        totalHours =
            json['total_work_hours']?.toString() ??
            _calcHours(loginRaw, logoutRaw);
      }

      return AttendanceRecord(
        date: loginRaw ?? '',
        loginAt: loginAt,
        logoutAt: json['logout_at'] as String?,
        totalHours: totalHours,
        isPresent: present,
      );
    } catch (e) {
      print("AttendanceRecord.tryFromJson error: $e | data: $json");
      return null;
    }
  }

  // static String _formatTime(String raw) {
  //   try {
  //     if (raw.contains('T') || (raw.contains('-') && raw.length > 8)) {
  //       final dt = DateTime.parse(raw).toLocal();
  //       int h = dt.hour;
  //       final m = dt.minute.toString().padLeft(2, '0');
  //       final suffix = h >= 12 ? 'PM' : 'AM';
  //       if (h > 12) h -= 12;
  //       if (h == 0) h = 12;
  //       return '${h.toString().padLeft(2, '0')}:$m $suffix';
  //     }
  //     final parts = raw.split(':');
  //     int h = int.parse(parts[0]);
  //     final m = parts[1];
  //     final suffix = h >= 12 ? 'PM' : 'AM';
  //     if (h > 12) h -= 12;
  //     if (h == 0) h = 12;
  //     return '${h.toString().padLeft(2, '0')}:$m $suffix';
  //   } catch (_) {
  //     return raw;
  //   }
  // }

  static String _calcHours(String login, String logout) {
    try {
      int inMin, outMin;
      if (login.contains('T') || (login.contains('-') && login.length > 8)) {
        final inDt = DateTime.parse(login).toLocal();
        final outDt = DateTime.parse(logout).toLocal();
        inMin = inDt.hour * 60 + inDt.minute;
        outMin = outDt.hour * 60 + outDt.minute;
      } else {
        final lIn = login.split(':');
        final lOut = logout.split(':');
        inMin = int.parse(lIn[0]) * 60 + int.parse(lIn[1]);
        outMin = int.parse(lOut[0]) * 60 + int.parse(lOut[1]);
      }
      final diff = outMin - inMin;
      if (diff <= 0) return '';
      return '${diff ~/ 60}h ${diff % 60}m';
    } catch (_) {
      return '';
    }
  }

  String get displayDate {
    try {
      final d = DateTime.parse(date);
      const months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[d.month]} ${d.day.toString().padLeft(2, '0')}, ${d.year}';
    } catch (_) {
      return date;
    }
  }
}

class AttendanceController extends GetxController with WidgetsBindingObserver {
  int? employeeId;

  // Camera
  CameraController? cameraController;
  bool isCameraInitialized = false;
  bool isCameraReady = false;
  bool _isCameraDisposed = true;
  bool isCameraOpen = false;

  // QR Scanner state
  bool isQrScannerOpen = false;
  String? lastScannedQrData;
  bool isProcessingQr = false;

  // UI State
  bool isScanning = false;
  bool isCapturing = false;
  bool isRecognized = false;
  String? errorMessage;
  String? markedTime;
  bool isCheckedIn = false;

  // Today Record
  Map<String, dynamic>? todayRecord = {};
  bool isLoadingToday = false;
  Map<String, dynamic>? shiftData;
  // History
  List<AttendanceRecord> historyList = [];
  bool isLoadingHistory = false;

  Map<String, dynamic>? attendanceResult;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    employeeId = await ApiService.getEmployeeId();
    if (employeeId == null) {
      errorMessage = 'Employee ID not found. Please login again.';
      _safeUpdate();
      return;
    }
    await Future.wait([
      checkAttendanceStatus(),
      fetchTodayAttendance(),
      fetchAttendanceHistory(),
    ]);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _safeDisposeCamera();
    } else if (state == AppLifecycleState.resumed && isCameraOpen) {
      _initCamera();
    }
  }

  void openQrScanner() {
    if (isProcessingQr) return;
    isQrScannerOpen = true;
    lastScannedQrData = null;
    errorMessage = null;
    _safeUpdate();
  }

  void closeQrScanner() {
    isQrScannerOpen = false;
    isProcessingQr = false;
    _safeUpdate();
  }

  Future<void> onQrScanned(String qrData) async {
    if (qrData.isEmpty) return;

    isProcessingQr = true;
    _safeUpdate();

    try {
      await checkAttendanceStatus();
      await fetchAttendanceHistory();
      await fetchShift();
      if (shiftData == null) {
        await assignShift(employeeId!);
        await fetchShift();
        _showError("Shift not assigned. Contact admin.");
        return;
      }
      if (!isCheckedIn) {
        isCheckedIn = isUserLoggedIn;
      }
      final decoded = jsonDecode(qrData);
      final qrToken = decoded["qr_token"];

      if (isCheckedIn) {
        print(" User already logged in → logging OUT");
        await _markLogoutWithQr(qrToken);
      } else {
        print("User not logged in → logging IN");
        await _markLoginWithQr(qrToken);
      }
    } catch (e) {
      _showError("QR Error: $e");
    } finally {
      isProcessingQr = false;
      _safeUpdate();
    }
  }

  Future<bool> assignShift(int employeeId) async {
    try {
      final res = await ApiService.post(
        "/shift",
        body: {
          'employee_id': employeeId,
          'shift_start_time': '09:00:00',
          'shift_end_time': '18:00:00',
          'late_grace_minutes': 15,
          'half_day_hours': 4,
          'overtime_after_hours': 8,
        },
        isAuth: true,
      );

      print("AUTO SHIFT RESPONSE: $res");
      return res['success'] == true;
    } catch (e) {
      if (e.toString().contains("Shift setting not found")) {
        _showError("Logout allowed but shift missing (backend issue)");
        await _markLogout();
        return false;
      }

      print("assignShift error: $e");
      return false;
    }
  }

  Future<void> openCameraForScan() async {
    if (isCameraOpen) return;
    isCameraOpen = true;
    _safeUpdate();
    await _initCamera();
  }

  Future<void> _closeCamera() async {
    isCameraOpen = false;
    await _safeDisposeCamera();
    _safeUpdate();
  }

  Future<void> _initCamera() async {
    if (!_isCameraDisposed &&
        cameraController != null &&
        cameraController!.value.isInitialized) {
      return;
    }

    _isCameraDisposed = false;
    isCameraInitialized = false;
    isCameraReady = false;
    _safeUpdate();

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        errorMessage = 'No camera found on this device.';
        isCameraOpen = false;
        _safeUpdate();
        return;
      }

      final frontCamera =
          cameras.firstWhereOrNull(
            (c) => c.lensDirection == CameraLensDirection.front,
          ) ??
          cameras.first;
      await _safeDisposeCamera(skipFlagReset: true);
      if (isClosed) return;

      _isCameraDisposed = false;
      cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await cameraController!.initialize();
      if (_isCameraDisposed || isClosed) {
        await _safeDisposeCamera();
        return;
      }

      isCameraInitialized = true;
      isCameraReady = true;
      errorMessage = null;
      _safeUpdate();
    } on CameraException catch (e) {
      final desc = e.description ?? 'Unknown camera error';
      if (desc.toLowerCase().contains('permission')) {
        errorMessage = 'Camera permission denied. Please enable in settings.';
      } else {
        errorMessage = 'Camera error: $desc';
      }
      isCameraReady = false;
      isCameraOpen = false;
      _isCameraDisposed = true;
      _safeUpdate();
    } catch (e) {
      errorMessage = 'Camera unavailable. Please try again.';
      isCameraReady = false;
      isCameraOpen = false;
      _isCameraDisposed = true;
      _safeUpdate();
    }
  }

  Future<void> _safeDisposeCamera({bool skipFlagReset = false}) async {
    if (_isCameraDisposed && !skipFlagReset) return;
    _isCameraDisposed = true;
    if (!skipFlagReset) {
      isCameraInitialized = false;
      isCameraReady = false;
    }
    final ctrl = cameraController;
    cameraController = null;
    try {
      await ctrl?.dispose();
    } catch (_) {}
  }

  Future<String?> _capturePhoto() async {
    const maxWait = 5000;
    int waited = 0;
    while (waited < maxWait) {
      if (cameraController != null &&
          cameraController!.value.isInitialized &&
          !_isCameraDisposed) {
        break;
      }
      await Future.delayed(const Duration(milliseconds: 300));
      waited += 300;
    }

    if (cameraController == null ||
        !cameraController!.value.isInitialized ||
        _isCameraDisposed) {
      errorMessage = 'Camera not ready. Please try again.';
      _safeUpdate();
      return null;
    }

    try {
      isCapturing = true;
      _safeUpdate();
      await Future.delayed(const Duration(milliseconds: 800));
      final XFile photo = await cameraController!.takePicture();
      isCapturing = false;
      _safeUpdate();
      return photo.path;
    } on CameraException catch (e) {
      isCapturing = false;
      errorMessage = 'Photo capture failed: ${e.description}';
      _safeUpdate();
      return null;
    } catch (e) {
      isCapturing = false;
      _safeUpdate();
      return null;
    }
  }

  Future<Position?> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        errorMessage = 'Location services are disabled.';
        _safeUpdate();
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        errorMessage = 'Location permission denied.';
        _safeUpdate();
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          errorMessage = 'Location timed out. Check GPS signal.';
          _safeUpdate();
          throw Exception('Location timeout');
        },
      );
    } catch (e) {
      errorMessage = 'Could not get location. Try again.';
      _safeUpdate();
      return null;
    }
  }

  Future<void> startCheckIn() async {
    if (isScanning) return;

    errorMessage = null;

    _safeUpdate();

    await openCameraForScan();

    await Future.delayed(const Duration(milliseconds: 800));

    await _markLogin();

    if (isUserLoggedIn) {
      print("Already logged in");

      return;
    }
  }

  Future<void> startCheckOut() async {
    if (isScanning) return;
    errorMessage = null;
    _safeUpdate();
    await openCameraForScan();
    await Future.delayed(const Duration(milliseconds: 800));
    await _markLogout();
  }

  Future<void> markFaceCheckIn(String imagePath) async {
    final employeeId = await ApiService.getEmployeeId();

    final featureCtrl = Get.find<EmployeeFeatureController>();

    if (!featureCtrl.canUseFace) {
      _showError("Face recognition access denied");

      return;
    }

    await _markLogin(imagePath: imagePath);
  }

  Future<void> markFaceCheckOut(String imagePath) async {
    final employeeId = await ApiService.getEmployeeId();
    final featureCtrl = Get.find<EmployeeFeatureController>();

    if (!featureCtrl.canUseFace) {
      _showError("Face recognition access denied");

      return;
    }

    await _markLogout(imagePath: imagePath);
  }

  Future<void> _markLogin({
    String? imagePath,
    Map<String, String> extraFields = const {},
  }) async {
    isScanning = true;
    _safeUpdate();
    try {
      final position = await _getLocation();
      if (position == null) {
        isScanning = false;
        await _closeCamera();
        return;
      }
      // if (position.accuracy > 50) {
      //   errorMessage = "Low GPS accuracy. Move to open area.";
      //   isScanning = false;
      //   await _closeCamera();
      //   _safeUpdate();
      //   return;
      // }

      final fields = {
        'login_type': extraFields.containsKey('qr_code') ? 'qr' : 'face',
        'latitude': position.latitude.toString(),
        'longitude': position.longitude.toString(),
        ...extraFields,
      };
      print("==========LATITUDE==========${position.latitude}");
      print("=======LONGITUDE ===== ${position.longitude}");
      print("==========ACCURACY=========${position.accuracy}");
      final dynamic response = await ApiService.postMultipart(
        Apis.attendanceLogin,
        fields: fields,
        filePath: imagePath ?? '',
        fileField: 'image',
      );
      print('user attendance postion of ===$response');
      attendanceResult = response as Map<String, dynamic>;
      markedTime = TimeOfDay.now().format(Get.context!);
      isCheckedIn = true;
      isScanning = false;
      isRecognized = true;
      await _closeCamera();
      _safeUpdate();
      _showSuccess('Punched IN at $markedTime');
      await fetchTodayAttendance();
      await fetchAttendanceHistory();
      await checkAttendanceStatus();
      await Future.delayed(const Duration(seconds: 3));
      if (isClosed) return;
      isRecognized = false;
      _safeUpdate();
    } on ApiException catch (e) {
      isScanning = false;
      await _closeCamera();
      if (e.statusCode == 400 && e.message.toLowerCase().contains('logout')) {
        isCheckedIn = true;
        _safeUpdate();
        _showError('Already checked in. Tap Logout to punch out.');
      } else {
        errorMessage = e.message;
        _safeUpdate();
        _showError(e.message);
      }
    } catch (e) {
      isScanning = false;
      await _closeCamera();
      errorMessage = 'Check-in failed. Try again.';
      _safeUpdate();
      _showError(errorMessage!);
    } finally {
      isProcessingQr = false;
    }
  }

  Future<void> _markLogout({
    String? imagePath,
    Map<String, String> extraFields = const {},
  }) async {
    isScanning = true;
    _safeUpdate();
    try {
      final position = await _getLocation();
      if (position == null) {
        isScanning = false;
        await _closeCamera();
        return;
      }

      final fields = {
        'latitude': position.latitude.toString(),
        'longitude': position.longitude.toString(),
        ...extraFields,
      };

      await ApiService.postMultipart(
        Apis.attendanceLogout,
        fields: fields,
        filePath: imagePath ?? '',
        fileField: 'image',
      );

      isCheckedIn = false;
      isScanning = false;
      isRecognized = true;
      markedTime = TimeOfDay.now().format(Get.context!);
      await _closeCamera();
      _safeUpdate();
      _showSuccess('Punched Out at $markedTime');
      await fetchTodayAttendance();
      await fetchAttendanceHistory();
      await Future.delayed(const Duration(seconds: 3));
      if (isClosed) return;
      isRecognized = false;
      _safeUpdate();
    } on ApiException catch (e) {
      print("the logot user error is ====$e");
      isScanning = false;
      await _closeCamera();
      errorMessage = e.message;
      _safeUpdate();
      _showError(e.message);
    } catch (e) {
      print("the logot user error message is ====$e");
      isScanning = false;
      await _closeCamera();
      errorMessage = 'Check-out failed. Try again.';
      _safeUpdate();
      _showError(errorMessage!);
    }
  }

  Future<void> uploadProfileImage(String path) async {
    await ApiService.postMultipart(
      '/api/upload-profile-image',
      fields: {},
      filePath: path,
      fileField: 'profile_image',
    );
  }

  Future<void> _markLoginWithQr(String qrData) async {
    try {
      isProcessingQr = true;
      _safeUpdate();
      final employeeId = await ApiService.getEmployeeId();
      if (employeeId == null) {
        _showError("Employee ID not found");
        return;
      }
      final position = await _getLocation();
      if (position == null) return;

      final response = await ApiService.post(
        Apis.employeeloginbyQR,
        body: {
          "qr_token": qrData,
          "latitude": position.latitude.toString(),
          "longitude": position.longitude.toString(),
          "employee_id": employeeId,
        },
        isAuth: true,
      );
      print("QR LOGIN RESPONSE ======= $response");
      isCheckedIn = true;
      markedTime = TimeOfDay.now().format(Get.context!);
      _showSuccess("QR Check-In Successful");
      await fetchTodayAttendance();
      await fetchAttendanceHistory();
    } catch (e) {
      if (e.toString().contains("logout first")) {
        isCheckedIn = true;
        _showError("Already checked in. Please scan again to logout.");
      } else {
        _showError("QR Login Failed: ${e.toString()}");
      }
    } finally {
      isProcessingQr = false;
      _safeUpdate();
    }
  }

  Future<void> _markLogoutWithQr(String qrData) async {
    try {
      isProcessingQr = true;
      _safeUpdate();
      final employeeId = await ApiService.getEmployeeId();
      if (employeeId == null) {
        _showError("Employee ID not found");
        return;
      }
      final position = await _getLocation();

      final response = await ApiService.post(
        Apis.employeelogoutbyQR,
        body: {
          "qr_token": qrData,
          "employee_id": employeeId,
          "latitude": position!.latitude.toString(),
          "longitude": position.longitude.toString(),
        },
        isAuth: true,
      );
      print("QR LOGOUT RESPONSE ======== $response");
      isCheckedIn = false;
      markedTime = TimeOfDay.now().format(Get.context!);
      _showSuccess("QR Check-Out Successful");
      await fetchTodayAttendance();
      await fetchAttendanceHistory();
    } catch (e) {
      print("QR Logout Error: $e");
      _showError("QR Logout Failed: ${e.toString()}");
    } finally {
      isProcessingQr = false;
      _safeUpdate();
    }
  }

  Future<void> fetchShift() async {
    if (employeeId == null) return;
    final res = await getShift(employeeId!);
    if (res != null && res['success'] == true) {
      final List list = res['data'];
      final filtered = list.where((e) {
        return e['employee_id'] == employeeId;
      }).toList();
      if (filtered.isNotEmpty) {
        shiftData = filtered.first;
      } else {
        shiftData = null;
      }
    } else {
      shiftData = null;
    }
  }

  bool checkTodayLoggedIn(List<AttendanceRecord> list) {
    final today = DateTime.now();

    for (var item in list) {
      final login = DateTime.parse(item.loginAt).toLocal();

      if (login.year == today.year &&
          login.month == today.month &&
          login.day == today.day) {
        // Agar logout null hai → still logged in
        if (item.logoutAt == null) {
          return true;
        }
      }
    }

    return false;
  }

  Future<void> checkAttendanceStatus() async {
    final id = employeeId;
    if (id == null) return;
    try {
      final res = await ApiService.get(Apis.attendanceStatus(id));
      if (res is Map) {
        final status = (res['status'] ?? '').toString().toLowerCase();
        const checkedInStatuses = {'checked_in', 'logged_in', 'present'};
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
          print("Unknown status: '$status' — falling back to history");
          isCheckedIn = isUserLoggedIn;
        }
      }
    } catch (e) {
      debugPrint('Status check error: $e');
      isCheckedIn = isUserLoggedIn;
    } finally {
      _safeUpdate();
    }
  }

  Future<void> fetchTodayAttendance() async {
    isLoadingToday = true;
    _safeUpdate();
    try {
      final dynamic response = await ApiService.get(Apis.attendanceToday);
      if (response is Map<String, dynamic>) {
        todayRecord = response['data'] is Map
            ? response['data'] as Map<String, dynamic>
            : response;
      }
    } catch (e) {
      debugPrint('Today attendance error: $e');
    } finally {
      isLoadingToday = false;
      _safeUpdate();
    }
  }

  Future<void> fetchAttendanceHistory() async {
    final id = employeeId;
    if (id == null) return;
    isLoadingHistory = true;
    _safeUpdate();
    try {
      final dynamic response = await ApiService.get(Apis.attendanceHistory(id));
      List<dynamic> rawList = [];
      if (response is List) {
        rawList = response;
      } else if (response is Map && response['data'] != null) {
        rawList = response['data'] as List<dynamic>;
      }

      historyList = rawList
          .cast<Map<String, dynamic>>()
          .where((e) {
            final empId = e['employee']?['id'];
            return empId == id;
          })
          .map((e) => AttendanceRecord.tryFromJson(e))
          .whereType<AttendanceRecord>()
          .toList();
      print("Current Employee ID: $employeeId");
      print("Latest record employee: ${historyList.first.loginAt}");
      print("Latest logout: ${historyList.first.logoutAt}");
      historyList.sort((a, b) {
        try {
          return DateTime.parse(b.loginAt).compareTo(DateTime.parse(a.loginAt));
        } catch (_) {
          return 0;
        }
      });
    } catch (e) {
      debugPrint('History fetch error: $e');
    } finally {
      isLoadingHistory = false;
      _safeUpdate();
    }
  }

  bool get isUserLoggedIn {
    if (historyList.isEmpty) return false;

    final latest = historyList.first;
    return latest.logoutAt == null;
  }

  String formatWorkHours(String hoursStr) {
    final hours = double.tryParse(hoursStr) ?? 0;
    final totalMinutes = (hours * 60).round();
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;

    if (h > 0) {
      return "$h h $m min";
    } else {
      return "$m min";
    }
  }

  String formatDateTime(String dateTime) {
    final dt = DateTime.parse(dateTime).toLocal();
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }

  void _safeUpdate() {
    if (!isClosed) update();
  }

  void _showSuccess(String msg) => Get.snackbar(
    'Success!',
    msg,
    backgroundColor: const Color(0xFF00B894),
    colorText: Colors.white,
    snackPosition: SnackPosition.TOP,
    borderRadius: 12,
    margin: const EdgeInsets.all(16),
    duration: const Duration(seconds: 3),
  );

  void _showError(String msg) => Get.snackbar(
    'Error',
    msg,
    backgroundColor: const Color(0xFFFF7675),
    colorText: Colors.white,
    snackPosition: SnackPosition.TOP,
    borderRadius: 12,
    margin: const EdgeInsets.all(16),
  );

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _safeDisposeCamera();
    super.onClose();
  }
}
