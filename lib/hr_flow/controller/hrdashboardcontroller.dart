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
    loadSampleData();
  }

  void loadSampleData() {
    // Sample Employees
    employees
      ..clear()
      ..addAll([
      Employee(
        id: '1',
        name: 'Ahmed Khan',
        email: 'ahmed.khan@company.com',
        phone: '+92 300 1234567',
        designation: 'Senior Developer',
        department: 'IT',
        joiningDate: DateTime(2020, 5, 15),
        employeeCode: 'EMP001',
        salary: 150000,
        status: 'Active',
        address: 'House 123, Street 5, Karachi',
        emergencyContact: '+92 300 7654321',
        bloodGroup: 'B+',
        totalLeaves: 24,
        usedLeaves: 5,
        isLoggedIn: true,
        lastLoginTime: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Employee(
        id: '2',
        name: 'Fatima Ali',
        email: 'fatima.ali@company.com',
        phone: '+92 301 2345678',
        designation: 'HR Manager',
        department: 'Human Resources',
        joiningDate: DateTime(2019, 3, 10),
        employeeCode: 'EMP002',
        salary: 120000,
        status: 'On Leave',
        address: 'Apartment 45, Block C, Lahore',
        emergencyContact: '+92 301 8765432',
        bloodGroup: 'A+',
        totalLeaves: 24,
        usedLeaves: 8,
        isLoggedIn: false,
      ),
      Employee(
        id: '3',
        name: 'Hassan Raza',
        email: 'hassan.raza@company.com',
        phone: '+92 302 3456789',
        designation: 'Marketing Executive',
        department: 'Marketing',
        joiningDate: DateTime(2021, 7, 20),
        employeeCode: 'EMP003',
        salary: 80000,
        status: 'Active',
        address: 'House 67, Garden Town, Islamabad',
        emergencyContact: '+92 302 9876543',
        bloodGroup: 'O+',
        totalLeaves: 24,
        usedLeaves: 3,
        isLoggedIn: true,
        lastLoginTime: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      Employee(
        id: '4',
        name: 'Ayesha Malik',
        email: 'ayesha.malik@company.com',
        phone: '+92 303 4567890',
        designation: 'Accountant',
        department: 'Finance',
        joiningDate: DateTime(2018, 11, 5),
        employeeCode: 'EMP004',
        salary: 95000,
        status: 'Active',
        address: 'Plot 89, Sector F-8, Islamabad',
        emergencyContact: '+92 303 0987654',
        bloodGroup: 'AB+',
        totalLeaves: 24,
        usedLeaves: 12,
        isLoggedIn: false,
      ),
      Employee(
        id: '5',
        name: 'Bilal Ahmed',
        email: 'bilal.ahmed@company.com',
        phone: '+92 304 5678901',
        designation: 'Sales Manager',
        department: 'Sales',
        joiningDate: DateTime(2020, 1, 15),
        employeeCode: 'EMP005',
        salary: 110000,
        status: 'Active',
        address: 'House 234, DHA Phase 5, Karachi',
        emergencyContact: '+92 304 1098765',
        bloodGroup: 'B-',
        totalLeaves: 24,
        usedLeaves: 7,
        isLoggedIn: true,
        lastLoginTime: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      ]);

    // Sample Leave Requests
    pendingLeaves
      ..clear()
      ..addAll([
      LeaveRequest(
        id: '1',
        employeeId: '1',
        employeeName: 'Ahmed Khan',
        leaveType: 'Casual',
        startDate: DateTime.now().add(const Duration(days: 2)),
        endDate: DateTime.now().add(const Duration(days: 4)),
        reason: 'Family function',
        status: 'Pending',
        requestDate: DateTime.now().subtract(const Duration(days: 1)),
        department: '',
      ),
      LeaveRequest(
        id: '2',
        employeeId: '3',
        employeeName: 'Hassan Raza',
        leaveType: 'Sick',
        startDate: DateTime.now().add(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 2)),
        reason: 'Medical checkup',
        status: 'Pending',
        requestDate: DateTime.now(),
        department: '',
      ),
      ]);

    updateStatistics();
    update();
  }

  void updateStatistics() {
    totalEmployees = employees.length;
    activeEmployees = employees.where((e) => e.status == 'Active').length;
    onLeaveEmployees = employees.where((e) => e.status == 'On Leave').length;
    loggedInEmployees = employees.where((e) => e.isLoggedIn).length;
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
