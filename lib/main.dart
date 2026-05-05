import 'package:employee_app/authentication/splash_scree.dart';
import 'package:employee_app/employee_flow/employee_permission_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
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
  Get.put(EmployeeFeatureController(), permanent: true);
  runApp(const HRMSApp());
}

class HRMSApp extends StatelessWidget {
  const HRMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Quick Salary',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF8F9FE),
        useMaterial3: true,
      ),

      initialBinding: BindingsBuilder(() {
        Get.put(AuthController(), permanent: true);
      }),
      initialRoute: '/splash',

      getPages: [
        GetPage(name: '/splash', page: () => SplashScreen()),
        GetPage(name: AppRoutes.LOGIN, page: () => const LoginPage()),
        GetPage(name: '/home', page: () => const HomePage()),
        ...AppPages.routes,
      ],
    );
  }
}
