import 'package:employee_app/hr_flow/controller/leave_management_controller.dart';
import 'package:employee_app/hr_flow/models/leave_request_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class LeaveManagementView extends GetView<LeaveManagementController> {
  const LeaveManagementView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F6),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _StatsRow(controller: controller),
          _FilterRow(controller: controller),
          _LeaveTypeFilterRow(controller: controller),
          Expanded(child: _LeaveList(controller: controller)),
        ],
      ),
      bottomNavigationBar: GetBuilder<LeaveManagementController>(
        builder: (controller) {
          if (!controller.isSelectMode || controller.selectedIds.isEmpty) {
            return const SizedBox.shrink();
          }
          return _BulkActionBar(controller: controller);
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: Colors.black.withOpacity(0.08)),
      ),
      title: GetBuilder<LeaveManagementController>(
        builder: (controller) => controller.isSelectMode
            ? Text(
                '${controller.selectedIds.length} Selected',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0F172A),
                ),
              )
            : Row(
                children: [
                  const Text(
                    'Leave Requests',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GetBuilder<LeaveManagementController>(
                    builder: (c) => c.pendingCount > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE9FE),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${c.pendingCount} pending',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF5B21B6),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
      ),
      actions: [
        GetBuilder<LeaveManagementController>(
          builder: (controller) => controller.isSelectMode
              ? Row(
                  children: [
                    TextButton(
                      onPressed: controller.selectAll,
                      child: const Text(
                        'Select All',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: controller.cancelSelectMode,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.black.withOpacity(0.12),
                            ),
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : controller.pendingCount > 0
              ? Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: controller.toggleSelectMode,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.black.withOpacity(0.12),
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.checklist_rounded,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Select',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ── Stats Row ──────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final LeaveManagementController controller;
  const _StatsRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LeaveManagementController>(
      builder: (controller) => Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Row(
          children: [
            _StatCard(
              label: 'Pending',
              count: controller.pendingCount,
              background: const Color(0xFFFFF7ED),
              textColor: const Color(0xFFC2410C),
            ),
            const SizedBox(width: 8),
            _StatCard(
              label: 'Approved',
              count: controller.approvedCount,
              background: const Color(0xFFF0FDF4),
              textColor: const Color(0xFF15803D),
            ),
            const SizedBox(width: 8),
            _StatCard(
              label: 'Rejected',
              count: controller.rejectedCount,
              background: const Color(0xFFFEF2F2),
              textColor: const Color(0xFFB91C1C),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color background;
  final Color textColor;

  const _StatCard({
    required this.label,
    required this.count,
    required this.background,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: textColor,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter Row ─────────────────────────────────────────────────
class _FilterRow extends StatelessWidget {
  final LeaveManagementController controller;
  const _FilterRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LeaveManagementController>(
      builder: (controller) => Container(
        color: Colors.white,
        child: Column(
          children: [
            Container(height: 0.5, color: Colors.black.withOpacity(0.08)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: ['Pending', 'Approved', 'Rejected', 'All'].map((
                  filter,
                ) {
                  final isSelected = controller.selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => controller.setFilter(filter),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF0F172A)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF0F172A)
                                : Colors.black.withOpacity(0.12),
                          ),
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w500
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Leave Type Filter Row ──────────────────────────────────────
class _LeaveTypeFilterRow extends StatelessWidget {
  final LeaveManagementController controller;
  const _LeaveTypeFilterRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LeaveManagementController>(
      builder: (controller) {
        if (controller.isLeaveTypesLoading) {
          return Container(
            height: 44,
            color: const Color(0xFFF8F8F6),
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
          );
        }
        if (controller.leaveTypes.isEmpty) return const SizedBox.shrink();

        return Container(
          color: const Color(0xFFF8F8F6),
          child: Column(
            children: [
              Container(height: 0.5, color: Colors.black.withOpacity(0.06)),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  children: [
                    _LeaveTypeChip(
                      label: 'All Types',
                      isSelected: controller.selectedLeaveTypeFilter == null,
                      accentColor: const Color(0xFF7C3AED),
                      onTap: () => controller.setLeaveTypeFilter(null),
                    ),
                    ...controller.leaveTypes.map((type) {
                      final name = type['name'] as String;
                      final days = type['total_days'] as int;
                      final isSelected =
                          controller.selectedLeaveTypeFilter == name;
                      return _LeaveTypeChip(
                        label: name,
                        days: days,
                        isSelected: isSelected,
                        accentColor: _accentForType(name),
                        onTap: () => controller.setLeaveTypeFilter(name),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _accentForType(String type) {
    switch (type.toLowerCase()) {
      case 'sick leave':
        return const Color(0xFFE24B4A);
      case 'annual leave':
        return const Color(0xFF1D9E75);
      case 'maternity leave':
      case 'paternity leave':
        return const Color(0xFFD4537E);
      default:
        return const Color(0xFF378ADD);
    }
  }
}

class _LeaveTypeChip extends StatelessWidget {
  final String label;
  final int? days;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _LeaveTypeChip({
    required this.label,
    this.days,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? accentColor.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? accentColor : Colors.black.withOpacity(0.1),
              width: isSelected ? 1 : 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isSelected)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor,
                    ),
                  ),
                ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? accentColor : const Color(0xFF64748B),
                ),
              ),
              if (days != null) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor
                        : Colors.black.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$days d',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Leave List ─────────────────────────────────────────────────
class _LeaveList extends StatelessWidget {
  final LeaveManagementController controller;
  const _LeaveList({required this.controller});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LeaveManagementController>(
      builder: (controller) {
        final leaves = controller.filteredLeaves;
        if (leaves.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.inbox_rounded,
                    size: 28,
                    color: Colors.black.withOpacity(0.2),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'No ${controller.selectedFilter.toLowerCase()} requests',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nothing to review right now',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withOpacity(0.35),
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
          itemCount: leaves.length,
          itemBuilder: (ctx, i) =>
              _LeaveCard(leave: leaves[i], controller: controller),
        );
      },
    );
  }
}

// ── Leave Card ─────────────────────────────────────────────────
class _LeaveCard extends StatelessWidget {
  final LeaveRequest leave;
  final LeaveManagementController controller;

  const _LeaveCard({required this.leave, required this.controller});

  @override
  Widget build(BuildContext context) {
    final status = leave.status;
    final leaveType = leave.leaveTypeName;
    final days = leave.totalDays;
    final startDate = leave.fromDate;
    final endDate = leave.toDate;
    final statusColor = _statusColor(status);
    final accentColor = _accentColor(leaveType);
    final initials = _initials(leave.employeeName);

    return GetBuilder<LeaveManagementController>(
      builder: (controller) {
        final isSelected = controller.selectedIds.contains(leave.id);
        final isSelectMode = controller.isSelectMode;

        return GestureDetector(
          onLongPress: status == 'pending'
              ? () {
                  controller.isSelectMode = true;
                  controller.toggleSelection(leave.id);
                }
              : null,
          onTap: isSelectMode && status == 'pending'
              ? () => controller.toggleSelection(leave.id)
              : null,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF1D9E75)
                    : Colors.black.withOpacity(0.07),
                width: isSelected ? 2 : 0.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 4, color: accentColor),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(13),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Row
                            Row(
                              children: [
                                if (isSelectMode && status == 'pending')
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: _SelectCircle(
                                      isSelected: isSelected,
                                    ),
                                  ),
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: accentColor.withOpacity(
                                    0.12,
                                  ),
                                  child: Text(
                                    initials,
                                    style: TextStyle(
                                      color: accentColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        leave.employeeName,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      Text(
                                        '${leave.department} · #${leave.employeeId}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),
                            Divider(
                              height: 1,
                              color: Colors.black.withOpacity(0.06),
                            ),
                            const SizedBox(height: 10),

                            // Meta Row
                            Row(
                              children: [
                                Expanded(
                                  child: _MetaItem(
                                    label: 'Leave type',
                                    child: _LeaveTypePill(
                                      label: leaveType,
                                      color: accentColor,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: _MetaItem(
                                    label: 'Duration',
                                    value:
                                        '$days ${days == 1 ? 'day' : 'days'}',
                                  ),
                                ),
                                Expanded(
                                  child: _MetaItem(
                                    label: 'Dates',
                                    value:
                                        '${DateFormat('dd MMM').format(startDate)} – '
                                        '${DateFormat('dd MMM').format(endDate)}',
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Reason
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(8),
                                border: Border(
                                  left: BorderSide(
                                    color: accentColor.withOpacity(0.5),
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: Text(
                                leave.reason,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black.withOpacity(0.5),
                                  height: 1.5,
                                ),
                              ),
                            ),

                            if (status == 'pending' && !isSelectMode) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          controller.rejectSingle(leave),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFF64748B,
                                        ),
                                        side: BorderSide(
                                          color: Colors.black.withOpacity(0.12),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Reject',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          controller.approveSingle(leave),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF1D9E75,
                                        ),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Approve',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, min(2, name.length)).toUpperCase();
  }

  Color _accentColor(String leaveType) {
    switch (leaveType.toLowerCase()) {
      case 'sick leave':
        return const Color(0xFFE24B4A);
      case 'annual leave':
        return const Color(0xFF1D9E75);
      case 'maternity leave':
      case 'paternity leave':
        return const Color(0xFFD4537E);
      default:
        return const Color(0xFF378ADD);
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF15803D);
      case 'rejected':
        return const Color(0xFFB91C1C);
      default:
        return const Color(0xFFC2410C);
    }
  }
}

// ── Helper Widgets ─────────────────────────────────────────────
class _SelectCircle extends StatelessWidget {
  final bool isSelected;
  const _SelectCircle({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF1D9E75), width: 1.5),
        color: isSelected ? const Color(0xFF1D9E75) : Colors.transparent,
      ),
      child: isSelected
          ? const Icon(Icons.check, size: 13, color: Colors.white)
          : null,
    );
  }
}

class _MetaItem extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? child;

  const _MetaItem({required this.label, this.value, this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            letterSpacing: 0.5,
            color: Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 3),
        if (child != null) child!,
        if (value != null)
          Text(
            value!,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0F172A),
            ),
          ),
      ],
    );
  }
}

class _LeaveTypePill extends StatelessWidget {
  final String label;
  final Color color;

  const _LeaveTypePill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bulk Action Bar ────────────────────────────────────────────
class _BulkActionBar extends StatelessWidget {
  final LeaveManagementController controller;
  const _BulkActionBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LeaveManagementController>(
      builder: (controller) => Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 12,
        ),
        decoration: const BoxDecoration(color: Color(0xFF1E293B)),
        child: Row(
          children: [
            Text(
              '${controller.selectedIds.length} selected',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: controller.bulkReject,
                icon: const Icon(Icons.close_rounded, size: 16),
                label: Text('Reject (${controller.selectedIds.length})'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFCA5A5),
                  side: BorderSide(color: Colors.red.withOpacity(0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: controller.bulkApprove,
                icon: const Icon(Icons.check_rounded, size: 16),
                label: Text('Approve (${controller.selectedIds.length})'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D9E75),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
