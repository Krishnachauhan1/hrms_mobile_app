import 'package:get/get.dart';
import '../../api_service.dart';
import '../../apis.dart';

class SalaryManagementController extends GetxController {
  List<Map<String, dynamic>> employees = [];

  bool isLoading = false;

  @override
  void onInit() {
    super.onInit();
    fetchEmployeesSalary();
  }

  Future<void> fetchEmployeesSalary() async {
    isLoading = true;
    update();
    try {
      final res = await ApiService.get("/employees");
      List list = res['data'];
      employees = [];
      for (var e in list) {
        int id = e['id'];
        final salaryRes = await ApiService.get(Apis.employeeSalary(id));
        // print('USERS SALARY ====$salaryRes');
        Map salaryData = salaryRes['data'];
        employees.add({
          ...e,
          ...salaryData,
          "department": e["department"] ?? "General",
        });
      }
    } catch (e) {
      print(e);
    }
    isLoading = false;
    update();
  }

  Future updateSalary(int id, double salary) async {
    await ApiService.put(Apis.employeeSalary(id), {"monthly_salary": salary});
    fetchEmployeesSalary();
  }

  double get totalSalaryExpense => employees.fold(
    0.0,
    (sum, emp) =>
        sum + double.tryParse(emp["basic_salary"]?.toString() ?? "0")!,
  );
  double getDepartmentSalary(String department) => employees
      .where((emp) => (emp["department"] ?? "") == department)
      .fold(
        0.0,
        (sum, emp) =>
            sum + double.tryParse(emp["basic_salary"]?.toString() ?? "0")!,
      );

  List<String> get departments =>
      employees.map((e) => (e["department"] ?? '').toString()).toSet().toList();
}
