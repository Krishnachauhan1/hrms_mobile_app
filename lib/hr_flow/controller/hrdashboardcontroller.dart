import 'package:employee_app/hr_flow/models/employee_model.dart';
import 'package:employee_app/hr_flow/models/leave_request_model.dart';
import 'package:employee_app/hr_flow/routes/app_routes.dart';
import 'package:get/get.dart';

class HRDashboardController extends GetxController {
  final List<Employee> employees = <Employee>[];
  final List<LeaveRequest> pendingLeaves = <LeaveRequest>[];
  int totalEmployees = 0;
  int activeEmployees = 0;
  int onLeaveEmployees = 0;
  int loggedInEmployees = 0;

  @override
  void onInit() {
    super.onInit();
  }

  void updateStatistics() {
    totalEmployees = employees.length;
    activeEmployees = employees.where((e) => e.status == 'Active').length;
    onLeaveEmployees = employees.where((e) => e.status == 'On Leave').length;
    loggedInEmployees = employees.where((e) => e.isLoggedIn == true).length;

    update();
  }

  void navigateToEmployeeList() {
    Get.toNamed(AppRoutes.EMPLOYEE_LIST);
  }

  void navigateToLeaveManagement() {
    Get.toNamed(AppRoutes.LEAVE_MANAGEMENT);
  }

  void navigateToSalaryManagement() {
    Get.toNamed(AppRoutes.SALARY_MANAGEMENT);
  }

  void navigateToAttendance() {
    Get.toNamed(AppRoutes.ATTENDANCE);
  }

  void logout() {
    Get.offAllNamed(AppRoutes.LOGIN);
  }
}
