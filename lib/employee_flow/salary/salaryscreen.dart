import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'salary_controller.dart';

class SalaryPage extends StatelessWidget {
  const SalaryPage({super.key});

  @override
  Widget build(BuildContext context) {
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

        // Error state
        if (controller.errorMessage != null &&
            controller.salaryDetail == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FE),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFFFF7675),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    controller.errorMessage!,
                    style: const TextStyle(color: Color(0xFF74788D)),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: controller.fetchSalary,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B894),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Retry',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final salary = controller.salaryDetail;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FE),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2D3436)),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Salary Details',
              style: TextStyle(
                color: Color(0xFF2D3436),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: RefreshIndicator(
            color: const Color(0xFF00B894),

            onRefresh: controller.fetchSalary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Net salary card
                  if (salary != null)
                    _buildCurrentSalaryCard(controller, salary),
                  const SizedBox(height: 25),
                  //  Breakdown
                  if (salary != null) _buildSalaryBreakdown(controller, salary),
                  const SizedBox(height: 25),
                  // Payroll history
                  if (salary != null) _buildPayrollHistory(controller, salary),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  //  Net Salary Card

  Widget _buildCurrentSalaryCard(SalaryController c, SalaryDetail s) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00B894), Color(0xFF00A383)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B894).withOpacity(0.3),
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
                'Net Salary',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),

              if (s.currentMonth.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    s.currentMonth,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 15),

          Text(
            '\₹${c.formatAmount(s.netSalary)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(
                child: _buildSalaryMetric(
                  'Gross',
                  '\₹${c.formatAmount(s.grossSalary)}',
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildSalaryMetric(
                  'Deductions',
                  '\₹${c.formatAmount(s.deductions)}',
                ),
              ),
            ],
          ),
          //  Overtime info row
          if (s.overtimeAllowed.toLowerCase() == 'yes') ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.timer_rounded,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Overtime: \₹${c.formatAmount(s.overtimeRatePerHour)}/hr',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSalaryMetric(String label, String amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Salary Breakdown
  Widget _buildSalaryBreakdown(SalaryController c, SalaryDetail s) {
    const allowanceColors = [
      Color(0xFF6C5CE7),
      Color(0xFF00B894),
      Color(0xFFFDAA2B),
      Color(0xFF74B9FF),
      Color(0xFFA29BFE),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Salary Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 20),

          //Allowances from API
          if (s.allowances.isEmpty)
            _buildBreakdownItem(
              'Monthly Salary',
              '\₹${c.formatAmount(s.monthlySalary)}',
              const Color(0xFF6C5CE7),
            )
          else
            ...s.allowances.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final name = item['name'] as String? ?? 'Allowance';
              final amount = item['amount'];
              final color = allowanceColors[idx % allowanceColors.length];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildBreakdownItem(
                  name,
                  '\₹${c.formatAmount(_toDouble(amount))}',
                  color,
                ),
              );
            }),

          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 15),

          //  Deductions from API
          const Text(
            'Deductions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 15),

          if (s.deductionItems.isEmpty && s.deductions > 0)
            _buildBreakdownItem(
              'Total Deductions',
              '\₹${c.formatAmount(s.deductions)}',
              const Color(0xFFFF7675),
            )
          else
            ...s.deductionItems.map((item) {
              final name = item['name'] as String? ?? 'Deduction';
              final amount = item['amount'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildBreakdownItem(
                  name,
                  '\₹${c.formatAmount(_toDouble(amount))}',
                  const Color(0xFFFF7675),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(String label, String amount, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF74788D)),
          ),
        ),
        Text(
          amount,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3436),
          ),
        ),
      ],
    );
  }

  //  Payroll History

  Widget _buildPayrollHistory(SalaryController c, SalaryDetail s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payroll History',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3436),
          ),
        ),
        const SizedBox(height: 15),

        if (s.payrollHistory.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'No payroll history found.',
                style: TextStyle(color: Color(0xFF74788D), fontSize: 14),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: s.payrollHistory.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final item = s.payrollHistory[i];
              final month = item['month'] as String? ?? '';
              final net = _toDouble(item['net_salary']);
              final status = item['status'] as String? ?? 'pending';
              final color = c.statusColor(status);

              return _buildPayrollItem(
                month: month,
                amount: '\₹${c.formatAmount(net)}',
                status: c.capitalize(status),
                color: color,
              );
            },
          ),
      ],
    );
  }

  Widget _buildPayrollItem({
    required String month,
    required String amount,
    required String status,
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
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  month,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3436),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  amount,
                  style: const TextStyle(
                    fontSize: 14,
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
              status,
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

  // Helper: safe number parse
  double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is int) return val.toDouble();
    if (val is double) return val;
    return double.tryParse(val.toString()) ?? 0.0;
  }
}
