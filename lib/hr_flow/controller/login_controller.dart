// import 'package:get/get.dart';
// import 'package:flutter/material.dart';
// import 'package:employee_app/hr_flow/routes/app_routes.dart';

// class LoginController extends GetxController {
//   final emailController = TextEditingController();
//   final passwordController = TextEditingController();

//   bool isLoading = false;
//   bool isPasswordVisible = false;

//   @override
//   void onClose() {
//     emailController.dispose();
//     passwordController.dispose();
//     super.onClose();
//   }

//   void togglePasswordVisibility() {
//     isPasswordVisible = !isPasswordVisible;
//     update();
//   }

//   Future<void> login() async {
//     if (emailController.text.isEmpty || passwordController.text.isEmpty) {
//       Get.snackbar(
//         'Error',
//         'Please enter email and password',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//       return;
//     }

//     // Simple validation for HR login
//     if (emailController.text == 'hr@company.com' &&
//         passwordController.text == 'hr123') {
//       isLoading = true;
//       update();

//       // Simulate API call
//       await Future.delayed(const Duration(seconds: 2));

//       isLoading = false;
//       update();

//       Get.snackbar(
//         'Success',
//         'Login successful!',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.green,
//         colorText: Colors.white,
//       );

//       Get.offAllNamed(AppRoutes.MAIN_SHELL);
//     } else {
//       Get.snackbar(
//         'Error',
//         'Invalid credentials',
//         snackPosition: SnackPosition.BOTTOM,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//     }
//   }
// }
