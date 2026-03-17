import 'package:employee_app/app_color.dart';
import 'package:employee_app/hr_flow/controller/main_shell_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final c = Get.find<MainShellController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header
              _Header(),
              const SizedBox(height: 24),

              // ── Stats Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overview',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GetBuilder<MainShellController>(
                      builder: (_) => GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 1.55,
                        children: [
                          _StatCard(
                            title: 'Total Employees',
                            value: c.totalEmployees.toString(),
                            icon: Icons.people_rounded,
                            color: AppColors.primary,
                            bgColor: AppColors.background.withOpacity(0.1),
                          ),
                          _StatCard(
                            title: 'Active',
                            value: c.activeCount.toString(),
                            icon: Icons.check_circle_rounded,
                            color: const Color(0xFF27AE60),
                            bgColor: const Color(0xFF27AE60).withOpacity(0.1),
                          ),
                          _StatCard(
                            title: 'On Leave',
                            value: c.onLeaveCount.toString(),
                            icon: Icons.event_busy_rounded,
                            color: const Color(0xFFF39C12),
                            bgColor: const Color(0xFFF39C12).withOpacity(0.1),
                          ),
                          _StatCard(
                            title: 'Leave Pending',
                            value: c.pendingLeaveCount.toString(),
                            icon: Icons.pending_actions_rounded,
                            color: const Color(0xFFE74C3C),
                            bgColor: const Color(0xFFE74C3C).withOpacity(0.1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Quick Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _QuickActionsGrid(controller: c),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Today's Snapshot
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _TodaySnapshot(controller: c),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header Widget
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C5CE7), Color.fromARGB(255, 73, 68, 107)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      // color: Color(0xFF6C5CE7)
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good ${_greeting()},',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text(
                  'HR Manager',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.business_center_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}

// ── Stat Card ─────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.textSecondary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Quick Actions Grid ────────────────────────────────────────
class _QuickActionsGrid extends StatelessWidget {
  final MainShellController controller;

  const _QuickActionsGrid({required this.controller});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionItem(
        label: 'Employees',
        icon: Icons.people_rounded,
        color: AppColors.primary,
        onTap: () => controller.changePage(1),
      ),
      _ActionItem(
        label: 'Leave Requests',
        icon: Icons.event_note_rounded,
        color: AppColors.secondary,
        onTap: () => controller.changePage(2),
      ),
      _ActionItem(
        label: 'Salary',
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFF27AE60),
        onTap: () => controller.changePage(3),
      ),
      _ActionItem(
        label: 'Attendance',
        icon: Icons.access_time_filled_rounded,
        color: const Color(0xFFF39C12),
        onTap: () => controller.changePage(4),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 2.2,
      children: actions.map((a) => _QuickActionCard(item: a)).toList(),
    );
  }
}

class _ActionItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  _ActionItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _QuickActionCard extends StatelessWidget {
  final _ActionItem item;
  const _QuickActionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: item.color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: item.color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: item.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Today's Snapshot ──────────────────────────────────────────
class _TodaySnapshot extends StatelessWidget {
  final MainShellController controller;
  const _TodaySnapshot({required this.controller});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MainShellController>(
      builder: (_) {
        final pending = controller.leaveRequests
            .where((l) => l.status == 'Pending')
            .take(3)
            .toList();

        if (pending.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pending Approvals',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                TextButton(
                  onPressed: () => controller.changePage(2),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange,
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('View All →'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...pending.map((leave) => _MiniLeaveCard(leave: leave)),
          ],
        );
      },
    );
  }
}

class _MiniLeaveCard extends StatelessWidget {
  final dynamic leave;
  const _MiniLeaveCard({required this.leave});

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColor(leave.leaveType);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.textSecondary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              leave.employeeName.isNotEmpty ? leave.employeeName[0] : "__",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
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
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${leave.leaveType} • ${leave.numberOfDays} day${leave.numberOfDays > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              leave.leaveType,
              style: TextStyle(
                color: typeColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
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
