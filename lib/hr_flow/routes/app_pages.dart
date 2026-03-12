import 'package:get/get.dart';
import 'package:employee_app/hr_flow/controller/attendance_controller.dart';
import 'package:employee_app/hr_flow/controller/employee_detail_controller.dart';
import 'package:employee_app/hr_flow/controller/employee_list_controller.dart';
import 'package:employee_app/hr_flow/controller/leave_management_controller.dart';
import 'package:employee_app/hr_flow/controller/main_shell_controller.dart';
import 'package:employee_app/hr_flow/controller/salary_management_controller.dart';
import 'package:employee_app/hr_flow/main_shell_view.dart';
import 'package:employee_app/hr_flow/screen/employee_details_view.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.MAIN_SHELL,
      page: () => const MainShellView(),
      binding: BindingsBuilder(() {
        Get.put(MainShellController());
        Get.lazyPut(() => EmployeeListController());
        Get.lazyPut(() => LeaveManagementController());
        Get.lazyPut(() => SalaryManagementController());
        Get.lazyPut(() => AttendanceController());
      }),
    ),

    // EMPLOYEE DETAILS
    GetPage(
      name: AppRoutes.EMPLOYEE_DETAILS,
      page: () => const EmployeeDetailsView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => EmployeeDetailsController());
      }),
    ),
  ];
}
