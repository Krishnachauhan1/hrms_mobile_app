import 'package:employee_app/employee_flow/employee_permission_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'salary_controller.dart';

class SalaryPage extends StatelessWidget {
  const SalaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<EmployeeFeatureController>(
      builder: (featureCtrl) {
        if (featureCtrl.isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8F9FE),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF00B894)),
            ),
          );
        }

        if (!featureCtrl.canViewSalary) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FE),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: const SizedBox(),
              title: const Text(
                'Salary Details',
                style: TextStyle(
                  color: Color(0xFF2D3436),
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        size: 44,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Access Denied',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3436),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'You do not have permission to view salary details.\nPlease contact your admin.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF74788D),
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () => Get.back(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Go Back',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C5CE7),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return GetBuilder<SalaryController>(
          init: SalaryController(),
          builder: (controller) {
            if (controller.isLoading) {
              return const Scaffold(
                backgroundColor: Color(0xFFF8F9FE),
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFF00B894)),
                ),
              );
            }

            if (controller.errorMessage != null &&
                controller.salaryDetail == null) {
              return Scaffold(
                backgroundColor: const Color(0xFFF8F9FE),
                body: Center(child: Text(controller.errorMessage!)),
              );
            }

            final s = controller.salaryDetail;

            return Scaffold(
              backgroundColor: const Color(0xFFF8F9FE),
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: const SizedBox(),
                title: const Text(
                  'Salary Details',
                  style: TextStyle(
                    color: Color(0xFF2D3436),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: true,
              ),
              body: RefreshIndicator(
                onRefresh: controller.fetchSalary,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (s != null) _netCard(controller, s),
                      const SizedBox(height: 20),
                      if (s != null) _fullDetails(controller, s),
                      const SizedBox(height: 20),
                      if (s != null) _breakdown(controller, s),
                      const SizedBox(height: 20),
                      if (s != null) _history(controller, s),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _netCard(SalaryController c, s) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00B894), Color(0xFF00A383)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Net Salary', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          Text(
            '₹${c.formatAmount(s.netSalary)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _metric('Gross', c.formatAmount(s.grossSalary))),
              Expanded(
                child: _metric('Deduction', c.formatAmount(s.deductions)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white70)),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _fullDetails(SalaryController c, s) {
    Widget row(String t, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(t, style: const TextStyle(color: Color(0xFF74788D))),
          Text(
            v,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3436),
            ),
          ),
        ],
      ),
    );

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('Complete Salary Details'),
          row('Basic Salary', '₹${c.formatAmount(s.basicSalary)}'),
          row('HRA', '₹${c.formatAmount(s.hra)}'),
          row('Conveyance', '₹${c.formatAmount(s.conveyanceAllowance)}'),
          row('Medical', '₹${c.formatAmount(s.medicalAllowance)}'),
          row('Special', '₹${c.formatAmount(s.specialAllowance)}'),
          const Divider(),
          row('Gross', '₹${c.formatAmount(s.grossSalary)}'),
          row('Deductions', '₹${c.formatAmount(s.deductions)}'),
          row('Net', '₹${c.formatAmount(s.netSalary)}'),
          const Divider(),
          row('Overtime Allowed', s.overtimeAllowed),
          row('Overtime Rate', '₹${c.formatAmount(s.overtimeRatePerHour)}'),
        ],
      ),
    );
  }

  Widget _breakdown(SalaryController c, s) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('Salary Breakdown'),
          ...s.allowances.map<Widget>(
            (e) => _rowItem(e['name'], '₹${c.formatAmount(e['amount'] ?? 0)}'),
          ),
          const Divider(),
          _title('Deductions'),
          ...s.deductionItems.map<Widget>(
            (e) => _rowItem(e['name'], '₹${c.formatAmount(e['amount'] ?? 0)}'),
          ),
        ],
      ),
    );
  }

  Widget _history(SalaryController c, s) {
    if (s.payrollHistory.isEmpty) {
      return _card(child: const Text('No payroll history'));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title('Payroll History'),
        const SizedBox(height: 10),
        ...s.payrollHistory.map<Widget>((e) {
          return _card(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(e['month'] ?? ''),
                Text('₹${c.formatAmount(e['net_salary'] ?? 0)}'),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _title(String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        t,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2D3436),
        ),
      ),
    );
  }

  Widget _rowItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
