import 'package:employee_app/app_color.dart';
import 'package:employee_app/hr_flow/controller/hrdashboardcontroller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HRDashboardView extends GetView<HRDashboardController> {
  const HRDashboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HR Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: GetBuilder<HRDashboardController>(
        builder: (controller) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statistics Cards
              _buildStatisticsSection(),
              const SizedBox(height: 24),

              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildQuickActions(),
              const SizedBox(height: 24),

              // Pending Leave Requests
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pending Leave Requests',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: controller.navigateToLeaveManagement,
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildPendingLeaves(),
              const SizedBox(height: 24),

              // Currently Logged In Employees
              Text(
                'Currently Logged In',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _buildLoggedInEmployees(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.1,
      children: [
        _buildStatCard(
          'Total Employees',
          controller.totalEmployees.toString(),
          Icons.people,
          AppColors.primary,
        ),
        _buildStatCard(
          'Active',
          controller.activeEmployees.toString(),
          Icons.check_circle,
          AppColors.secondary,
        ),
        _buildStatCard(
          'On Leave',
          controller.onLeaveEmployees.toString(),
          Icons.event_busy,
          AppColors.primary,
        ),
        _buildStatCard(
          'Logged In',
          controller.loggedInEmployees.toString(),
          Icons.login,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2,
      children: [
        _buildActionCard(
          'Employees',
          Icons.people_outline,
          AppColors.primary,
          controller.navigateToEmployeeList,
        ),
        _buildActionCard(
          'Leave Management',
          Icons.event_note,
          AppColors.secondary,
          controller.navigateToLeaveManagement,
        ),
        _buildActionCard(
          'Salary',
          Icons.account_balance_wallet,
          Colors.green,
          controller.navigateToSalaryManagement,
        ),
        _buildActionCard(
          'Attendance',
          Icons.access_time,
          AppColors.primary,
          controller.navigateToAttendance,
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingLeaves() {
    if (controller.pendingLeaves.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No pending leave requests',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.pendingLeaves.length,
      itemBuilder: (context, index) {
        final leave = controller.pendingLeaves[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.withOpacity(0.1),
              child: const Icon(Icons.person, color: Colors.orange),
            ),
            title: Text(leave.employeeName),
            subtitle: Text(
              '${leave.leaveType} - ${leave.numberOfDays} days',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Chip(
              label: Text(leave.status, style: const TextStyle(fontSize: 11)),
              backgroundColor: AppColors.primary.withOpacity(0.2),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoggedInEmployees() {
    final loggedInEmployees = controller.employees
        .where((e) => e.isLoggedIn)
        .toList();

    if (loggedInEmployees.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No employees currently logged in.',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: loggedInEmployees.length,
      itemBuilder: (context, index) {
        final employee = loggedInEmployees[index];
        final lastLogin = employee.lastLoginTime;
        final timeAgo = lastLogin != null ? _getTimeAgo(lastLogin) : 'N/A';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.withOpacity(0.1),
              child: const Icon(Icons.person, color: Colors.green),
            ),
            title: Text(employee.name),
            subtitle: Text(
              '${employee.designation} - Login: $timeAgo',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showLogoutDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              controller.logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
