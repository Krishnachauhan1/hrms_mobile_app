import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:employee_app/api_service.dart';
import 'package:employee_app/authentication/auth_controller.dart';
import 'package:employee_app/authentication/login_screen.dart';

import 'package:employee_app/employee_flow/bottomnav/homepage.dart';

// HR routes
import 'package:employee_app/hr_flow/routes/app_pages.dart';
import 'package:employee_app/hr_flow/routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  final bool isLoggedIn = await ApiService.isLoggedIn();
  final employee = await ApiService.getEmployee();

  String initialRoute = AppRoutes.LOGIN;

  if (isLoggedIn && employee != null) {
    String role = employee['role'] ?? employee['type'] ?? "employee";

    if (role == "hr") {
      initialRoute = AppRoutes.MAIN_SHELL;
    } else {
      initialRoute = '/home';
    }
  }

  runApp(HRMSApp(initialRoute: initialRoute));
}

class HRMSApp extends StatelessWidget {
  final String initialRoute;

  const HRMSApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'HRMS',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF8F9FE),
        useMaterial3: true,
      ),

      initialBinding: BindingsBuilder(() {
        Get.put(AuthController(), permanent: true);
      }),

      initialRoute: initialRoute,

      getPages: [
        GetPage(name: AppRoutes.LOGIN, page: () => const LoginPage()),
        GetPage(name: '/home', page: () => const HomePage()),
        ...AppPages.routes,
      ],
    );
  }
}
