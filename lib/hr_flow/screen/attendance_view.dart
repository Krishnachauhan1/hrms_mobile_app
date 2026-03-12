import 'package:employee_app/hr_flow/controller/attendance_controller.dart';
import 'package:employee_app/hr_flow/models/attendance_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AttendanceView extends GetView<AttendanceController> {
  const AttendanceView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange,
      appBar: _buildAppBar(),
      floatingActionButton: _AddFAB(controller: controller),
      // body: Obx(
      //   // () => controller.viewMode.value == 'calendar'
      //       ? _CalendarView(controller: controller)
      //       : _ListView(controller: controller),
      // ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Attendance'),
      automaticallyImplyLeading: false,
      actions: [
        // Toggle view mode
        Obx(
          () => IconButton(
            tooltip: controller.viewMode.value == 'list'
                ? 'Calendar View'
                : 'List View',
            icon: Icon(
              controller.viewMode.value == 'list'
                  ? Icons.calendar_month_rounded
                  : Icons.list_alt_rounded,
            ),
            onPressed: controller.toggleViewMode,
          ),
        ),
      ],
    );
  }
}

// ─── FAB ──────────────────────────────────────────────────────
class _AddFAB extends StatelessWidget {
  final AttendanceController controller;
  const _AddFAB({required this.controller});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => controller.showAddEditDialog(),
      backgroundColor: Colors.orange,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Add', style: TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

// ─── LIST VIEW ────────────────────────────────────────────────
class _ListView extends StatelessWidget {
  final AttendanceController controller;
  const _ListView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DateNavigator(controller: controller),
        _EmployeeFilterBar(controller: controller),
        _StatsRow(controller: controller),
        Expanded(child: _AttendanceList(controller: controller)),
      ],
    );
  }
}

// ─── Date Navigator ───────────────────────────────────────────
class _DateNavigator extends StatelessWidget {
  final AttendanceController controller;
  const _DateNavigator({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Obx(() {
        final d = controller.selectedDate.value;
        final isToday = _isSameDay(d, DateTime.now());
        return Row(
          children: [
            _NavBtn(
              icon: Icons.chevron_left_rounded,
              onTap: controller.prevDay,
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => _pickDate(context, controller),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatDate(d),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      if (isToday)
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Text(
                            'Today',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            _NavBtn(
              icon: Icons.chevron_right_rounded,
              onTap: controller.nextDay,
              disabled: _isSameDay(d, DateTime.now()),
            ),
          ],
        );
      }),
    );
  }

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

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _pickDate(BuildContext ctx, AttendanceController c) async {
    final picked = await showDatePicker(
      context: ctx,
      initialDate: c.selectedDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Colors.orange),
        ),
        child: child!,
      ),
    );
    // if (picked != null) c.changeDate(picked);
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool disabled;
  const _NavBtn({
    required this.icon,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: disabled ? Colors.grey.shade100 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: disabled ? Colors.grey.shade300 : Colors.white70,
          size: 22,
        ),
      ),
    );
  }
}

// ─── Employee Filter Bar ──────────────────────────────────────
class _EmployeeFilterBar extends StatelessWidget {
  final AttendanceController controller;
  const _EmployeeFilterBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // "All" chip
              _EmpChip(
                label: 'All',
                isSelected: controller.selectedEmployeeId.value.isEmpty,
                onTap: () => controller.setEmployeeFilter(''),
              ),
              const SizedBox(width: 8),
              ...controller.employees.map(
                (emp) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _EmpChip(
                    label: emp.name.split(' ').first,
                    isSelected: controller.selectedEmployeeId.value == emp.id,
                    onTap: () => controller.setEmployeeFilter(emp.id),
                    initial: emp.name[0],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmpChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final String? initial;
  const _EmpChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.initial,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (initial != null) ...[
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.3)
                      : Colors.orange.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initial!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.orange,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stats Row ─────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final AttendanceController controller;
  const _StatsRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Direct read of RxList so GetX tracks changes
      final _ = controller.records.length;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Colors.orange.withOpacity(0.05),
        child: Row(
          children: [
            _StatBox(
              'Present',
              controller.presentCount,
              const Color(0xFF27AE60),
              Icons.check_circle_rounded,
            ),
            const SizedBox(width: 8),
            _StatBox(
              'Absent',
              controller.absentCount,
              const Color(0xFFE74C3C),
              Icons.cancel_rounded,
            ),
            const SizedBox(width: 8),
            _StatBox(
              'On Leave',
              controller.onLeaveCount,
              const Color(0xFFF39C12),
              Icons.event_busy_rounded,
            ),
            const SizedBox(width: 8),
            _StatBox(
              'Half Day',
              controller.halfDayCount,
              const Color(0xFF2980B9),
              Icons.timelapse_rounded,
            ),
          ],
        ),
      );
    });
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  const _StatBox(this.label, this.count, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 3),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Attendance List ──────────────────────────────────────────
class _AttendanceList extends StatelessWidget {
  final AttendanceController controller;
  const _AttendanceList({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Read .records directly so GetX RxList tracks this Obx
      final _ = controller.records.length;
      final records = controller.recordsForDate;
      if (records.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_available_rounded,
                size: 64,
                color: Colors.grey.shade200,
              ),
              const SizedBox(height: 12),
              const Text(
                'No records for this date',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => controller.showAddEditDialog(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Attendance'),
                style: TextButton.styleFrom(foregroundColor: Colors.orange),
              ),
            ],
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: records.length,
        itemBuilder: (ctx, i) =>
            _AttendanceCard(record: records[i], controller: controller),
      );
    });
  }
}

class _AttendanceCard extends StatelessWidget {
  final Attendance record;
  final AttendanceController controller;
  const _AttendanceCard({required this.record, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar + status bar
            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      record.employeeName[0],
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          record.employeeName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          record.status,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    record.department,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  if (record.checkInTime != null || record.checkOutTime != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Row(
                        children: [
                          if (record.checkInTime != null) ...[
                            _TimeChip(
                              icon: Icons.login_rounded,
                              label: _fmt(record.checkInTime!),
                              color: const Color(0xFF27AE60),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (record.checkOutTime != null) ...[
                            _TimeChip(
                              icon: Icons.logout_rounded,
                              label: _fmt(record.checkOutTime!),
                              color: const Color(0xFFE74C3C),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                record.workingHours,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  if (record.remarks != null && record.remarks!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '📝 ${record.remarks}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // Actions column
            Column(
              children: [
                // Edit button
                GestureDetector(
                  onTap: () async {
                    // Dialog open hone ka wait karo
                    controller.showAddEditDialog(existing: record);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 16,
                      color: Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // History button
                GestureDetector(
                  onTap: () {
                    final emp = controller.employees.firstWhere(
                      (e) => e.id == record.employeeId,
                      orElse: () => controller.employees.first,
                    );
                    controller.showEmployeeHistory(emp);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white70.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      size: 16,
                      color: Colors.orangeAccent,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) {
    final h = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
        ? 12
        : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $s';
  }
}

class _TimeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _TimeChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CALENDAR VIEW ────────────────────────────────────────────
class _CalendarView extends StatefulWidget {
  final AttendanceController controller;
  const _CalendarView({required this.controller});

  @override
  State<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<_CalendarView> {
  late int _calYear;
  late int _calMonth;
  String _selectedEmpId = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _calYear = now.year;
    _calMonth = now.month;
    // Default to first employee
    if (widget.controller.employees.isNotEmpty) {
      _selectedEmpId = widget.controller.employees.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final employees = widget.controller.employees;
    final selectedEmp = employees.isNotEmpty
        ? employees.firstWhere(
            (e) => e.id == _selectedEmpId,
            orElse: () => employees.first,
          )
        : null;

    return Obx(() {
      // Direct read of RxList so Obx rebuilds when records change
      final _ = widget.controller.records.length;
      final statusMap = selectedEmp != null
          ? widget.controller.calendarStatusForEmployee(
              _selectedEmpId,
              _calYear,
              _calMonth,
            )
          : <DateTime, String>{};

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        child: Column(
          children: [
            // Employee selector
            Container(
              margin: const EdgeInsets.symmetric(vertical: 14),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: employees.map((emp) {
                    final isSel = emp.id == _selectedEmpId;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedEmpId = emp.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.all(4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSel ? Colors.orange : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: isSel
                                  ? Colors.white.withOpacity(0.3)
                                  : Colors.orange.withOpacity(0.12),
                              child: Text(
                                emp.name[0],
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSel ? Colors.white : Colors.orange,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              emp.name.split(' ').first,
                              style: TextStyle(
                                color: isSel ? Colors.white : Colors.white70,
                                fontWeight: isSel
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Calendar card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Month nav
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() {
                            if (_calMonth == 1) {
                              _calMonth = 12;
                              _calYear--;
                            } else {
                              _calMonth--;
                            }
                          }),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.chevron_left_rounded,
                              size: 20,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _monthName(_calMonth) + ' $_calYear',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            final now = DateTime.now();
                            if (_calYear < now.year ||
                                (_calYear == now.year &&
                                    _calMonth < now.month)) {
                              setState(() {
                                if (_calMonth == 12) {
                                  _calMonth = 1;
                                  _calYear++;
                                } else {
                                  _calMonth++;
                                }
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Day headers
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) {
                        return Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Calendar grid
                  _CalendarGrid(
                    year: _calYear,
                    month: _calMonth,
                    statusMap: statusMap,
                    onDayTap: (date) {
                      widget.controller.changeDate(date);
                      widget.controller.setEmployeeFilter(_selectedEmpId);
                      widget.controller.toggleViewMode();
                    },
                  ),
                  const SizedBox(height: 12),

                  // Legend
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _LegendDot('Present', const Color(0xFF27AE60)),
                        const SizedBox(width: 16),
                        _LegendDot('Absent', const Color(0xFFE74C3C)),
                        const SizedBox(width: 16),
                        _LegendDot('Leave', const Color(0xFFF39C12)),
                        const SizedBox(width: 16),
                        _LegendDot('Half Day', const Color(0xFF2980B9)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Monthly stats
            if (selectedEmp != null)
              _MonthlyStats(statusMap: statusMap, empName: selectedEmp.name),
          ],
        ),
      ); // end SingleChildScrollView
    }); // end Obx
  }

  String _monthName(int m) {
    const names = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[m];
  }
}

// ─── Calendar Grid ─────────────────────────────────────────────
class _CalendarGrid extends StatelessWidget {
  final int year;
  final int month;
  final Map<DateTime, String> statusMap;
  final ValueChanged<DateTime> onDayTap;

  const _CalendarGrid({
    required this.year,
    required this.month,
    required this.statusMap,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startWeekday = firstDay.weekday; // 1=Mon … 7=Sun
    final today = DateTime.now();
    final totalCells = startWeekday - 1 + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: List.generate(rows, (row) {
          return Row(
            children: List.generate(7, (col) {
              final cellIndex = row * 7 + col;
              final day = cellIndex - (startWeekday - 1) + 1;

              if (day < 1 || day > daysInMonth) {
                return const Expanded(child: SizedBox(height: 42));
              }

              final date = DateTime(year, month, day);
              final isFuture = date.isAfter(today);
              final isToday =
                  date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              final status = statusMap[date];
              final color = status != null ? _color(status) : null;
              final isWeekend = col >= 5;

              return Expanded(
                child: GestureDetector(
                  onTap: isFuture ? null : () => onDayTap(date),
                  child: Container(
                    height: 42,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isToday
                          ? Colors.orange
                          : color?.withOpacity(0.15) ?? Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: isToday
                          ? null
                          : color != null
                          ? Border.all(color: color.withOpacity(0.3))
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isToday || color != null
                                ? FontWeight.w700
                                : FontWeight.normal,
                            color: isToday
                                ? Colors.white
                                : isFuture
                                ? Colors.grey.shade300
                                : isWeekend && color == null
                                ? Colors.grey.shade400
                                : color ?? Colors.black87,
                          ),
                        ),
                        if (color != null && !isToday)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }

  Color _color(String status) {
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
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendDot(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white70),
        ),
      ],
    );
  }
}

class _MonthlyStats extends StatelessWidget {
  final Map<DateTime, String> statusMap;
  final String empName;
  const _MonthlyStats({required this.statusMap, required this.empName});

  @override
  Widget build(BuildContext context) {
    final present = statusMap.values.where((s) => s == 'Present').length;
    final absent = statusMap.values.where((s) => s == 'Absent').length;
    final leave = statusMap.values.where((s) => s == 'On Leave').length;
    final halfDay = statusMap.values.where((s) => s == 'Half Day').length;
    final total = statusMap.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Summary · ${empName.split(' ').first}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MonthlyStat('Present', present, total, const Color(0xFF27AE60)),
              const SizedBox(width: 10),
              _MonthlyStat('Absent', absent, total, const Color(0xFFE74C3C)),
              const SizedBox(width: 10),
              _MonthlyStat('Leave', leave, total, const Color(0xFFF39C12)),
              const SizedBox(width: 10),
              _MonthlyStat('Half Day', halfDay, total, const Color(0xFF2980B9)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthlyStat extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  const _MonthlyStat(this.label, this.count, this.total, this.color);

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (count / total) : 0.0;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 5,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
