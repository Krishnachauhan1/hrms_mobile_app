import 'package:employee_app/api_service.dart';
import 'package:employee_app/employee_flow/device_info_service.dart';
import 'package:employee_app/employee_flow/employee_permission_controller.dart';
import 'package:employee_app/employee_flow/location/field_location_controller.dart';
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
    final deviceData = await DeviceInfoService.getDeviceInfo();

    final email = loginEmailController.text.trim();
    final password = loginPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Login failed', 'Please enter email and password.');
      return;
    }

    isLoginLoading = true;
    update();

    try {
      final data = await ApiService.login(
        email: email,
        password: password,
        deviceInfo: deviceData,
      );
      print('device info data is =========== $deviceData');
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

      if (employee != null) {
        final employeeId = employee['id'];
        final ctrl = Get.find<EmployeeFeatureController>();

        try {
          await ctrl.loadPermissions(employeeId);
          print("PERMISSIONS LOADED ✅");
        } catch (e) {
          print("PERMISSION ERROR ❌ === $e");
        }
      }

      final roleId = employee?["role_id"];

      if (roleId == 3) {
        if (!Get.isRegistered<FieldLocationController>()) {
          Get.put(FieldLocationController(), permanent: true);
        }
        await Get.find<FieldLocationController>().start();
        Get.offAllNamed("/home");
      } else {
        Get.offAllNamed(AppRoutes.MAIN_SHELL);
      }
    } on ApiException catch (e) {
      _showLoginError(e);
    } catch (e) {
      print('login error: $e');
      _showError('Login failed', 'Please check your email and password.');
    }

    isLoginLoading = false;
    update();
  }

  Future<void> logout() async {
    FieldLocationController.stopIfRegistered();
    await ApiService.clearToken();
    final ctrl = Get.find<EmployeeFeatureController>();
    // ctrl.reset();

    token = null;
    employee = null;
    loginEmailController.clear();
    loginPasswordController.clear();
    update();

    Get.offAllNamed('/login');
  }

  void _showLoginError(ApiException e) {
    if (e.isDeviceAlreadyInUse) {
      _showError('This phone is already linked to another employee.', '');
      return;
    }

    if (e.isDeviceMismatch) {
      _showError('Please login from your registered device only.', '');
      return;
    }

    if (e.statusCode == 401) {
      _showError('Login failed', 'Invalid email or password.');
      return;
    }

    _showError('Login failed', e.message);
  }

  void _showError(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: const Color(0xFFFF7675),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 5),
      messageText: message.isEmpty ? const SizedBox.shrink() : null,
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
