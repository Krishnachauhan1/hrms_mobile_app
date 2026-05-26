import 'package:employee_app/employee_flow/attendance/attendance_screen.dart';
import 'package:employee_app/employee_flow/breaks/break_time_screen.dart';
import 'package:employee_app/employee_flow/dashboard/dashboardscreen.dart';
import 'package:employee_app/employee_flow/leaves/leavescreen.dart';
import 'package:employee_app/employee_flow/location/field_location_controller.dart';
import 'package:employee_app/employee_flow/salary/salaryscreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Get.isRegistered<FieldLocationController>()) {
        Get.put(FieldLocationController(), permanent: true);
      }
      Get.find<FieldLocationController>().start();
    });
  }

  final List<Widget> _pages = [
    const DashboardPage(),
    const AttendancePage(),
    const BreakTimeScreen(),
    const LeavePage(),
    const SalaryPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = MediaQuery.sizeOf(context).width;
              final compact = width < 380;
              final hPad = width * 0.02;

              return Padding(
                padding: EdgeInsets.fromLTRB(hPad, 6, hPad, 8),
                child: Row(
                  children: [
                    _buildNavItem(
                      0,
                      Icons.dashboard_rounded,
                      'Home',
                      compact: compact,
                    ),
                    _buildNavItem(
                      1,
                      Icons.fingerprint_rounded,
                      compact ? 'Attend' : 'Attendance',
                      compact: compact,
                    ),
                    _buildNavItem(
                      2,
                      Icons.free_breakfast_outlined,
                      'Break',
                      compact: compact,
                    ),
                    _buildNavItem(
                      3,
                      Icons.calendar_today_rounded,
                      'Leave',
                      compact: compact,
                    ),
                    _buildNavItem(
                      4,
                      Icons.account_balance_wallet_rounded,
                      'Salary',
                      compact: compact,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label, {
    required bool compact,
  }) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 2 : 4,
            vertical: compact ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6C5CE7) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFFB2B7C2),
                size: compact ? 22 : 24,
              ),
              SizedBox(height: compact ? 2 : 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFFB2B7C2),
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: compact ? 10 : 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
