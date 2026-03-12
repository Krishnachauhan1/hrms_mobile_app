import 'package:employee_app/hr_flow/controller/main_shell_controller.dart';
import 'package:employee_app/hr_flow/models/employee_model.dart';
import 'package:employee_app/hr_flow/routes/app_routes.dart';
import 'package:get/get.dart';

class EmployeeListController extends GetxController {
  late final MainShellController _shell;

  String searchQuery = '';
  String selectedFilter = 'All';

  @override
  void onInit() {
    super.onInit();
    _shell = Get.find<MainShellController>();
  }

  List<Employee> get filteredEmployees {
    var result = _shell.employees.toList();

    if (searchQuery.isNotEmpty) {
      result = result.where((e) {
        return e.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            e.employeeCode.toLowerCase().contains(
              searchQuery.toLowerCase(),
            ) ||
            e.department.toLowerCase().contains(
              searchQuery.toLowerCase(),
            );
      }).toList();
    }

    if (selectedFilter != 'All') {
      result = result.where((e) => e.status == selectedFilter).toList();
    }

    return result;
  }

  void searchEmployees(String query) {
    searchQuery = query;
    update();
  }

  void setFilter(String filter) {
    selectedFilter = filter;
    update();
  }

  void viewEmployeeDetails(Employee employee) {
    Get.toNamed(AppRoutes.EMPLOYEE_DETAILS, arguments: employee);
  }

  int get total => _shell.employees.length;
  int get activeCount =>
      _shell.employees.where((e) => e.status == 'Active').length;
  int get onLeaveCount =>
      _shell.employees.where((e) => e.status == 'On Leave').length;
}
