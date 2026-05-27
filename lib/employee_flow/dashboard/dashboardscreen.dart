import 'package:employee_app/employee_flow/attendance/attendance_screen.dart';
import 'package:employee_app/employee_flow/breaks/break_time_screen.dart';
import 'package:employee_app/employee_flow/leaves/leavescreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../profile/profile_screen.dart';
import 'dashboard_controller.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DashboardController>(
      init: DashboardController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FE),
          body: RefreshIndicator(
            onRefresh: () async {
              await controller.loadDashboardData();
            },
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(controller, context),
                    _buildAttendanceCard(controller),
                    const SizedBox(height: 20),
                    _buildQuickActions(context),
                    const SizedBox(height: 25),
                    const Text(
                      'Overview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3436),
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildStatsGrid(controller),
                    const SizedBox(height: 25),
                    _buildUpcomingLeaves(controller),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // HEADER
  Widget _buildHeader(DashboardController controller, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome back,',
              style: TextStyle(fontSize: 16, color: Color(0xFF74788D)),
            ),
            const SizedBox(height: 4),
            controller.isLoadingProfile
                ? const SizedBox(
                    width: 140,
                    height: 32,
                    child: LinearProgressIndicator(
                      color: Color(0xFF6C5CE7),
                      backgroundColor: Color(0xFFEEEEEE),
                    ),
                  )
                : Text(
                    controller.employeeName.isEmpty
                        ? 'Employee'
                        : controller.employeeName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3436),
                    ),
                  ),
          ],
        ),

        // Profile Avatar
        GestureDetector(
          onTap: () => ProfileBottomSheet.show(context, controller),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF6C5CE7),
              child: controller.isLoadingProfile
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      controller.employeeInitials.isEmpty
                          ? '--'
                          : controller.employeeInitials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  // PROFILE BOTTOM SHEET

  // ATTENDANCE CARD
  Widget _buildAttendanceCard(DashboardController controller) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C5CE7), Color(0xFF5F4FD1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Today\'s Status',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: controller.isLoadingToday
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        controller.todayStatus.isEmpty
                            ? 'Not Marked'
                            : controller.todayStatus,
                        style: TextStyle(
                          color: controller.todayStatusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Check In',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),

                    const SizedBox(height: 4),
                    controller.isLoadingToday
                        ? const Text(
                            '...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : Text(
                            controller.checkInTime.isEmpty
                                ? '--:-- --'
                                : controller.checkInTime,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Working Hours',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    controller.isLoadingToday
                        ? const Text(
                            '...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : Text(
                            controller.workingHours.isEmpty
                                ? '0:00 hrs'
                                : controller.workingHours,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // QUICK ACTIONS
  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.fingerprint_rounded,
                label: 'Mark Attendance',
                color: const Color(0xFF00B894),
                onTap: () =>
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AttendancePage()),
                    ).then((value) {
                      if (value == true) {
                        final controller = Get.find<DashboardController>();
                        controller.fetchTotalAttendance();
                      }
                    }),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildActionButton(
                icon: Icons.free_breakfast_outlined,
                label: 'Break Time',
                color: const Color(0xFF6C5CE7),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BreakTimeScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.event_note_rounded,
                label: 'Apply Leave',
                color: const Color(0xFFFF7675),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LeavePage()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3436),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STATS GRID
  Widget _buildStatsGrid(DashboardController controller) {
    if (controller.isLoadingStats) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatCard(
            'Present',
            controller.presentDays.toString(),
            'Days',
            const Color(0xFF00B894),
          ),

          const SizedBox(width: 12),

          _buildStatCard(
            'Absent',
            controller.absentDays.toString(),
            'Days',
            const Color(0xFFFF7675),
          ),

          const SizedBox(width: 12),

          _buildStatCard(
            'Leaves',
            controller.leaveDays.toString(),
            'Days',
            const Color(0xFFFDAA2B),
          ),

          const SizedBox(width: 12),

          _buildStatCard(
            'Monthly',
            controller.monthlyDays.toString(),
            'Days',
            Colors.blue,
          ),

          const SizedBox(width: 12),

          _buildStatCard(
            'Total',
            controller.totalDays.toString(),
            'Days',
            Colors.purple,
          ),

          const SizedBox(width: 12),

          _buildStatCard(
            'Hours',
            controller.formatWorkHours(controller.monthlyHours.toString()),
            'hrs',
            Colors.teal,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Color(0xFF74788D)),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Color(0xFF74788D)),
          ),
        ],
      ),
    );
  }

  // UPCOMING LEAVES
  Widget _buildUpcomingLeaves(DashboardController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upcoming Leaves',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3436),
          ),
        ),
        const SizedBox(height: 15),
        if (controller.isLoadingLeaves)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: Color(0xFF6C5CE7)),
            ),
          )
        else if (controller.upcomingLeaves.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'No upcoming leaves',
                style: TextStyle(color: Color(0xFF74788D), fontSize: 14),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.upcomingLeaves.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final leave = controller.upcomingLeaves[i];
              final color = controller.leaveColor(i);
              return _buildLeaveItem(
                type: leave['type'] as String,
                date: leave['date'] as String,
                duration: leave['duration'] as String,
                color: color,
              );
            },
          ),
      ],
    );
  }

  Widget _buildLeaveItem({
    required String type,
    required String date,
    required String duration,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.calendar_today_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3436),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF74788D),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              duration,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
