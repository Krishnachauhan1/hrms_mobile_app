import 'package:employee_app/api_service.dart';
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

  //  LOGIN
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
      print(data);
      final token = data["token"];
      final employee = data["employee"] ?? data["user"] ?? data["data"];
      //token

      if (token != null) {
        await ApiService.saveToken(token);
        print("TOKEN SAVED === $token");
      }
      final savedToken = await ApiService.getToken();
      print("AFTER LOGIN TOKEN === $savedToken");
      // employee
      if (employee != null) {
        await ApiService.saveEmployee(employee);
      }
      //organization id
      if (employee != null && employee["organization_id"] != null) {
        await ApiService.saveOrganizationId(
          employee["organization_id"].toString(),
        );
      }
      // print('print the data of login user ===$data');
      final roleId = employee?["role_id"];
      // print("ROLE ID = $roleId");
      if (roleId == 3) {
        Get.offAllNamed("/home");
      } else {
        Get.offAllNamed(AppRoutes.MAIN_SHELL);
      }
    } catch (e) {
      print('error is $e');
      _showError("Please check your id & password $e");
    }

    isLoginLoading = false;
    update();
  }

  // LOGOUT
  Future<void> logout() async {
    await ApiService.clearToken();
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

  // Dispose
  @override
  void onClose() {
    loginEmailController.dispose();
    loginPasswordController.dispose();
    super.onClose();
  }
}
