import 'package:employee_app/app_color.dart';
import 'package:employee_app/hr_flow/controller/employee_list_controller.dart';
import 'package:employee_app/hr_flow/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class EmployeeListView extends GetView<EmployeeListController> {
  const EmployeeListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<EmployeeListController>(
      builder: (c) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Employees'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              tooltip: 'Refresh locations',
              onPressed: c.isSyncingLocations ? null : c.refreshLocations,
              icon: c.isSyncingLocations
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.location_searching),
            ),
          ],
        ),
        body: Column(
          children: [
            _SearchAndFilter(controller: c),
            _SummaryBar(controller: c),
            Expanded(child: _EmployeeList(controller: c)),
          ],
        ),
      ),
    );
  }
}

class _SearchAndFilter extends StatelessWidget {
  final EmployeeListController controller;
  const _SearchAndFilter({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.textSecondary,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        children: [
          TextField(
            onChanged: controller.searchEmployees,
            decoration: InputDecoration(
              hintText: 'Search by name, code, department...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.primary,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 10),
          GetBuilder<EmployeeListController>(
            builder: (controller) => Row(
              children: ['All', 'Active', 'On Leave'].map((f) {
                final isSelected = controller.selectedFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => controller.setFilter(f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.background
                              : AppColors.textPrimary,
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
    );
  }
}

class _SummaryBar extends StatelessWidget {
  final EmployeeListController controller;
  const _SummaryBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<EmployeeListController>(
      builder: (controller) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: AppColors.primary.withOpacity(0.06),
        child: Row(
          children: [
            _SummaryItem(
              'Total',
              controller.total.toString(),
              AppColors.primary,
            ),
            const SizedBox(width: 20),
            _SummaryItem(
              'Active',
              controller.activeCount.toString(),
              const Color(0xFF27AE60),
            ),
            const SizedBox(width: 20),
            _SummaryItem(
              'On Leave',
              controller.onLeaveCount.toString(),
              const Color(0xFFF39C12),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryItem(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.white70),
        ),
      ],
    );
  }
}

class _EmployeeList extends StatelessWidget {
  final EmployeeListController controller;
  const _EmployeeList({required this.controller});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<EmployeeListController>(
      builder: (controller) {
        final employees = controller.filteredEmployees;
        if (employees.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_search_rounded,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 12),
                const Text(
                  'No employees found',
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: employees.length,
          itemBuilder: (ctx, i) => _EmployeeCard(
            employee: employees[i],
            onTap: () => controller.viewEmployeeDetails(employees[i]),
          ),
        );
      },
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final Employee employee;
  final VoidCallback onTap;
  const _EmployeeCard({required this.employee, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = employee.status == 'Active'
        ? const Color(0xFF27AE60)
        : employee.status == 'On Leave'
        ? const Color(0xFFF39C12)
        : Colors.red;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      employee.name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                if (employee.isLoggedIn)
                  Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF27AE60),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    employee.designation,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: employee.latitude != null
                            ? const Color(0xFF27AE60)
                            : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          employee.latitude != null
                              ? '${employee.locationText}${employee.lastLocationAt != null ? ' · ${DateFormat('hh:mm a').format(employee.lastLocationAt!)}' : ''}'
                              : 'Location pending',
                          style: TextStyle(
                            fontSize: 11,
                            color: employee.latitude != null
                                ? const Color(0xFF636E72)
                                : Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.business_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        employee.department,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.badge_rounded, size: 12, color: Colors.white),
                      const SizedBox(width: 3),
                      Text(
                        employee.employeeCode,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    employee.status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
