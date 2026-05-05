import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:employee_app/api_service.dart';
import 'package:employee_app/apis.dart';
import 'package:employee_app/authentication/auth_controller.dart';

class SalaryDetail {
  final int id;
  final int employeeId;

  final double basicSalary;
  final double hra;
  final double conveyanceAllowance;
  final double medicalAllowance;
  final double specialAllowance;

  final double grossSalary;
  final double netSalary;
  final double deductions;

  final String overtimeAllowed;
  final double overtimeRatePerHour;

  final String currentMonth;

  // Breakdown items
  final List<Map<String, dynamic>> allowances;
  final List<Map<String, dynamic>> deductionItems;
  final List<Map<String, dynamic>> payrollHistory;

  SalaryDetail({
    required this.id,
    required this.employeeId,
    required this.basicSalary,
    required this.hra,
    required this.conveyanceAllowance,
    required this.medicalAllowance,
    required this.specialAllowance,
    required this.grossSalary,
    required this.netSalary,
    required this.deductions,
    required this.overtimeAllowed,
    required this.overtimeRatePerHour,
    required this.currentMonth,
    required this.allowances,
    required this.deductionItems,
    required this.payrollHistory,
  });

  // 🔥 Safe parser
  factory SalaryDetail.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is int) return val.toDouble();
      if (val is double) return val;
      return double.tryParse(val.toString()) ?? 0.0;
    }

    final basic = toDouble(json['basic_salary']);
    final hra = toDouble(json['hra']);
    final conveyance = toDouble(json['conveyance_allowance']);
    final medical = toDouble(json['medical_allowance']);
    final special = toDouble(json['special_allowance']);

    final gross = toDouble(json['gross_salary']);

    // 👉 Simple deduction logic (you can improve later)
    final pfPercent = toDouble(json['pf_percentage']);
    final esiPercent = toDouble(json['esi_percentage']);

    final pfAmount = (basic * pfPercent) / 100;
    final esiAmount = (gross * esiPercent) / 100;

    final totalDeductions = pfAmount + esiAmount;
    final net = gross - totalDeductions;

    return SalaryDetail(
      id: json['id'] as int? ?? 0,
      employeeId: json['employee_id'] as int? ?? 0,

      basicSalary: basic,
      hra: hra,
      conveyanceAllowance: conveyance,
      medicalAllowance: medical,
      specialAllowance: special,

      grossSalary: gross,
      netSalary: net,
      deductions: totalDeductions,

      overtimeAllowed: json['overtime_allowed']?.toString() ?? 'no',
      overtimeRatePerHour: toDouble(json['overtime_rate_per_hour']),

      currentMonth: json['current_month']?.toString() ?? '',

      // ✅ Build allowances from API fields
      allowances: [
        {'name': 'Basic Salary', 'amount': basic},
        {'name': 'HRA', 'amount': hra},
        {'name': 'Conveyance', 'amount': conveyance},
        {'name': 'Medical', 'amount': medical},
        {'name': 'Special Allowance', 'amount': special},
      ],

      // ✅ Deduction breakdown
      deductionItems: [
        if (pfAmount > 0) {'name': 'PF', 'amount': pfAmount},
        if (esiAmount > 0) {'name': 'ESI', 'amount': esiAmount},
      ],

      // Payroll history (safe)
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
    isLoading = true;
    errorMessage = null;
    _safeUpdate();

    try {
      // Step 1: API call — GET, no body needed
      final dynamic response = await ApiService.get(Apis.employeeSalary(id));
      // print('salary data is $response');
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
      isLoading = false;
      _safeUpdate();
    } on ApiException catch (e) {
      isLoading = false;
      errorMessage = e.message;
      _safeUpdate();
      _showError('Failed to load salary: ${e.message}');
    } catch (e) {
      isLoading = false;
      errorMessage = 'Network error. Could not load salary.';
      _safeUpdate();
      _showError('Network error. Try again.');
    }
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
    //  Validation
    if (monthlySalary <= 0) {
      _showError('Monthly salary must be greater than 0');
      return;
    }

    final Map<String, dynamic> body = {
      'monthly_salary': monthlySalary,
      'overtime_allowed': overtimeAllowed,
      'overtime_rate_per_hour': overtimeRatePerHour,
    };
    isUpdating = true;
    _safeUpdate();

    try {
      final dynamic response = await ApiService.put(
        Apis.employeeSalary(id),
        body,
      );
      isUpdating = false;
      _safeUpdate();
      _showSuccess('Salary updated successfully!');

      // Refresh to show updated values
      print('Refreshing salary data...');
      await fetchSalary();
    } on ApiException catch (e) {
      isUpdating = false;
      _safeUpdate();
      _showError(e.message);
    } catch (e) {
      isUpdating = false;
      _safeUpdate();
      _showError('Network error. Check your connection.');
    }
  }

  // Format helpers (controller owns formatting logic)
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
