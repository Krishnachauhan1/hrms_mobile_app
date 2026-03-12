import 'package:get/get.dart';
import 'package:employee_app/hr_flow/controller/attendance_controller.dart';
import 'package:employee_app/hr_flow/controller/employee_detail_controller.dart';
import 'package:employee_app/hr_flow/controller/employee_list_controller.dart';
import 'package:employee_app/hr_flow/controller/leave_management_controller.dart';
import 'package:employee_app/hr_flow/controller/login_controller.dart';
import 'package:employee_app/hr_flow/controller/main_shell_controller.dart';
import 'package:employee_app/hr_flow/controller/salary_management_controller.dart';
import 'package:employee_app/hr_flow/main_shell_view.dart';
import 'package:employee_app/hr_flow/screen/employee_details_view.dart';
import 'package:employee_app/hr_flow/screen/login_view_ui.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.LOGIN,
      page: () => const LoginView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<LoginController>(() => LoginController());
      }),
    ),
    GetPage(
      name: AppRoutes.MAIN_SHELL,
      page: () => const MainShellView(),
      binding: BindingsBuilder(() {
        Get.put<MainShellController>(MainShellController());
        Get.lazyPut<EmployeeListController>(() => EmployeeListController());
        Get.lazyPut<LeaveManagementController>(
          () => LeaveManagementController(),
        );
        Get.lazyPut<SalaryManagementController>(
          () => SalaryManagementController(),
        );
        Get.lazyPut<AttendanceController>(() => AttendanceController());
      }),
    ),
    GetPage(
      name: AppRoutes.EMPLOYEE_DETAILS,
      page: () => const EmployeeDetailsView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<EmployeeDetailsController>(
          () => EmployeeDetailsController(),
        );
      }),
    ),
  ];
}
