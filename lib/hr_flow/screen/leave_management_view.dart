import 'package:employee_app/hr_flow/controller/leave_management_controller.dart';
import 'package:employee_app/hr_flow/models/leave_request_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class LeaveManagementView extends GetView<LeaveManagementController> {
  const LeaveManagementView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _StatsRow(controller: controller),
          _FilterRow(controller: controller),
          Expanded(child: _LeaveList(controller: controller)),
        ],
      ),
      bottomNavigationBar: GetBuilder<LeaveManagementController>(
        builder: (controller) {
        if (!controller.isSelectMode || controller.selectedIds.isEmpty) {
          return const SizedBox.shrink();
        }
        return _BulkActionBar(controller: controller);
      }),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: GetBuilder<LeaveManagementController>(
        builder: (controller) => controller.isSelectMode
            ? Text('${controller.selectedIds.length} Selected')
            : const Text('Leave Requests'),
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
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: controller.cancelSelectMode,
                    ),
                  ],
                )
              : (() {
                  final pendingCount = controller.pendingCount;
                  return pendingCount > 0
                      ? TextButton.icon(
                          onPressed: controller.toggleSelectMode,
                          icon: const Icon(
                            Icons.checklist_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: const Text(
                            'Select',
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : const SizedBox.shrink();
                })(),
        ),
      ],
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final LeaveManagementController controller;
  const _StatsRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LeaveManagementController>(
      builder: (controller) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        color: Colors.white,
        child: Row(
          children: [
            _StatChip(
              label: 'Pending',
              count: controller.pendingCount,
              color: const Color(0xFFF39C12),
            ),
            const SizedBox(width: 10),
            _StatChip(
              label: 'Approved',
              count: controller.approvedCount,
              color: const Color(0xFF27AE60),
            ),
            const SizedBox(width: 10),
            _StatChip(
              label: 'Rejected',
              count: controller.rejectedCount,
              color: const Color(0xFFE74C3C),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter Row ────────────────────────────────────────────────
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
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: ['Pending', 'Approved', 'Rejected', 'All'].map((
                  filter,
                ) {
                  final isSelected = controller.selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => controller.setFilter(filter),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.orange
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? Colors.orange
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.orangeAccent,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 13,
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

// ── Leave List ────────────────────────────────────────────────
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
              Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                'No ${controller.selectedFilter.toLowerCase()} requests',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: leaves.length,
        itemBuilder: (ctx, i) =>
            _LeaveCard(leave: leaves[i], controller: controller),
      );
      },
    );
  }
}

// ── Leave Card ────────────────────────────────────────────────
class _LeaveCard extends StatelessWidget {
  final LeaveRequest leave;
  final LeaveManagementController controller;
  const _LeaveCard({required this.leave, required this.controller});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(leave.status);
    final typeColor = _typeColor(leave.leaveType);

    return GetBuilder<LeaveManagementController>(
      builder: (controller) {
      final isSelected = controller.selectedIds.contains(leave.id);
      final isSelectMode = controller.isSelectMode;

      return GestureDetector(
        onLongPress: leave.status == 'Pending'
            ? () {
                controller.isSelectMode = true;
                controller.toggleSelection(leave.id);
              }
            : null,
        onTap: isSelectMode && leave.status == 'Pending'
            ? () => controller.toggleSelection(leave.id)
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.orange : Colors.transparent,
              width: isSelected ? 2 : 0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top Row ──
                Row(
                  children: [
                    if (isSelectMode && leave.status == 'Pending')
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.orange
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.orange
                                  : Colors.grey.shade400,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 14,
                                )
                              : null,
                        ),
                      ),
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.orange.withOpacity(0.1),
                      child: Text(
                        leave.employeeName[0],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            leave.employeeName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            leave.department,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        leave.status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Details ──
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _InfoChip(
                          icon: Icons.category_outlined,
                          label: leave.leaveType,
                          color: typeColor,
                        ),
                      ),
                      Expanded(
                        child: _InfoChip(
                          icon: Icons.calendar_today_outlined,
                          label:
                              '${leave.numberOfDays} day${leave.numberOfDays > 1 ? 's' : ''}',
                          color: Colors.white70,
                        ),
                      ),
                      Expanded(
                        child: _InfoChip(
                          icon: Icons.date_range_outlined,
                          label:
                              '${DateFormat('dd MMM').format(leave.startDate)} - ${DateFormat('dd MMM').format(leave.endDate)}',
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Reason ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        leave.reason,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),

                // ── HR Comment ──
                if (leave.hrComment != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: statusColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.comment_rounded,
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            leave.hrComment!,
                            style: TextStyle(fontSize: 12, color: statusColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Action Buttons (only pending, not in select mode) ──
                if (leave.status == 'Pending' && !isSelectMode) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => controller.rejectSingle(leave),
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => controller.approveSingle(leave),
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF27AE60),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
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
      );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Approved':
        return const Color(0xFF27AE60);
      case 'Rejected':
        return const Color(0xFFE74C3C);
      default:
        return const Color(0xFFF39C12);
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Sick':
        return Colors.red;
      case 'Annual':
        return Colors.orangeAccent;
      case 'Emergency':
        return const Color(0xFFE74C3C);
      default:
        return Colors.orange;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Bulk Action Bar ───────────────────────────────────────────
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
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: controller.bulkReject,
                icon: const Icon(Icons.close_rounded, size: 18),
                label: Text('Reject (${controller.selectedIds.length})'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: controller.bulkApprove,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text('Approve (${controller.selectedIds.length})'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27AE60),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
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
