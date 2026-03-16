import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:employee_app/api_service.dart';
import 'package:employee_app/apis.dart';

// Model
class AttendanceRecord {
  final String date;
  final String? loginTime;
  final String? logoutTime;
  final String? totalHours;
  final bool isPresent;
  final String status;

  AttendanceRecord({
    required this.date,
    this.loginTime,
    this.logoutTime,
    this.totalHours,
    required this.isPresent,
    this.status = '',
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['status'] as String? ?? '').toLowerCase();
    final bool present =
        rawStatus.contains('logged') ||
        rawStatus.contains('present') ||
        rawStatus == 'checked_in' ||
        rawStatus == 'checked_out' ||
        rawStatus == 'half_day' ||
        (json['is_present'] == true);

    final loginRaw =
        json['login_time'] as String? ??
        json['login_at'] as String? ??
        json['check_in'] as String?;

    final logoutRaw =
        json['logout_time'] as String? ??
        json['logout_at'] as String? ??
        json['check_out'] as String?;

    String? totalHours;
    if (loginRaw != null && logoutRaw != null) {
      totalHours =
          json['total_hours'] as String? ??
          json['total_work_hours'] as String? ??
          _calcHours(loginRaw, logoutRaw);
    }

    return AttendanceRecord(
      date: json['date'] as String? ?? '',
      loginTime: loginRaw != null ? _formatTime(loginRaw) : null,
      logoutTime: logoutRaw != null ? _formatTime(logoutRaw) : null,
      totalHours: totalHours,
      isPresent: present,
      status: rawStatus,
    );
  }

  static String _formatTime(String raw) {
    try {
      if (raw.contains('T') || (raw.contains('-') && raw.length > 8)) {
        final dt = DateTime.parse(raw).toLocal();
        int h = dt.hour;
        final m = dt.minute.toString().padLeft(2, '0');
        final suffix = h >= 12 ? 'PM' : 'AM';
        if (h > 12) h -= 12;
        if (h == 0) h = 12;
        return '${h.toString().padLeft(2, '0')}:$m $suffix';
      }
      final parts = raw.split(':');
      int h = int.parse(parts[0]);
      final m = parts[1];
      final suffix = h >= 12 ? 'PM' : 'AM';
      if (h > 12) h -= 12;
      if (h == 0) h = 12;
      return '${h.toString().padLeft(2, '0')}:$m $suffix';
    } catch (_) {
      return raw;
    }
  }

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

  //  Camera
  CameraController? cameraController;
  bool isCameraInitialized = false;
  bool isCameraReady = false;
  bool _isCameraDisposed = false;
  bool isCameraOpen = false;

  // UI State
  bool isScanning = false;
  bool isCapturing = false;
  bool isRecognized = false;
  String? errorMessage;
  String? markedTime;
  bool isCheckedIn = false;

  //  Today Record
  Map<String, dynamic>? todayRecord = {};
  bool isLoadingToday = false;

  //  History
  List<AttendanceRecord> historyList = [];
  bool isLoadingHistory = false;

  Map<String, dynamic>? attendanceResult;
  String? viewMode;
  VoidCallback toggleViewMode = () {};
  DateTime? selectedDate;

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

  // Lifecycle
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _safeDisposeCamera();
    }
  }

  // Camera
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
    _isCameraDisposed = false;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        errorMessage = 'No camera found.';
        isCameraOpen = false;
        _safeUpdate();
        return;
      }

      final frontCamera =
          cameras.firstWhereOrNull(
            (c) => c.lensDirection == CameraLensDirection.front,
          ) ??
          cameras.first;

      await _safeDisposeCamera();
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
      errorMessage = 'Camera error: ${e.description}';
      isCameraReady = false;
      isCameraOpen = false;
      _safeUpdate();
    } catch (e) {
      errorMessage = 'Camera not available.';
      isCameraReady = false;
      isCameraOpen = false;
      _safeUpdate();
    }
  }

  Future<void> _safeDisposeCamera() async {
    if (_isCameraDisposed) return;
    _isCameraDisposed = true;
    isCameraInitialized = false;
    isCameraReady = false;
    try {
      await cameraController?.dispose();
    } catch (_) {
    } finally {
      cameraController = null;
    }
  }

  // Photo capture
  Future<String?> _capturePhoto() async {
    int waited = 0;
    while ((cameraController == null ||
            !cameraController!.value.isInitialized) &&
        waited < 4000) {
      await Future.delayed(const Duration(milliseconds: 200));
      waited += 200;
    }
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return null;
    }

    try {
      isCapturing = true;
      _safeUpdate();
      await Future.delayed(const Duration(milliseconds: 600));
      final XFile photo = await cameraController!.takePicture();
      isCapturing = false;
      _safeUpdate();
      return photo.path;
    } catch (e) {
      isCapturing = false;
      _safeUpdate();
      return null;
    }
  }

  // Location
  Future<Position?> _getLocation() async {
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
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // Public actions
  Future<void> startCheckIn() async {
    if (isScanning) return;
    errorMessage = null;
    _safeUpdate();
    await openCameraForScan();
    await _markLogin();
  }

  Future<void> startCheckOut() async {
    if (isScanning) return;
    errorMessage = null;
    _safeUpdate();
    await openCameraForScan();
    await _markLogout();
  }

  // PUCH IN
  Future<void> _markLogin() async {
    isScanning = true;
    _safeUpdate();
    try {
      final position = await _getLocation();
      if (position == null) {
        isScanning = false;
        await _closeCamera();
        return;
      }
      // camera ready hone ka wait
      final photoPath = await _capturePhoto();
      if (photoPath == null) {
        errorMessage = 'Could not capture photo. Please try again.';
        isScanning = false;
        await _closeCamera();
        _safeUpdate();
        return;
      }
      final dynamic response = await ApiService.postMultipart(
        Apis.attendanceLogin,
        fields: {
          'login_type': 'face',
          'latitude': position.latitude.toString(),
          'longitude': position.longitude.toString(),
        },
        filePath: photoPath,
        fileField: 'photo',
      );
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
      errorMessage = 'Something went wrong. Try again.';
      _safeUpdate();
      _showError('Network error. Check your connection.');
    }
  }

  // PUNCH OUT
  Future<void> _markLogout() async {
    isScanning = true;
    _safeUpdate();

    try {
      final position = await _getLocation();
      if (position == null) {
        isScanning = false;
        await _closeCamera();
        _safeUpdate();
        return;
      }

      //  basic photo capture
      final photoPath = await _capturePhoto();
      if (photoPath == null) {
        errorMessage = 'Could not capture photo. Please try again.';
        isScanning = false;
        await _closeCamera();
        _safeUpdate();
        return;
      }

      final dynamic response = await ApiService.postMultipart(
        Apis.attendanceLogout,
        fields: {
          'latitude': position.latitude.toString(),
          'longitude': position.longitude.toString(),
        },
        filePath: photoPath,
        fileField: 'photo',
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
      isScanning = false;
      await _closeCamera();
      errorMessage = e.message;
      _safeUpdate();
      _showError(e.message);
    } catch (e) {
      isScanning = false;
      await _closeCamera();
      errorMessage = 'Logout failed. Try again.';
      _safeUpdate();
      _showError('Network error. Check your connection.');
    }
  }

  //ATTENDANCE STATUS
  // Future<void> checkAttendanceStatus() async {
  //   final id = employeeId;
  //   if (id == null) return;
  //   try {
  //     final res = await ApiService.get(Apis.attendanceStatus(id));
  //     print('employees attendance status.................. $res');

  //     if (res is Map) {
  //       isCheckedIn =
  //           res['checked_in'] ??
  //           res['data']?['checked_in'] ??
  //           res['is_checked_in'] ??
  //           false;

  //       final status = (res['status'] as String? ?? '').toLowerCase();
  //       if (status.isNotEmpty) {
  //         isCheckedIn =
  //             isCheckedIn ||
  //             status == 'checked_in' ||
  //             status.contains('logged_in');
  //       }
  //     }
  //     print('employee isCheckedIn ==================== $isCheckedIn');
  //     _safeUpdate();
  //   } catch (e) {
  //     print('error in status................ $e');
  //   }
  // }
  Future<void> checkAttendanceStatus() async {
    final id = employeeId;
    if (id == null) return;

    try {
      final res = await ApiService.get(Apis.attendanceStatus(id));
      if (res is Map) {
        final status = (res['status'] ?? '').toString().toLowerCase();
        switch (status) {
          case 'checked_in':
          case 'logged_in':
          case 'present':
            isCheckedIn = true;
            break;
          case 'not_logged_in':
          case 'absent':
          default:
            isCheckedIn = false;
        }
      }
      _safeUpdate();
    } catch (e) {
      print(e);
    }
  }
  // TODAY ATTENDACE

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
      isLoadingToday = false;
      _safeUpdate();
    } catch (e) {
      isLoadingToday = false;
      _safeUpdate();
    }
  }

  //  History

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

      // Debug: har record print karo
      for (final r in rawList) {
        print('look the employee record............ $r');
      }

      historyList = rawList
          .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
          .toList();

      // Latest pehle
      historyList.sort((a, b) => b.date.compareTo(a.date));
      for (final r in historyList) {
        print(' ${r.date} | ${r.status} | present:${r.isPresent}');
      }

      isLoadingHistory = false;
      _safeUpdate();
    } catch (e) {
      isLoadingHistory = false;
      _safeUpdate();
    }
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
