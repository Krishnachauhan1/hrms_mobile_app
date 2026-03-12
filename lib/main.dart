import 'package:employee_app/api_service.dart';
import 'package:employee_app/authentication/auth_controller.dart';
import 'package:employee_app/authentication/login_screen.dart';
import 'package:employee_app/employee_flow/bottomnav/homepage.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/bindings_interface.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:get/get_navigation/src/routes/get_route.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final bool isLoggedIn = await ApiService.isLoggedIn();
  final int? employeeId = await ApiService.getEmployeeId();
  final bool hasValidSession = !isLoggedIn || employeeId != null;

  runApp(HRMSApp(isLoggedIn: isLoggedIn && hasValidSession));
}

class HRMSApp extends StatelessWidget {
  final bool isLoggedIn;

  const HRMSApp({super.key, required this.isLoggedIn});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'HRMS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF8F9FE),
        fontFamily: 'SF Pro Display',
        useMaterial3: true,
      ),
      initialBinding: BindingsBuilder(() {
        Get.put(AuthController(), permanent: true);
      }),
      initialRoute: isLoggedIn ? '/home' : '/login',
      getPages: [
        GetPage(name: '/login', page: () => const LoginPage()),
        GetPage(name: '/home', page: () => const HomePage()),
      ],
    );
  }
}
