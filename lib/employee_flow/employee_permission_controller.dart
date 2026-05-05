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
        'employee-permissions/employee/$employeeId',
      );
      final data = res['data'];
      canViewSalary = data['can_view_salary'] == 1;
      canUseFace = data['can_use_face_recognition'] == 1;
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
