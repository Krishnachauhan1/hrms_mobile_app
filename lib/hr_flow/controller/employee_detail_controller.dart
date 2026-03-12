import 'package:employee_app/hr_flow/models/employee_model.dart';
import 'package:get/get.dart';

class EmployeeDetailsController extends GetxController {
  Employee? employee;

  @override
  void onInit() {
    super.onInit();

    if (Get.arguments != null) {
      employee = Get.arguments as Employee;
    }
  }
}
