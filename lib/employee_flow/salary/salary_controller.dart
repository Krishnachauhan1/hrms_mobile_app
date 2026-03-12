import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:employee_app/api_service.dart';
import 'package:employee_app/apis.dart';
import 'package:employee_app/authentication/auth_controller.dart';

class SalaryDetail {
  final int id;
  final int employeeId;
  final double monthlySalary;
  final String overtimeAllowed;
  final double overtimeRatePerHour;
  final double grossSalary;
  final double netSalary;
  final double deductions;
  final String currentMonth;

  // Breakdown items from API
  final List<Map<String, dynamic>> allowances;
  final List<Map<String, dynamic>> deductionItems;
  final List<Map<String, dynamic>> payrollHistory;

  SalaryDetail({
    required this.id,
    required this.employeeId,
    required this.monthlySalary,
    required this.overtimeAllowed,
    required this.overtimeRatePerHour,
    required this.grossSalary,
    required this.netSalary,
    required this.deductions,
    required this.currentMonth,
    required this.allowances,
    required this.deductionItems,
    required this.payrollHistory,
  });

  //  Parse from API JSON
  factory SalaryDetail.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is int) return val.toDouble();
      if (val is double) return val;
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return SalaryDetail(
      id: json['id'] as int? ?? 0,
      employeeId: json['employee_id'] as int? ?? 0,
      monthlySalary: toDouble(json['monthly_salary']),
      overtimeAllowed: json['overtime_allowed'] as String? ?? 'no',
      overtimeRatePerHour: toDouble(json['overtime_rate_per_hour']),
      grossSalary: toDouble(json['gross_salary'] ?? json['monthly_salary']),
      netSalary: toDouble(json['net_salary'] ?? json['monthly_salary']),
      deductions: toDouble(json['deductions'] ?? 0),
      currentMonth: json['current_month'] as String? ?? '',

      // Allowances list { "name": "House", "amount": 5000 }
      allowances:
          (json['allowances'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],

      // Deduction items { "name": "Tax", "amount": 4500 }
      deductionItems:
          (json['deduction_items'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],

      // Payroll history { "month": "Jan 2026", "net_salary": 40500, "status": "paid"
      payrollHistory:
          (json['payroll_history'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
    );
  }
}

//  Controller
class SalaryController extends GetxController {
  int? employeeId;
  SalaryController();

  //  Salary data from API
  SalaryDetail? salaryDetail;

  //  Loading & error state
  bool isLoading = false;
  bool isUpdating = false;
  String? errorMessage;

  @override
  void onInit() {
    super.onInit();
    _loadSalaryData();
  }

  Future<void> _loadSalaryData() async {
    final authController = Get.find<AuthController>();
    employeeId =
        ApiService.extractEmployeeId(authController.employee) ??
        await ApiService.getEmployeeId();

    print('Salary onInit employeeId========== $employeeId');

    if (employeeId == null) {
      errorMessage = 'Employee ID not found. Please login again.';
      _safeUpdate();
      return;
    }

    await fetchSalary();
  }

  // Api GET /employees/{id}/salary

  Future<void> fetchSalary() async {
    final id = employeeId;
    if (id == null) return;
    print('Api Get salary details');
    print('Api URL=========== ${Apis.baseUrl}${Apis.employeeSalary(id)}');

    isLoading = true;
    errorMessage = null;
    _safeUpdate();

    try {
      // Step 1: API call — GET, no body needed
      final dynamic response = await ApiService.get(
        Apis.employeeSalary(id),
      );
      print('get API ✅ Status......... 200');
      print('API Raw response: $response');

      // Step 2: Parse — handle both flat and nested response
      Map<String, dynamic> data = {};
      if (response is Map<String, dynamic>) {
        data = response['data'] != null
            ? response['data'] as Map<String, dynamic>
            : response;
      }

      // Step 3: Map to model
      salaryDetail = SalaryDetail.fromJson(data);

      // Step 4: Log parsed values
      print('....API  Parsed.............');
      print('....monthly_salary.........${salaryDetail!.monthlySalary}');
      print('....gross_salary...........${salaryDetail!.grossSalary}');
      print('.....net_salary............${salaryDetail!.netSalary}');
      print('.....deductions.............${salaryDetail!.deductions}');
      print('.....overtime_allowed.......${salaryDetail!.overtimeAllowed}');
      print('.....overtime_rate/hr.......${salaryDetail!.overtimeRatePerHour}');
      print('....allowances count.......${salaryDetail!.allowances.length}');
      print(
        '.........deduction_items count...${salaryDetail!.deductionItems.length}',
      );
      print(
        '......payroll_history count......${salaryDetail!.payrollHistory.length}',
      );

      isLoading = false;
      _safeUpdate();
    } on ApiException catch (e) {
      print('API ❌ ApiException ${e.statusCode}: ${e.message}');
      isLoading = false;
      errorMessage = e.message;
      _safeUpdate();
      _showError('Failed to load salary: ${e.message}');
    } catch (e) {
      print('API ❌ Unknown error: $e');
      isLoading = false;
      errorMessage = 'Network error. Could not load salary.';
      _safeUpdate();
      _showError('Network error. Try again.');
    }

    print('.......................');
  }

  //  API PUT /employees/{id}/salary

  Future<void> updateSalary({
    required double monthlySalary,
    required String overtimeAllowed,
    required double overtimeRatePerHour,
  }) async {
    final id = employeeId;
    if (id == null) {
      _showError('Employee ID not found. Please login again.');
      return;
    }
    print('API PUT update salary');
    print('API  URL........ ${Apis.baseUrl}${Apis.employeeSalary(id)}');

    //  Validation
    if (monthlySalary <= 0) {
      print('API  ❌ Validation: salary must be > 0');
      _showError('Monthly salary must be greater than 0');
      return;
    }

    final Map<String, dynamic> body = {
      'monthly_salary': monthlySalary,
      'overtime_allowed': overtimeAllowed,
      'overtime_rate_per_hour': overtimeRatePerHour,
    };

    print('API EMPLOYEE SALRAY Body..........$body');

    isUpdating = true;
    _safeUpdate();

    try {
      final dynamic response = await ApiService.put(
        Apis.employeeSalary(id),
        body,
      );
      print('API EMPLOYEE SALARY Status......... 200');
      print('EMOLOYEE SALARY Response...... $response');

      isUpdating = false;
      _safeUpdate();

      _showSuccess('Salary updated successfully!');

      // Refresh to show updated values
      print('│ [API 2] Refreshing salary data...');
      await fetchSalary();
    } on ApiException catch (e) {
      print('│ [API 2] ❌ ApiException ${e.statusCode}: ${e.message}');
      isUpdating = false;
      _safeUpdate();
      _showError(e.message);
    } catch (e) {
      print('│ [API 2] ❌ Unknown error: $e');
      isUpdating = false;
      _safeUpdate();
      _showError('Network error. Check your connection.');
    }

    print('.................................................');
  }

  // Format helpers (controller owns formatting logic)

  // Format number → "45,000.00"
  String formatAmount(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$intPart.${parts[1]}';
  }

  // Status color for payroll history
  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return const Color(0xFF00B894);
      case 'pending':
        return const Color(0xFFFDAA2B);
      case 'failed':
        return const Color(0xFFFF7675);
      default:
        return const Color(0xFF74788D);
    }
  }

  // Capitalize first letter
  String capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  //Safe update
  void _safeUpdate() {
    if (!isClosed) update();
  }

  // Snackbars
  void _showSuccess(String msg) => Get.snackbar(
    'Success!',
    msg,
    backgroundColor: const Color(0xFF00B894),
    colorText: Colors.white,
    snackPosition: SnackPosition.TOP,
    borderRadius: 12,
    margin: const EdgeInsets.all(16),
    duration: const Duration(seconds: 3),
  );

  void _showError(String msg) => Get.snackbar(
    'Error',
    msg,
    backgroundColor: const Color(0xFFFF7675),
    colorText: Colors.white,
    snackPosition: SnackPosition.TOP,
    borderRadius: 12,
    margin: const EdgeInsets.all(16),
  );
}
