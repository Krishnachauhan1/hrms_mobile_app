import 'package:employee_app/app_color.dart';
import 'package:employee_app/hr_flow/controller/main_shell_controller.dart';
import 'package:employee_app/hr_flow/models/attendance_model.dart';
import 'package:employee_app/hr_flow/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../api_service.dart';
import '../../apis.dart';

class AttendanceController extends GetxController {
  late final MainShellController _shell;
  List<Attendance> historyRecords = [];
  DateTime selectedDate = DateTime.now();
  String selectedEmployeeId = '';
  String selectedEmpId = "";
  String viewMode = 'list';
  List<Attendance> records = [];
  Employee? emp;

  int? monthlyDays;
  double? monthlyHours;
  int? monthlyMonth;
  int totalPresent = 0;
  int totalAbsent = 0;
  int totalLeave = 0;
  int totalAttendanceDays = 0;
  double totalWorkHours = 0;
  int totalEmployeeId = 0;
  String? currentStatus;
  String? currentEmployeeName;
  int? currentEmployeeId;

  @override
  void onInit() {
    super.onInit();
    _shell = Get.find<MainShellController>();
    fetchTodayAttendance();
    fetchAttendanceTotal();
  }

  void loadMonthly() {
    fetchMonthlyAttendance(selectedDate.month, selectedDate.year);
  }

  // Today
  Future<void> fetchTodayAttendance() async {
    try {
      final res = await ApiService.get(Apis.attendanceToday);
      print('the final response of data is ========$res');
      final String dateStr = res["date"];
      final DateTime apiDate = DateTime.parse(dateStr);
      selectedDate = apiDate;
      List list = res["data"];
      records.clear();
      int? firstId;
      for (var e in list) {
        firstId ??= e["employee_id"];
        records.add(
          Attendance(
            id: "${e["employee_id"]}_$dateStr",
            employeeId: e["employee_id"].toString(),
            employeeName: e["employee_name"] ?? "__",
            department: e["department"] ?? "",
            date: apiDate,
            status: _mapStatus(e["status"]),
            checkInTime: e["login_at"] != null
                ? DateTime.parse(e["login_at"])
                : null,
            checkOutTime: e["logout_at"] != null
                ? DateTime.parse(e["logout_at"])
                : null,
          ),
        );
      }
      if (firstId != null) {
        loadEmployeeStatus(firstId!);
      }
      update();
    } catch (e) {
      print('the error ==========$e');
    }
  }

  //  Monthly ─
  Future<void> fetchMonthlyAttendance(int month, int year) async {
    try {
      final res = await ApiService.get(Apis.attendanceMonthly);
      print("employe monthly attendance data is =====$res");
      monthlyMonth = res["month"] ?? 0;
      monthlyDays = res["total_days"] ?? 0;
      monthlyHours = (res["total_hours"] ?? 0).toDouble();
      update();
    } catch (e) {
      print('the error is =======$e');
    }
  }

  // Total
  Future<void> fetchAttendanceTotal() async {
    try {
      final res = await ApiService.get(Apis.attendanceTotal);
      print("employe  Total Attendance data is =====$res");
      totalEmployeeId = res["employee_id"] ?? 0;
      totalAttendanceDays = res["total_attendance_days"] ?? 0;
      totalWorkHours = (res["total_work_hours"] ?? 0).toDouble();
      update();
    } catch (e) {
      print('error=====$e');
    }
  }

  // employees status
  Future<void> loadEmployeeStatus(int employeeId) async {
    try {
      final res = await ApiService.get(Apis.attendanceStatus(employeeId));
      print("employe employee status data is =====$res");
      currentEmployeeId = res["employee_id"] ?? 0;
      currentEmployeeName = res["employee_name"] ?? "";
      currentStatus = _mapStatus(res["status"]);
      update();
    } catch (e) {
      print('error is ==$e');
    }
  }

  Future<void> fetchHistory(int employeeId) async {
    try {
      final res = await ApiService.get(Apis.attendanceHistory(employeeId));
      print("history res ========== $res");
      historyRecords.clear();
      List list = res["data"];
      for (var e in list) {
        historyRecords.add(
          Attendance(
            id: "${e["employee_id"]}_${e["date"]}",
            employeeId: e["employee_id"].toString(),
            employeeName: currentEmployeeName ?? "",
            department: "",
            date: DateTime.parse(e["date"]),
            status: e["status"],
            checkInTime: e["login_at"] != null
                ? DateTime.parse(e["login_at"])
                : null,
            checkOutTime: e["logout_at"] != null
                ? DateTime.parse(e["logout_at"])
                : null,
          ),
        );
      }
      update();
    } catch (e) {
      print("history error = $e");
    }
  }

  // Status mapping
  String _mapStatus(String s) {
    switch (s) {
      case "logged_in":
        return "Present";
      case "not_logged_in":
        return "Absent";
      case "leave":
        return "On Leave";
      case "half_day":
        return "Half Day";
      default:
        return "Absent";
    }
  }

  //  Helpers
  List<Employee> get employees => _shell.employees;

  List<Attendance> get recordsForDate {
    final d = selectedDate;
    return records.where((r) {
      final sameDay =
          r.date.year == d.year &&
          r.date.month == d.month &&
          r.date.day == d.day;
      if (!sameDay) return false;
      if (selectedEmployeeId.isNotEmpty) {
        return r.employeeId == selectedEmployeeId;
      }
      return true;
    }).toList();
  }

  List<Attendance> recordsForEmployee(String empId) {
    return records.where((r) => r.employeeId == empId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Color statusColor(String status) {
    switch (status) {
      case 'Present':
        return const Color(0xFF27AE60);
      case 'Absent':
        return const Color(0xFFE74C3C);
      case 'On Leave':
        return const Color(0xFFF39C12);
      case 'Half Day':
        return const Color(0xFF2980B9);
      default:
        return const Color(0xFF95A5A6);
    }
  }

  // Date & View Navigation
  void changeDate(DateTime date) {
    selectedDate = date;
    update();
  }

  void prevDay() {
    selectedDate = selectedDate.subtract(const Duration(days: 1));
    update();
  }

  void nextDay() {
    final next = selectedDate.add(const Duration(days: 1));
    if (!next.isAfter(DateTime.now())) {
      selectedDate = next;
      update();
    }
  }

  void nextMonth() {
    selectedDate = DateTime(selectedDate.year, selectedDate.month + 1);
    loadMonthly();
    update();
  }

  void toggleViewMode() {
    viewMode = viewMode == 'list' ? 'calendar' : 'list';
    if (viewMode == 'calendar') {
      loadMonthly();
    }
    update();
  }

  void setEmployeeFilter(String empId) {
    selectedEmployeeId = empId;
    update();
  }

  void setSelectedEmployee(String id) {
    selectedEmpId = id;
    update();
  }

  int get presentCount =>
      recordsForDate.where((a) => a.status == 'Present').length;
  int get absentCount =>
      recordsForDate.where((a) => a.status == 'Absent').length;
  int get onLeaveCount =>
      recordsForDate.where((a) => a.status == 'On Leave').length;
  int get halfDayCount =>
      recordsForDate.where((a) => a.status == 'Half Day').length;

  //  Add Attendance
  void addAttendance({
    required String employeeId,
    required DateTime date,
    required String status,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? remarks,
  }) {
    print("Adding attendance for $employeeId");
    if (employeeId.isEmpty || employees.isEmpty) {
      Get.snackbar(
        'Error',
        'Please select an employee',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    final emp = employees.firstWhere(
      (e) => e.id == employeeId,
      orElse: () => employees.first,
    );

    final cleanDate = DateTime(date.year, date.month, date.day);

    records.removeWhere(
      (r) =>
          r.employeeId == employeeId &&
          r.date.year == cleanDate.year &&
          r.date.month == cleanDate.month &&
          r.date.day == cleanDate.day,
    );

    final newRecord = Attendance(
      id: '${employeeId}_${cleanDate.millisecondsSinceEpoch}',
      employeeId: employeeId,
      employeeName: emp.name,
      department: emp.department,
      date: cleanDate,
      checkInTime: checkInTime,
      checkOutTime: checkOutTime,
      status: status,
      remarks: remarks,
    );
    records.add(newRecord);
    _shell.attendanceRecords
      ..removeWhere(
        (r) =>
            r.employeeId == employeeId &&
            r.date.year == cleanDate.year &&
            r.date.month == cleanDate.month &&
            r.date.day == cleanDate.day,
      )
      ..add(newRecord);
    selectedDate = cleanDate;
    selectedEmployeeId = '';
    update();

    Get.snackbar(
      'Saved ✓',
      '${emp.name} · $status · ${_fmtDate(cleanDate)}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF27AE60),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  //  Update Attendance
  void updateAttendance({
    required String recordId,
    required String newStatus,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? remarks,
  }) {
    final idx = records.indexWhere((r) => r.id == recordId);
    if (idx == -1) return;

    final old = records[idx];
    final updated = old.copyWith(
      status: newStatus,
      checkInTime: checkInTime,
      checkOutTime: checkOutTime,
      remarks: remarks,
    );
    records[idx] = updated;
    final shellIdx = _shell.attendanceRecords.indexWhere(
      (r) => r.id == recordId,
    );
    if (shellIdx != -1) {
      _shell.attendanceRecords[shellIdx] = updated;
    }
    selectedDate = DateTime(old.date.year, old.date.month, old.date.day);
    selectedEmployeeId = '';
    update();

    Get.snackbar(
      'Updated ✓',
      '${old.employeeName} · $newStatus · ${_fmtDate(old.date)}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF2980B9),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  // Show Add/Edit Dialog
  void showAddEditDialog({
    Attendance? existing,
    String? prefilledEmpId,
    DateTime? prefilledDate,
  }) {
    final isEdit = existing != null;
    DateTime formDate = prefilledDate ?? selectedDate;
    TimeOfDay? formCheckIn = existing?.checkInTime != null
        ? TimeOfDay.fromDateTime(existing!.checkInTime!)
        : null;
    TimeOfDay? formCheckOut = existing?.checkOutTime != null
        ? TimeOfDay.fromDateTime(existing!.checkOutTime!)
        : null;
    String formStatus = existing?.status ?? 'Present';
    final remarksCtrl = TextEditingController(text: existing?.remarks ?? '');
    selectedEmpId =
        prefilledEmpId ??
        existing?.employeeId ??
        (employees.isNotEmpty ? employees.first.id : '');
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.access_time_filled_rounded,
                        color: Color(0xFFFF9800),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEdit ? 'Edit Attendance' : 'Add Attendance',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (!isEdit) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          color: Color(0xFFFF9800),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            "New attendance record will be added",
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF757575),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(
                            0xFFFF9800,
                          ).withOpacity(0.1),
                          child: Text(
                            existing!.employeeName[0],
                            style: const TextStyle(
                              color: Color(0xFFFF9800),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              existing.employeeName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              existing.department,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF757575),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const _FieldLabel('Date'),
                const SizedBox(height: 6),
                GetBuilder<AttendanceController>(
                  builder: (c) {
                    return _DatePickerField(
                      date: formDate,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: Get.context!,
                          initialDate: formDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          formDate = picked;
                          c.update();
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),

                const _FieldLabel('Status'),
                const SizedBox(height: 6),
                GetBuilder<AttendanceController>(
                  builder: (c) {
                    return Wrap(
                      spacing: 8,
                      children: ['Present', 'Absent', 'Half Day', 'On Leave']
                          .map((s) {
                            final isSelected = formStatus == s;
                            final color = _statusColorStatic(s);
                            return GestureDetector(
                              onTap: () {
                                formStatus = s;
                                c.update();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? color
                                      : color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  s,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : color,
                                  ),
                                ),
                              ),
                            );
                          })
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel('Check-in'),
                          const SizedBox(height: 6),
                          GetBuilder<AttendanceController>(
                            builder: (c) {
                              return _TimePickerField(
                                time: formCheckIn,
                                hint: 'Not Mark Yet',
                                onTap: () async {
                                  final t = await showTimePicker(
                                    context: Get.context!,
                                    initialTime:
                                        formCheckIn ??
                                        const TimeOfDay(hour: 9, minute: 0),
                                  );
                                  if (t != null) {
                                    formCheckIn = t;
                                    c.update();
                                  }
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel('Check-out'),
                          const SizedBox(height: 6),
                          GetBuilder<AttendanceController>(
                            builder: (c) {
                              return _TimePickerField(
                                time: formCheckOut,
                                hint: '--:-- --',
                                onTap: () async {
                                  final t = await showTimePicker(
                                    context: Get.context!,
                                    initialTime:
                                        formCheckOut ??
                                        const TimeOfDay(hour: 17, minute: 30),
                                  );
                                  if (t != null) {
                                    formCheckOut = t;
                                    c.update();
                                  }
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                const _FieldLabel('Remarks'),
                const SizedBox(height: 6),
                TextField(
                  controller: remarksCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Any notes...',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: Get.back,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final d = formDate;
                          DateTime? checkIn;
                          DateTime? checkOut;

                          if (formCheckIn != null) {
                            checkIn = DateTime(
                              d.year,
                              d.month,
                              d.day,
                              formCheckIn!.hour,
                              formCheckIn!.minute,
                            );
                          }

                          if (formCheckOut != null) {
                            checkOut = DateTime(
                              d.year,
                              d.month,
                              d.day,
                              formCheckOut!.hour,
                              formCheckOut!.minute,
                            );
                          }

                          if (isEdit) {
                            updateAttendance(
                              recordId: existing!.id,
                              newStatus: formStatus,
                              checkInTime: checkIn,
                              checkOutTime: checkOut,
                              remarks: remarksCtrl.text.trim().isEmpty
                                  ? null
                                  : remarksCtrl.text.trim(),
                            );
                          } else {
                            addAttendance(
                              employeeId: selectedEmpId,
                              date: d,
                              status: formStatus,
                              checkInTime: checkIn,
                              checkOutTime: checkOut,
                              remarks: remarksCtrl.text.trim().isEmpty
                                  ? null
                                  : remarksCtrl.text.trim(),
                            );
                          }

                          Future.delayed(const Duration(milliseconds: 120), () {
                            if (Get.isDialogOpen ?? false) {
                              Navigator.of(
                                Get.context!,
                                rootNavigator: true,
                              ).pop();
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(isEdit ? 'Update' : 'Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  //  Employee History Dialog
  void showEmployeeHistory(String empId, String name, String dept) {
    final history = historyRecords;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// HEADER
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Text(
                        name.isNotEmpty ? name[0] : "?",
                        style: const TextStyle(
                          color: Color(0xFFFF9800),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            dept,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: Get.back,
                    ),
                  ],
                ),
              ),

              /// STATS
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _HistoryStat(
                      'Present',
                      history
                          .where((h) => h.status == 'Present')
                          .length
                          .toString(),
                      const Color(0xFF27AE60),
                    ),

                    _HistoryStat(
                      'Absent',
                      history
                          .where((h) => h.status == 'Absent')
                          .length
                          .toString(),
                      const Color(0xFFE74C3C),
                    ),
                  ],
                ),
              ),

              const Divider(),

              /// LIST
              Flexible(
                child: history.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text("No history"),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: history.length,
                        itemBuilder: (ctx, i) {
                          final r = history[i];

                          final color = statusColor(r.status);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_formatDate(r.date)),

                                if (r.checkInTime != null)
                                  Text("In: ${_formatTime(r.checkInTime!)}"),

                                if (r.checkOutTime != null)
                                  Text("Out: ${_formatTime(r.checkOutTime!)}"),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //  Calendar Helpers
  Map<DateTime, String> calendarStatusForEmployee(
    String empId,
    int year,
    int month,
  ) {
    final result = <DateTime, String>{};
    for (final r in records) {
      if (r.employeeId == empId &&
          r.date.year == year &&
          r.date.month == month) {
        final key = DateTime(r.date.year, r.date.month, r.date.day);
        result[key] = r.status;
      }
    }
    return result;
  }

  //Format Helpers
  String _fmtDate(DateTime d) => _formatDate(d);

  String _formatDate(DateTime d) {
    const months = [
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
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
        ? 12
        : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $suffix';
  }

  static Color _statusColorStatic(String s) {
    switch (s) {
      case 'Present':
        return const Color(0xFF27AE60);
      case 'Absent':
        return const Color(0xFFE74C3C);
      case 'On Leave':
        return const Color(0xFFF39C12);
      case 'Half Day':
        return const Color(0xFF2980B9);
      default:
        return const Color(0xFF95A5A6);
    }
  }
}

// Reusable Dialog Widgets
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Color(0xFF757575),
    ),
  );
}

class _DropdownField<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  const _DropdownField({
    required this.value,
    required this.items,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButton<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        isExpanded: true,
        underline: const SizedBox.shrink(),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;
  const _DatePickerField({required this.date, required this.onTap});
  @override
  Widget build(BuildContext context) {
    const months = [
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: Color(0xFFFF9800),
            ),
            const SizedBox(width: 8),
            Text(
              '${date.day} ${months[date.month - 1]} ${date.year}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, color: Color(0xFF757575)),
          ],
        ),
      ),
    );
  }
}

class _TimePickerField extends StatelessWidget {
  final TimeOfDay? time;
  final String hint;
  final VoidCallback onTap;
  const _TimePickerField({
    required this.time,
    required this.hint,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    String display = hint;
    if (time != null) {
      final h = time!.hourOfPeriod == 0 ? 12 : time!.hourOfPeriod;
      final m = time!.minute.toString().padLeft(2, '0');
      final suffix = time!.period == DayPeriod.am ? 'AM' : 'PM';
      display = '$h:$m $suffix';
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.access_time_rounded,
              size: 18,
              color: Color(0xFFFF9800),
            ),
            const SizedBox(width: 6),
            Text(
              display,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: time != null ? Colors.black87 : const Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _HistoryStat(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF757575)),
        ),
      ],
    );
  }
}
