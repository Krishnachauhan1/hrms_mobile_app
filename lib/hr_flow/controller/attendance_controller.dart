import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:employee_app/hr_flow/controller/main_shell_controller.dart';
import 'package:employee_app/hr_flow/models/attendance_model.dart';
import 'package:employee_app/hr_flow/models/employee_model.dart';

class AttendanceController extends GetxController {
  late final MainShellController _shell;

  // ── Reactive State ─────────────────────────────────────────
  final selectedDate = DateTime.now().obs;
  final selectedEmployeeId = ''.obs;
  final viewMode = 'list'.obs;

  // LOCAL reactive copy of attendance — Obx reads this directly
  final records = <Attendance>[].obs;

  @override
  void onInit() {
    super.onInit();
    _shell = Get.find<MainShellController>();
    // Sync local list from shell on start
    records.assignAll(_shell.attendanceRecords);
    update();
  }

  // ── Helpers ────────────────────────────────────────────────
  List<Employee> get employees => _shell.employees;

  /// Records shown in the list for the selected date + filter
  List<Attendance> get recordsForDate {
    final d = selectedDate.value;
    return records.where((r) {
      final sameDay =
          r.date.year == d.year &&
          r.date.month == d.month &&
          r.date.day == d.day;
      if (!sameDay) return false;
      if (selectedEmployeeId.value.isNotEmpty) {
        return r.employeeId == selectedEmployeeId.value;
      }
      return true;
    }).toList();
  }

  /// Full history for one employee, newest first
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

  // ── Date & View Navigation ─────────────────────────────────
  void changeDate(DateTime date) {
    selectedDate.value = date;
    update();
  }

  void prevDay() {
    selectedDate.value = selectedDate.value.subtract(const Duration(days: 1));
    update();
  }

  void nextDay() {
    final next = selectedDate.value.add(const Duration(days: 1));
    if (!next.isAfter(DateTime.now())) {
      selectedDate.value = next;
      update();
    }
  }

  void toggleViewMode() {
    viewMode.value = viewMode.value == 'list' ? 'calendar' : 'list';
    update();
  }

  void setEmployeeFilter(String empId) {
    selectedEmployeeId.value = empId;
    update();
  }

  // ── Stats ──────────────────────────────────────────────────
  int get presentCount =>
      recordsForDate.where((a) => a.status == 'Present').length;
  int get absentCount =>
      recordsForDate.where((a) => a.status == 'Absent').length;
  int get onLeaveCount =>
      recordsForDate.where((a) => a.status == 'On Leave').length;
  int get halfDayCount =>
      recordsForDate.where((a) => a.status == 'Half Day').length;

  // ── Add Attendance ─────────────────────────────────────────
  void addAttendance({
    required String employeeId,
    required DateTime date,
    required String status,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? remarks,
  }) {
    final emp = employees.firstWhere(
      (e) => e.id == employeeId,
      orElse: () => employees.first,
    );

    final cleanDate = DateTime(date.year, date.month, date.day);

    // Remove any existing record for same employee + date
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

    // Also sync back to shell so other screens stay updated
    _shell.attendanceRecords
      ..removeWhere(
        (r) =>
            r.employeeId == employeeId &&
            r.date.year == cleanDate.year &&
            r.date.month == cleanDate.month &&
            r.date.day == cleanDate.day,
      )
      ..add(newRecord);
    _shell.update();

    // Jump to the saved date so user sees the record immediately
    selectedDate.value = cleanDate;
    selectedEmployeeId.value = '';
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

  // ── Update Attendance ──────────────────────────────────────
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

    // Sync to shell
    final shellIdx = _shell.attendanceRecords.indexWhere(
      (r) => r.id == recordId,
    );
    if (shellIdx != -1) {
      _shell.attendanceRecords[shellIdx] = updated;
    }
    _shell.update();

    // Jump to that date
    selectedDate.value = DateTime(old.date.year, old.date.month, old.date.day);
    selectedEmployeeId.value = '';
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

  // ── Show Add/Edit Dialog ────────────────────────────────────
  void showAddEditDialog({
    Attendance? existing,
    String? prefilledEmpId,
    DateTime? prefilledDate,
  }) {
    final isEdit = existing != null;
    final formDate = (prefilledDate ?? selectedDate.value).obs;
    final formCheckIn = Rx<TimeOfDay?>(
      existing?.checkInTime != null
          ? TimeOfDay.fromDateTime(existing!.checkInTime!)
          : null,
    );
    final formCheckOut = Rx<TimeOfDay?>(
      existing?.checkOutTime != null
          ? TimeOfDay.fromDateTime(existing!.checkOutTime!)
          : null,
    );
    final formStatus = (existing?.status ?? 'Present').obs;
    final remarksCtrl = TextEditingController(text: existing?.remarks ?? '');

    // For employee picker
    final selectedEmpId =
        (prefilledEmpId ?? existing?.employeeId ?? employees.first.id).obs;

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
                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9800).withOpacity(0.1),
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

                // Employee Picker
                if (!isEdit) ...[
                  const _FieldLabel('Employee'),
                  const SizedBox(height: 6),
                  Obx(
                    () => _DropdownField<String>(
                      value: selectedEmpId.value,
                      items: employees
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.id,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: const Color(
                                      0xFFFF9800,
                                    ).withOpacity(0.1),
                                    child: Text(
                                      e.name[0],
                                      style: const TextStyle(
                                        color: Color(0xFFFF9800),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      '${e.name} (${e.employeeCode})',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => selectedEmpId.value = v!,
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  // Show employee info readonly
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
                            existing.employeeName[0],
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

                // Date Picker
                const _FieldLabel('Date'),
                const SizedBox(height: 6),
                Obx(
                  () => _DatePickerField(
                    date: formDate.value,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: Get.context!,
                        initialDate: formDate.value,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        builder: (ctx, child) => Theme(
                          data: Theme.of(ctx).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Color(0xFFFF9800),
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) formDate.value = picked;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Status
                const _FieldLabel('Status'),
                const SizedBox(height: 6),
                Obx(
                  () => Wrap(
                    spacing: 8,
                    children: ['Present', 'Absent', 'Half Day', 'On Leave'].map(
                      (s) {
                        final isSelected = formStatus.value == s;
                        final color = _statusColorStatic(s);
                        return GestureDetector(
                          onTap: () => formStatus.value = s,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color
                                  : color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? color
                                    : color.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              s,
                              style: TextStyle(
                                color: isSelected ? Colors.white : color,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      },
                    ).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Check-in / Check-out
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel('Check-in'),
                          const SizedBox(height: 6),
                          Obx(
                            () => _TimePickerField(
                              time: formCheckIn.value,
                              hint: '--:-- --',
                              onTap: () async {
                                final t = await showTimePicker(
                                  context: Get.context!,
                                  initialTime:
                                      formCheckIn.value ??
                                      const TimeOfDay(hour: 9, minute: 0),
                                  builder: (ctx, child) => Theme(
                                    data: Theme.of(ctx).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: Color(0xFFFF9800),
                                      ),
                                    ),
                                    child: child!,
                                  ),
                                );
                                if (t != null) formCheckIn.value = t;
                              },
                            ),
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
                          Obx(
                            () => _TimePickerField(
                              time: formCheckOut.value,
                              hint: '--:-- --',
                              onTap: () async {
                                final t = await showTimePicker(
                                  context: Get.context!,
                                  initialTime:
                                      formCheckOut.value ??
                                      const TimeOfDay(hour: 17, minute: 30),
                                  builder: (ctx, child) => Theme(
                                    data: Theme.of(ctx).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: Color(0xFFFF9800),
                                      ),
                                    ),
                                    child: child!,
                                  ),
                                );
                                if (t != null) formCheckOut.value = t;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Remarks
                const _FieldLabel('Remarks (optional)'),
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

                // Actions
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
                          final d = formDate.value;
                          DateTime? checkIn;
                          DateTime? checkOut;

                          if (formCheckIn.value != null) {
                            checkIn = DateTime(
                              d.year,
                              d.month,
                              d.day,
                              formCheckIn.value!.hour,
                              formCheckIn.value!.minute,
                            );
                          }

                          if (formCheckOut.value != null) {
                            checkOut = DateTime(
                              d.year,
                              d.month,
                              d.day,
                              formCheckOut.value!.hour,
                              formCheckOut.value!.minute,
                            );
                          }

                          //SAVE / UPDATE CALL
                          if (isEdit) {
                            updateAttendance(
                              recordId: existing.id,
                              newStatus: formStatus.value,
                              checkInTime: checkIn,
                              checkOutTime: checkOut,
                              remarks: remarksCtrl.text.trim().isEmpty
                                  ? null
                                  : remarksCtrl.text.trim(),
                            );
                          } else {
                            addAttendance(
                              employeeId: selectedEmpId.value,
                              date: d,
                              status: formStatus.value,
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
                          backgroundColor: const Color(0xFFFF9800),
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

  // ── Employee Attendance History Dialog ──────────────────────
  void showEmployeeHistory(Employee emp) {
    final history = recordsForEmployee(emp.id);
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF9800),
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
                        emp.name[0],
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
                            emp.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${emp.employeeCode} · ${emp.department}',
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

              // Summary row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
                    _HistoryStat(
                      'On Leave',
                      history
                          .where((h) => h.status == 'On Leave')
                          .length
                          .toString(),
                      const Color(0xFFF39C12),
                    ),
                    _HistoryStat(
                      'Half Day',
                      history
                          .where((h) => h.status == 'Half Day')
                          .length
                          .toString(),
                      const Color(0xFF2980B9),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // History list
              Flexible(
                child: history.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No attendance records found',
                          style: TextStyle(color: Color(0xFF9E9E9E)),
                        ),
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
                              border: Border.all(color: color.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _formatDate(r.date),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      if (r.checkInTime != null)
                                        Text(
                                          'In: ${_formatTime(r.checkInTime!)}'
                                          '${r.checkOutTime != null ? '  ·  Out: ${_formatTime(r.checkOutTime!)}  ·  ${r.workingHours}' : ''}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF757575),
                                          ),
                                        ),
                                      if (r.remarks != null &&
                                          r.remarks!.isNotEmpty)
                                        Text(
                                          r.remarks!,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                            color: Color(0xFF9E9E9E),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    r.status,
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
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

  // ── Calendar helpers ───────────────────────────────────────
  /// All dates in visible month that have records for given employee
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

  // ── Helpers ────────────────────────────────────────────────
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
    final wd = days[d.weekday - 1];
    return '$wd, ${d.day} ${months[d.month - 1]} ${d.year}';
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

// ── Small reusable dialog widgets ──────────────────────────────
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
