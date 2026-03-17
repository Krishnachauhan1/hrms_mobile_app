import 'package:employee_app/hr_flow/controller/main_shell_controller.dart';
import 'package:employee_app/hr_flow/models/employee_model.dart';
import 'package:employee_app/hr_flow/routes/app_routes.dart';
import 'package:get/get.dart';
import '../../api_service.dart';
import '../../apis.dart';

class EmployeeListController extends GetxController {
  late final MainShellController _shell;
  List<Map<String, dynamic>> employee = [];
  String searchQuery = '';
  String selectedFilter = 'All';

  @override
  void onInit() {
    super.onInit();
    _shell = Get.find<MainShellController>();
    fetchEmployees();
  }

  Future<void> fetchEmployees() async {
    try {
      final orgId = await ApiService.getOrganizationId();
      // print("org id = $orgId");
      if (orgId == null || orgId.isEmpty) {
        print("org id null");
        return;
      }
      final res = await ApiService.get(Apis.organizationbyemployee(orgId));
      // print('employee daata is======$res');
      if (res["success"] == true) {
        final List data = res["data"];
        _shell.employees.clear();
        _shell.employees.addAll(
          data.map((e) {
            return Employee(
              id: e["id"].toString(),
              name: e["name"] ?? "",
              employeeCode: e["id"].toString(),
              department: e["organization"]?["organization_name"] ?? "",
              designation: e["role"] ?? "",
              status: e["is_active"] == 1 ? "Active" : "Inactive",
              isLoggedIn: false,
              email: e["email"] ?? "",
              phone: e["phone"] ?? "",
              salary: e["salary_structure"]?["monthly_salary"] != null
                  ? double.tryParse(
                          e["salary_structure"]["monthly_salary"].toString(),
                        ) ??
                        0
                  : 0,
              joiningDate: e["created_at"] != null
                  ? DateTime.parse(e["created_at"])
                  : DateTime.now(),
              address: e["address"] ?? "",
              emergencyContact: e["emergency_contact"] ?? "",
              bloodGroup: e["blood_group"] ?? "",
            );
          }).toList(),
        );
        update();
      }
    } catch (e) {
      print("employee error = $e");
    }
  }

  List<Employee> get filteredEmployees {
    var result = _shell.employees.toList();

    if (searchQuery.isNotEmpty) {
      result = result.where((e) {
        return e.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            e.employeeCode.toLowerCase().contains(searchQuery.toLowerCase()) ||
            e.department.toLowerCase().contains(searchQuery.toLowerCase());
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
