import 'package:employee_app/api_service.dart';
import 'package:employee_app/employee_flow/employee_permission_controller.dart';
import 'package:employee_app/hr_flow/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  final loginEmailController = TextEditingController();
  final loginPasswordController = TextEditingController();

  bool isLoginLoading = false;
  bool isLoginPasswordVisible = false;

  String? token;
  Map<String, dynamic>? employee;

  @override
  void onInit() {
    super.onInit();
    _loadSession();
  }

  void toggleLoginPassword() {
    isLoginPasswordVisible = !isLoginPasswordVisible;
    update();
  }

  Future<void> login() async {
    final email = loginEmailController.text.trim();
    final password = loginPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("Fill all fields");
      return;
    }

    isLoginLoading = true;
    update();

    try {
      final data = await ApiService.login(email: email, password: password);
      print('data is =========== $data');

      final token = data?["token"];
      final employee = data?["employee"];

      if (token != null) {
        await ApiService.saveToken(token);
      }

      if (employee != null) {
        await ApiService.saveEmployee(employee);
      }

      if (employee != null && employee["organization_id"] != null) {
        await ApiService.saveOrganizationId(
          employee["organization_id"].toString(),
        );
      }

      // ✅ PERMISSION KO SAFE BANAYA
      if (employee != null) {
        final employeeId = employee['id'];
        final ctrl = Get.find<EmployeeFeatureController>();

        try {
          await ctrl.loadPermissions(employeeId);
          print("PERMISSIONS LOADED ✅");
        } catch (e) {
          print("PERMISSION ERROR ❌ === $e");
          // ❗ ignore karo, login continue rahega
        }
      }

      // ✅ LOGIN ALWAYS CONTINUE
      final roleId = employee?["role_id"];
      if (roleId == 3) {
        Get.offAllNamed("/home");
      } else {
        Get.offAllNamed(AppRoutes.MAIN_SHELL);
      }

    } catch (e) {
      print('login error: $e');
      _showError("Please check your id & password");
    }

    isLoginLoading = false;
    update();
  }
  Future<void> logout() async {
    await ApiService.clearToken();
    final ctrl = Get.find<EmployeeFeatureController>();
    ctrl.reset();

    token = null;
    employee = null;
    loginEmailController.clear();
    loginPasswordController.clear();
    update();

    Get.offAllNamed('/login');
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: const Color(0xFFFF7675),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
    );
  }

  Future<void> _loadSession() async {
    token = await ApiService.getToken();
    employee = await ApiService.getEmployee();
    update();
  }

  @override
  void onClose() {
    loginEmailController.dispose();
    loginPasswordController.dispose();
    super.onClose();
  }
}
