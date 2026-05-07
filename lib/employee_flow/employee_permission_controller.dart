import 'package:employee_app/api_service.dart';
import 'package:get/get.dart';

class EmployeeFeatureController extends GetxController {
  bool canViewSalary = false;
  bool canUseFace = false;
  bool isLoading = false;

  @override
  void onInit() {
    super.onInit();
    _initPermissions();
  }

  Future<void> _initPermissions() async {
    final employeeId = await ApiService.getEmployeeId();

    if (employeeId != null) {
      loadPermissions(employeeId);
    }
  }

  Future<void> loadPermissions(int employeeId) async {
    isLoading = true;
    update();

    try {
      final res = await ApiService.get(
        '/employee-permissions/employee/$employeeId',
      );
      final data = res['data'];
      canViewSalary =
          data['can_view_salary'] == 1 ||
          data['can_view_salary'] == true ||
          data['can_view_salary'].toString() == '1';

      canUseFace =
          data['can_use_face_recognition'] == 1 ||
          data['can_use_face_recognition'] == true ||
          data['can_use_face_recognition'].toString() == '1';
      print("PERMISSION RESPONSE = $res");
      print("FACE VALUE = ${data['can_use_face_recognition']}");
      print("SALARY VALUE = ${data['can_view_salary']}");
    } catch (e) {
      canViewSalary = false;
      canUseFace = false;
    }

    isLoading = false;
    update();
  }

  void reset() {
    canViewSalary = false;
    canUseFace = false;
    isLoading = false;
    update();
  }
}
