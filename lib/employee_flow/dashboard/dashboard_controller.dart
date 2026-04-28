import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:employee_app/api_service.dart';
import 'package:employee_app/apis.dart';
import 'package:employee_app/authentication/auth_controller.dart';
import 'package:http/http.dart' as http;

class DashboardController extends GetxController {
  String employeeName = '';
  bool uploadImage = true;
  String employeeInitials = '';
  String employeeRole = '';
  bool isLoadingProfile = false;
  int? employeeId;

  String todayStatus = '';
  String checkInTime = '';
  String checkOutTime = '';
  String workingHours = '';
  bool isLoadingToday = false;

  int presentDays = 0;
  int absentDays = 0;
  int leaveDays = 0;
  bool isLoadingStats = false;

  int monthlyDays = 0;
  double monthlyHours = 0;
  bool isLoadingMonthly = false;

  int totalDays = 0;
  double totalHours = 0;
  bool isLoadingTotal = false;

  List<Map<String, dynamic>> upcomingLeaves = [];
  bool isLoadingLeaves = false;
  bool isLoggingOut = false;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  Future<void> refreshDashboard() async {
    await Future.wait([
      _fetchTodayFromHistory(),
      fetchAttendanceStats(),
      fetchUpcomingLeaves(),
    ]);
  }

  Future<void> loadDashboardData() async {
    employeeId = await ApiService.getEmployeeId();

    if (employeeId != null) {
      final authController = Get.find<AuthController>();
      employeeName = authController.employee?['name']?.toString() ?? 'Employee';
      // print('emplyee data ${authController.employee?['face_embedding']}');
      uploadImage = authController.employee?['face_embedding'] == null
          ? true
          : false;
      employeeInitials = _generateInitials(employeeName);
      employeeRole =
          authController.employee?['role']?.toString() ??
          authController.employee?['designation']?.toString() ??
          'Employee';
      _safeUpdate();
    }

    await Future.wait([
      fetchProfile(),
      _fetchTodayFromHistory(),
      fetchAttendanceStats(),
      fetchUpcomingLeaves(),
      fetchMonthlyAttendance(),
      fetchTotalAttendance(),
    ]);
  }

  Future<void> fetchProfile() async {
    final id = employeeId;
    if (id == null) return;

    isLoadingProfile = true;
    _safeUpdate();

    try {
      final dynamic res = await ApiService.get(Apis.attendanceStatus(id));
      // print('attendanceStatus response is ====== $res');

      if (res is Map<String, dynamic>) {
        final auth = Get.find<AuthController>().employee;
        employeeName =
            res['employee_name'] ?? auth?['name']?.toString() ?? 'Employee';
        employeeRole =
            auth?['role']?.toString() ??
            auth?['designation']?.toString() ??
            'Employee';
        employeeInitials = _generateInitials(employeeName);
        final rawStatus = res['status']?.toString() ?? '';
        if (rawStatus.isNotEmpty) {
          todayStatus = formatStatus(rawStatus);
        }
      }
    } catch (e) {
      // print(' fetchProfile==== $e');
    }

    isLoadingProfile = false;
    _safeUpdate();
  }

  Future<void> _fetchTodayFromHistory() async {
    final id = employeeId;
    if (id == null) return;
    isLoadingToday = true;
    _safeUpdate();
    try {
      final dynamic res = await ApiService.get(Apis.attendanceHistory(id));

      List<dynamic> rawList = [];
      if (res is Map && res['data'] is List) {
        rawList = res['data'] as List<dynamic>;
      } else if (res is List) {
        rawList = res;
      }

      final todayStr = DateTime.now().toUtc().toString().substring(0, 10);
      final todayLocal = DateTime.now().toString().substring(0, 10);

      // print(
      //   'Looking for date====== $todayStr or $todayLocal, employeeId........ $id',
      // );
      Map<String, dynamic>? todayRecord;
      for (final item in rawList) {
        final map = item as Map<String, dynamic>;
        final empObj = map['employee'];
        final empId = empObj is Map
            ? empObj['id']?.toString()
            : map['employee_id']?.toString();

        if (empId != id.toString()) continue;
        final loginAt = map['login_at']?.toString() ?? '';
        if (loginAt.startsWith(todayStr) || loginAt.startsWith(todayLocal)) {
          todayRecord = map;
          // print('Today record found====== $todayRecord');
          break;
        }
      }

      if (todayRecord != null) {
        final loginAt = todayRecord['login_at']?.toString();
        checkInTime = loginAt != null && loginAt.isNotEmpty
            ? _formatTime(loginAt)
            : '--:-- --';

        final logoutAt = todayRecord['logout_at']?.toString();
        checkOutTime = logoutAt != null && logoutAt.isNotEmpty
            ? _formatTime(logoutAt)
            : '--:-- --';

        final rawHours = todayRecord['total_work_hours'];
        if (rawHours != null && rawHours.toString() != 'null') {
          workingHours = _formatHours(rawHours);
        } else if (loginAt != null && logoutAt != null) {
          try {
            final diff = DateTime.parse(
              logoutAt,
            ).difference(DateTime.parse(loginAt));
            final h = diff.inHours;
            final m = diff.inMinutes % 60;
            workingHours =
                '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} hrs';
          } catch (_) {
            workingHours = '0:00 hrs';
          }
        } else {
          if (loginAt != null) {
            try {
              final diff = DateTime.now().difference(DateTime.parse(loginAt));
              final h = diff.inHours;
              final m = diff.inMinutes % 60;
              workingHours =
                  '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} hrs';
            } catch (_) {
              workingHours = '0:00 hrs';
            }
          } else {
            workingHours = '0:00 hrs';
          }
        }
        if (todayStatus.isEmpty) {
          todayStatus = logoutAt != null && logoutAt.isNotEmpty
              ? 'Checked Out'
              : 'Checked In';
        }
        final empObj = todayRecord['employee'];
        if (empObj is Map && employeeName.isEmpty) {
          employeeName = empObj['name']?.toString() ?? 'Employee';
          employeeInitials = _generateInitials(employeeName);
        }

        // print(' checkInTime=== $checkInTime');
        // print(' checkOutTime===$checkOutTime');
        // print(' workingHours=== $workingHours');
        // print('todayStatus=== $todayStatus');
      } else {
        print('No today record found for employee $id');
        checkInTime = 'Not Mark';
        checkOutTime = '--:-- --';
        workingHours = '0:00 hrs';
        if (todayStatus.isEmpty) todayStatus = 'Not Marked';
      }
    } catch (e) {
      print('fetchTodayFromHistory=== $e');
      checkInTime = '--:-- --';
      workingHours = '0:00 hrs';
    }

    isLoadingToday = false;
    _safeUpdate();
  }

  Future<void> fetchAttendanceStats() async {
    final id = employeeId;
    if (id == null) return;
    isLoadingStats = true;
    _safeUpdate();
    try {
      final dynamic res = await ApiService.get(Apis.attendanceHistory(id));
      // print('fetching the attendance stats response is == $res');
      List<dynamic> rawList = [];
      if (res is Map && res['data'] is List) {
        rawList = res['data'] as List<dynamic>;
      } else if (res is List) {
        rawList = res;
      }
      presentDays = 0;
      absentDays = 0;
      leaveDays = 0;
      final Set<String> counted = {};
      for (final item in rawList) {
        final map = item as Map<String, dynamic>;
        final empObj = map['employee'];
        final empId = empObj is Map
            ? empObj['id']?.toString()
            : map['employee_id']?.toString();
        if (empId != id.toString()) continue;
        final loginAt = map['login_at']?.toString() ?? '';
        final dateKey = loginAt.isNotEmpty
            ? loginAt.substring(0, 10)
            : map['date']?.toString() ?? '';
        if (dateKey.isEmpty || counted.contains(dateKey)) continue;
        counted.add(dateKey);
        if (loginAt.isNotEmpty) {
          presentDays++;
        }
      }

      // print('present $presentDays');
    } catch (e) {
      // print('fetchAttendanceStats== $e');
    }

    isLoadingStats = false;
    _safeUpdate();
  }

  Future<void> fetchMonthlyAttendance() async {
    isLoadingMonthly = true;
    _safeUpdate();

    try {
      final res = await ApiService.get(Apis.attendanceMonthly);
      print('Monthly user attendace data is === $res');
      if (res != null && res['success'] == true) {
        monthlyDays = res['total_days'] ?? 0;
        monthlyHours = double.parse(
          (double.tryParse(res['total_hours'].toString()) ?? 0).toStringAsFixed(
            2,
          ),
        );
      }
    } catch (e) {
      // print(' fetchMonthlyAttendance  === $e');
    }

    isLoadingMonthly = false;
    _safeUpdate();
  }

  // Total Attendance
  Future<void> fetchTotalAttendance() async {
    isLoadingTotal = true;
    _safeUpdate();

    try {
      final res = await ApiService.get(Apis.attendanceTotal);
      // print('Total user working days ??/response $res');
      if (res != null && res['success'] == true) {
        totalDays = res['total_attendance_days'] ?? 0;
        totalHours = double.tryParse(res['total_work_hours'].toString()) ?? 0;
        if (workingHours == '0:00 hrs' || workingHours.isEmpty) {
          workingHours = _formatHours(totalHours);
        }
      }
    } catch (e) {
      // print('fetchTotalAttendance: $e');
    }

    isLoadingTotal = false;
    _safeUpdate();
  }

  // Upcoming Leaves
  Future<void> fetchUpcomingLeaves() async {
    isLoadingLeaves = true;
    _safeUpdate();

    try {
      final dynamic res = await ApiService.get(Apis.leaveApplications);
      List<dynamic> rawList = [];
      if (res is List) {
        rawList = res;
      } else if (res is Map && res['data'] != null) {
        rawList = res['data'] as List<dynamic>;
      }

      final today = DateTime.now();
      final filtered =
          rawList.map((e) => e as Map<String, dynamic>).where((item) {
            final fromDateRaw = item['from_date'] as String? ?? '';
            try {
              final fromDate = DateTime.parse(fromDateRaw);
              final status = (item['status'] as String? ?? '').toLowerCase();
              return !fromDate.isBefore(today) &&
                  (status == 'approved' || status == 'pending');
            } catch (_) {
              return false;
            }
          }).toList()..sort((a, b) {
            final aDate = DateTime.tryParse(a['from_date'] ?? '') ?? today;
            final bDate = DateTime.tryParse(b['from_date'] ?? '') ?? today;
            return aDate.compareTo(bDate);
          });
      upcomingLeaves = filtered.map((item) {
        final typeRaw = item['leave_type'];
        final typeName = typeRaw is Map
            ? (typeRaw['name'] as String? ?? 'Leave')
            : (item['leave_type_name'] as String? ?? 'Leave');

        final fromDate = item['from_date'] as String? ?? '';
        final toDate = item['to_date'] as String? ?? '';
        int days = 1;
        try {
          final from = DateTime.parse(fromDate);
          final to = DateTime.parse(toDate);
          days = to.difference(from).inDays + 1;
        } catch (_) {}

        final displayDate = fromDate == toDate
            ? _formatDisplayDate(fromDate)
            : '${_formatDisplayDate(fromDate)} - ${_formatDisplayDate(toDate)}';

        return {
          'type': typeName,
          'date': displayDate,
          'duration': '$days ${days == 1 ? "day" : "days"}',
          'status': _capitalize(item['status'] as String? ?? ''),
        };
      }).toList();
    } catch (e) {
      // print('fetchUpcomingLeaves $e');
    }

    isLoadingLeaves = false;
    _safeUpdate();
  }

  // Logout
  Future<void> logout() async {
    isLoggingOut = true;
    update();
    try {
      await ApiService.clearToken();
      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar(
        'Error',
        'Logout failed. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoggingOut = false;
      update();
    }
  }

  //  Helpers
  String _generateInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatTime(String raw) {
    try {
      final date = DateTime.parse(raw).toLocal();
      int hour = date.hour;
      final minute = date.minute.toString().padLeft(2, '0');
      final suffix = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      return '${hour.toString().padLeft(2, '0')}:$minute $suffix';
    } catch (_) {
      return raw;
    }
  }

  String _formatHours(dynamic raw) {
    try {
      if (raw is String && raw.contains(':')) {
        final parts = raw.split(':');
        return '${parts[0]}:${parts[1]} hrs';
      }
      final total = double.parse(raw.toString());
      final hours = total.floor();
      final minutes = ((total - hours) * 60).round();
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')} hrs';
    } catch (_) {
      return '$raw hrs';
    }
  }

  String _formatDisplayDate(String raw) {
    try {
      final d = DateTime.parse(raw);
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
      return raw;
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'checked_in':
      case 'logged_in':
        return 'Checked In';
      case 'checked_out':
      case 'logged_out':
        return 'Checked Out';
      case 'not_logged_in':
        return 'Login Pending';
      case 'absent':
        return 'Absent';
      default:
        return 'Not Marked';
    }
  }

  Future<void> uploadProfileImage(File imageFile) async {
    try {
      final token = await ApiService.getToken();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://quicksalary.org/api/upload-profile-image'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.files.add(
        await http.MultipartFile.fromPath('profile_image', imageFile.path),
      );

      var response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('Status: ${response.statusCode}');
      print('Response: $responseBody');
      if (response.statusCode == 200) {
        Get.snackbar(
          "Success",
          "Image uploaded successfully",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          "Error",
          "Unable to upload image. Please try again.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Something went wrong: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<File?> pickImageFromCamera() async {
    final picker = ImagePicker();

    final XFile? image = await picker.pickImage(
      source: ImageSource.camera, // ❗ no gallery
      imageQuality: 80,
    );

    if (image == null) return null;
    return File(image.path);
  }

  Color get todayStatusColor {
    switch (todayStatus.toLowerCase()) {
      case 'checked in':
      case 'logged in':
        return Colors.white;
      case 'checked out':
        return const Color(0xFFFFD700);
      case 'absent':
        return const Color(0xFFFF7675);
      case 'not marked':
      case 'login pending':
        return const Color(0xFFFDAA2B);
      default:
        return Colors.white;
    }
  }

  Color leaveColor(int index) {
    const colors = [
      Color(0xFF6C5CE7),
      Color(0xFFFF7675),
      Color(0xFF00B894),
      Color(0xFFFDAA2B),
    ];
    return colors[index % colors.length];
  }

  void _safeUpdate() {
    if (!isClosed) update();
  }
}
