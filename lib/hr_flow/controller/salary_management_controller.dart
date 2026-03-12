import 'package:employee_app/hr_flow/controller/main_shell_controller.dart';
import 'package:employee_app/hr_flow/models/employee_model.dart';
import 'package:get/get.dart';

class SalaryManagementController extends GetxController {
  late final MainShellController _shell;

  @override
  void onInit() {
    super.onInit();
    _shell = Get.find<MainShellController>();
  }

  List<Employee> get employees => _shell.employees;

  double get totalSalaryExpense =>
      employees.fold(0.0, (sum, emp) => sum + emp.salary);

  double getDepartmentSalary(String department) => employees
      .where((emp) => emp.department == department)
      .fold(0.0, (sum, emp) => sum + emp.salary);

  List<String> get departments =>
      employees.map((e) => e.department).toSet().toList();
}
