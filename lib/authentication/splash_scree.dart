import 'dart:async';
import 'package:employee_app/api_service.dart';
import 'package:employee_app/employee_flow/location/field_location_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    final token = await ApiService.getToken();
    print("TOKEN === $token");
    if (token == null || token.isEmpty) {
      Get.offAllNamed("/login");
      return;
    }
    try {
      final user = await ApiService.getEmployee();
      if (user != null) {
        if (user["role_id"] == 3) {
          if (!Get.isRegistered<FieldLocationController>()) {
            Get.put(FieldLocationController(), permanent: true);
          }
          await Get.find<FieldLocationController>().start();
          Get.offAllNamed("/home");
        } else {
          Get.offAllNamed("/mainShell");
        }
      } else {
        Get.offAllNamed("/login");
      }
    } catch (e) {
      print("API ERROR: $e");
      Get.offAllNamed("/home");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/ICON.jpeg", width: 120),

            const SizedBox(height: 20),
            const Text(
              "Quick Salary",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3436),
              ),
            ),

            const SizedBox(height: 30),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
