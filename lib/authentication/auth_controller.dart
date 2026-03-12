import 'package:employee_app/api_service.dart';
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
      _showError('Please fill in all fields');
      return;
    }
    if (!GetUtils.isEmail(email)) {
      _showError('Please enter a valid email');
      return;
    }

    isLoginLoading = true;
    update();

    try {
      final data = await ApiService.login(email: email, password: password);

      token = data['token'] ?? data['access_token'];
      employee =
          ApiService.extractEmployee(data) ??
          (data['employee'] ?? data['user'] ?? data['data']);

      if (token != null) {
        await ApiService.saveToken(token!);
      }
      if (employee != null) {
        await ApiService.saveEmployee(employee!);
      }

      Get.offAllNamed('/home');
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Network error. Please check your connection.');
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
