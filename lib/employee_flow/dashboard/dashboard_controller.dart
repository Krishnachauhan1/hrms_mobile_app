import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:employee_app/api_service.dart';
import 'package:employee_app/apis.dart';
import 'package:employee_app/authentication/auth_controller.dart';

class DashboardController extends GetxController {
  String employeeName = '';
  String employeeInitials = '';
  String employeeRole = '';
  bool isLoadingProfile = false;
  int? employeeId;

  String todayStatus = '';
  String checkInTime = '';
  String workingHours = '';
  bool isLoadingToday = false;
  bool isLoggingOut = false;

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

  @override
  void onInit() {
    super.onInit();
    _loadDashboardData();
    fetchMonthlyAttendance();
    fetchTotalAttendance();
  }

  Future<void> refreshDashboard() async {
    await Future.wait([
      fetchTodayAttendance(),
      fetchAttendanceStats(),
      fetchUpcomingLeaves(),
    ]);
  }

  Future<void> _loadDashboardData() async {
    final authController = Get.find<AuthController>();
    employeeId =
        ApiService.extractEmployeeId(authController.employee) ??
        await ApiService.getEmployeeId();

    if (employeeId == null) {
      print('Dashboard: employeeId not found');
      employeeName = authController.employee?['name']?.toString() ?? 'Employee';
      employeeInitials = _generateInitials(employeeName);
      employeeRole =
          authController.employee?['role']?.toString() ??
          authController.employee?['designation']?.toString() ??
          'Employee';
      _safeUpdate();
      return;
    }

    await Future.wait([
      fetchProfile(),
      fetchTodayAttendance(),
      fetchAttendanceStats(),
      fetchUpcomingLeaves(),
    ]);
  }

  Future<void> fetchProfile() async {
    final id = employeeId;
    if (id == null) return;

    isLoadingProfile = true;
    _safeUpdate();

    try {
      final dynamic response = await ApiService.get(Apis.attendanceStatus(id));
      print('Profile response🤩🤩🤩🤩🤩🤩🤩🤩🤩🤩🤩🤩🤩🤩🤩🤩🤩🤩🤩 $response');

      if (response is Map<String, dynamic>) {
        final authEmployee = Get.find<AuthController>().employee;
        employeeName =
            response['employee_name'] ??
            authEmployee?['name']?.toString() ??
            'Employee';
        employeeRole =
            authEmployee?['role']?.toString() ??
            authEmployee?['designation']?.toString() ??
            'Employee';
        employeeInitials = _generateInitials(employeeName);
      }

      isLoadingProfile = false;
      _safeUpdate();
    } catch (e) {
      print('❌ Profile error: $e');
      isLoadingProfile = false;
      _safeUpdate();
    }
  }

  // Today Attendance

  Future<void> fetchTodayAttendance() async {
    print('📅 Dashboard: GET today → ${Apis.baseUrl}${Apis.attendanceToday}');
    isLoadingToday = true;
    _safeUpdate();

    try {
      final dynamic response = await ApiService.get(Apis.attendanceToday);
      print('📅 ✅ Response: $response');

      Map<String, dynamic> data = {};

      if (response is Map<String, dynamic>) {
        final raw = response['data'];

        if (raw is List) {
          final employee = raw.firstWhereOrNull((e) {
            final eId = e['employee_id'];
            return eId?.toString() == employeeId?.toString();
          });

          if (employee != null) {
            data = employee as Map<String, dynamic>;
            print('📅Found employee record: $data');
          } else {
            print('📅 Employee not found in list. IDs in list:');
            for (final e in raw) {
              print(
                '  → employee_id: ${e['employee_id']} (${e['employee_id'].runtimeType})',
              );
            }
            print('  → looking for: $employeeId (${employeeId.runtimeType})');
          }
        } else if (raw is Map<String, dynamic>) {
          data = raw;
        } else {
          data = response;
        }
      }

      // Status
      final rawStatus = data['status'] as String? ?? '';
      todayStatus = rawStatus.isEmpty
          ? 'Not Marked'
          : rawStatus
                .replaceAll('_', ' ')
                .split(' ')
                .map(_capitalize)
                .join(' ');

      // Check-in time
      final rawLogin =
          data['login_at'] as String? ??
          data['login_time'] as String? ??
          data['check_in'] as String? ??
          '';
      checkInTime = rawLogin.isEmpty ? '--:-- --' : _formatTime(rawLogin);

      // Working hours
      final rawHours = data['total_work_hours'] ?? data['total_hours'];
      if (rawHours != null) {
        workingHours = _formatHours(rawHours);
      } else {
        final login = data['login_at'] ?? data['login_time'];
        final logout = data['logout_at'] ?? data['logout_time'];
        if (login != null && logout != null) {
          try {
            final diff = DateTime.parse(
              logout,
            ).difference(DateTime.parse(login));
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

      print(
        '📅 status: $todayStatus | checkIn: $checkInTime | hours: $workingHours',
      );

      isLoadingToday = false;
      _safeUpdate();
    } on ApiException catch (e) {
      print('📅 ❌ ${e.statusCode}: ${e.message}');
      if (e.statusCode == 404) {
        todayStatus = 'Not Marked';
        checkInTime = '--:-- --';
        workingHours = '0:00 hrs';
      }
      isLoadingToday = false;
      _safeUpdate();
    } catch (e) {
      print('📅 ❌ $e');
      isLoadingToday = false;
      _safeUpdate();
    }
  }

  Future<void> fetchMonthlyAttendance() async {
    print(
      '📅 Dashboard: GET monthly → ${Apis.baseUrl}${Apis.attendanceMonthly}',
    );

    isLoadingMonthly = true;
    update();

    try {
      final response = await ApiService.get(Apis.attendanceMonthly);

      print("📅 Monthly Response: $response");

      if (response != null && response['success'] == true) {
        monthlyDays = response['total_days'] ?? 0;
        monthlyHours = double.tryParse(response['total_hours'].toString()) ?? 0;
      }
    } catch (e) {
      print("❌ Monthly error $e");
    }

    isLoadingMonthly = false;
    update();
  }

  Future<void> fetchTotalAttendance() async {
    isLoadingTotal = true;
    update();

    try {
      final res = await ApiService.get(Apis.attendanceTotal);

      if (res != null && res['success'] == true) {
        totalDays = res['total_attendance_days'] ?? 0;
        totalHours = double.tryParse(res['total_work_hours'].toString()) ?? 0;
      }
    } catch (e) {
      print(e);
    }

    isLoadingTotal = false;
    update();
  }

  //  Attendance Stats

  Future<void> fetchAttendanceStats() async {
    final id = employeeId;
    if (id == null) return;
    print(
      '📊 Dashboard: GET stats → ${Apis.baseUrl}${Apis.attendanceHistory(id)}',
    );

    isLoadingStats = true;
    _safeUpdate();

    try {
      final dynamic response = await ApiService.get(Apis.attendanceHistory(id));
      print('📊 ✅ Response: $response');

      List<dynamic> rawList = [];
      if (response is List) {
        rawList = response;
      } else if (response is Map && response['data'] != null) {
        rawList = response['data'] as List<dynamic>;
      }

      presentDays = 0;
      absentDays = 0;
      leaveDays = 0;

      final Set<String> counted = {};

      for (final item in rawList) {
        final map = item as Map<String, dynamic>;
        final date = map['date']?.toString() ?? '';
        final status = (map['status'] as String? ?? '').toLowerCase();

        if (counted.contains(date)) continue;
        counted.add(date);

        if (status.contains('logged') ||
            status.contains('present') ||
            status == 'checked_in' ||
            status == 'checked_out') {
          presentDays++;
        } else if (status.contains('not_logged') ||
            status.contains('absent') ||
            status.contains('not_marked')) {
          absentDays++;
        } else if (status.contains('leave')) {
          leaveDays++;
        }
      }

      print('📊 present:$presentDays absent:$absentDays leaves:$leaveDays');
      isLoadingStats = false;
      _safeUpdate();
    } catch (e) {
      print('📊 ❌ $e');
      isLoadingStats = false;
      _safeUpdate();
    }
  }

  //  Upcoming Leaves

  Future<void> fetchUpcomingLeaves() async {
    print(
      '🏖️  Dashboard: GET leaves → ${Apis.baseUrl}${Apis.leaveApplications}',
    );
    isLoadingLeaves = true;
    _safeUpdate();

    try {
      final dynamic response = await ApiService.get(Apis.leaveApplications);
      print('🏖️  ✅ Response: $response');

      List<dynamic> rawList = [];
      if (response is List) {
        rawList = response;
      } else if (response is Map && response['data'] != null) {
        rawList = response['data'] as List<dynamic>;
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

      print('🏖️  ${upcomingLeaves.length} upcoming leaves');
      isLoadingLeaves = false;
      _safeUpdate();
    } catch (e) {
      print('🏖️  ❌ $e');
      isLoadingLeaves = false;
      _safeUpdate();
    }
  }

  //  Logout

  Future<void> logout() async {
    isLoggingOut = true;
    update();
    try {
      await ApiService.clearToken();
      Get.offAllNamed('/login');
    } catch (e) {
      print('❌ Logout error: $e');
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

  Color get todayStatusColor {
    switch (todayStatus.toLowerCase()) {
      case 'present':
      case 'checked in':
      case 'logged in':
        return Colors.white;
      case 'absent':
        return const Color(0xFFFF7675);
      case 'not marked':
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
