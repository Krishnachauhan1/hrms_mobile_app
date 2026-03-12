import 'package:get/get.dart';
import 'package:employee_app/hr_flow/models/attendance_model.dart';
import 'package:employee_app/hr_flow/models/employee_model.dart';
import 'package:employee_app/hr_flow/models/leave_request_model.dart';

class MainShellController extends GetxController {
  int currentIndex = 0;
  final List<Employee> employees = <Employee>[];
  final List<LeaveRequest> leaveRequests = <LeaveRequest>[];
  final List<Attendance> attendanceRecords = <Attendance>[];

  @override
  void onInit() {
    super.onInit();
    _loadSampleData();
  }

  void changePage(int index) {
    currentIndex = index;
    update();
  }

  // ── Stats ────────────────────────────────────────────────
  int get totalEmployees => employees.length;
  int get activeCount => employees.where((e) => e.status == 'Active').length;
  int get onLeaveCount => employees.where((e) => e.status == 'On Leave').length;
  int get loggedInCount => employees.where((e) => e.isLoggedIn).length;
  int get pendingLeaveCount =>
      leaveRequests.where((l) => l.status == 'Pending').length;

  // ── Leave Actions ────────────────────────────────────────
  void approveLeave(String leaveId) {
    final index = leaveRequests.indexWhere((l) => l.id == leaveId);
    if (index != -1) {
      leaveRequests[index] = leaveRequests[index].copyWith(
        status: 'Approved',
        hrComment: 'Approved by HR',
      );
      update();
    }
  }

  void rejectLeave(String leaveId, String comment) {
    final index = leaveRequests.indexWhere((l) => l.id == leaveId);
    if (index != -1) {
      leaveRequests[index] = leaveRequests[index].copyWith(
        status: 'Rejected',
        hrComment: comment.isEmpty ? 'Rejected by HR' : comment,
      );
      update();
    }
  }

  void bulkApproveLeaves(List<String> leaveIds) {
    for (final id in leaveIds) {
      approveLeave(id);
    }
  }

  void bulkRejectLeaves(List<String> leaveIds, String comment) {
    for (final id in leaveIds) {
      rejectLeave(id, comment);
    }
  }

  // ── Sample Data ──────────────────────────────────────────
  void _loadSampleData() {
    employees
      ..clear()
      ..addAll([
      Employee(
        id: '1',
        name: 'Ahmed Khan',
        email: 'ahmed@company.com',
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
        email: 'fatima@company.com',
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
        email: 'hassan@company.com',
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
        email: 'ayesha@company.com',
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
        email: 'bilal@company.com',
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
      Employee(
        id: '6',
        name: 'Zara Sheikh',
        email: 'zara@company.com',
        phone: '+92 305 6789012',
        designation: 'UI/UX Designer',
        department: 'IT',
        joiningDate: DateTime(2022, 4, 1),
        employeeCode: 'EMP006',
        salary: 90000,
        status: 'Active',
        address: 'Flat 12, Block A, Karachi',
        emergencyContact: '+92 305 2109876',
        bloodGroup: 'O-',
        totalLeaves: 24,
        usedLeaves: 2,
        isLoggedIn: false,
      ),
      ]);

    leaveRequests
      ..clear()
      ..addAll([
      LeaveRequest(
        id: 'LR001',
        employeeId: '1',
        employeeName: 'Ahmed Khan',
        department: 'IT',
        leaveType: 'Casual',
        startDate: DateTime.now().add(const Duration(days: 2)),
        endDate: DateTime.now().add(const Duration(days: 4)),
        reason: 'Family function in hometown',
        status: 'Pending',
        requestDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
      LeaveRequest(
        id: 'LR002',
        employeeId: '3',
        employeeName: 'Hassan Raza',
        department: 'Marketing',
        leaveType: 'Sick',
        startDate: DateTime.now().add(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 2)),
        reason: 'Fever and throat infection',
        status: 'Pending',
        requestDate: DateTime.now(),
      ),
      LeaveRequest(
        id: 'LR003',
        employeeId: '6',
        employeeName: 'Zara Sheikh',
        department: 'IT',
        leaveType: 'Annual',
        startDate: DateTime.now().add(const Duration(days: 5)),
        endDate: DateTime.now().add(const Duration(days: 10)),
        reason: 'Planned vacation with family',
        status: 'Pending',
        requestDate: DateTime.now().subtract(const Duration(days: 2)),
      ),
      LeaveRequest(
        id: 'LR004',
        employeeId: '4',
        employeeName: 'Ayesha Malik',
        department: 'Finance',
        leaveType: 'Emergency',
        startDate: DateTime.now().add(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 1)),
        reason: 'Medical emergency in family',
        status: 'Pending',
        requestDate: DateTime.now(),
      ),
      LeaveRequest(
        id: 'LR005',
        employeeId: '5',
        employeeName: 'Bilal Ahmed',
        department: 'Sales',
        leaveType: 'Casual',
        startDate: DateTime.now().subtract(const Duration(days: 5)),
        endDate: DateTime.now().subtract(const Duration(days: 3)),
        reason: 'Personal errands',
        status: 'Approved',
        requestDate: DateTime.now().subtract(const Duration(days: 7)),
        hrComment: 'Approved',
      ),
      LeaveRequest(
        id: 'LR006',
        employeeId: '2',
        employeeName: 'Fatima Ali',
        department: 'Human Resources',
        leaveType: 'Annual',
        startDate: DateTime.now().subtract(const Duration(days: 3)),
        endDate: DateTime.now().add(const Duration(days: 2)),
        reason: 'Annual vacation',
        status: 'Approved',
        requestDate: DateTime.now().subtract(const Duration(days: 10)),
        hrComment: 'Approved',
      ),
      ]);

    _generateAttendance();
    update();
  }

  void _generateAttendance() {
    final today = DateTime.now();
    final records = <Attendance>[];
    for (var emp in employees) {
      records.add(
        Attendance(
          id: '${emp.id}_today',
          employeeId: emp.id,
          employeeName: emp.name,
          department: emp.department,
          date: today,
          checkInTime: emp.isLoggedIn
              ? DateTime(today.year, today.month, today.day, 9, 0)
              : null,
          checkOutTime: null,
          status: emp.status == 'On Leave'
              ? 'On Leave'
              : emp.isLoggedIn
              ? 'Present'
              : 'Absent',
        ),
      );
      for (int i = 1; i <= 6; i++) {
        final d = today.subtract(Duration(days: i));
        records.add(
          Attendance(
            id: '${emp.id}_$i',
            employeeId: emp.id,
            employeeName: emp.name,
            department: emp.department,
            date: d,
            checkInTime: DateTime(d.year, d.month, d.day, 9, 0),
            checkOutTime: DateTime(d.year, d.month, d.day, 17, 30),
            status: 'Present',
          ),
        );
      }
    }
    attendanceRecords
      ..clear()
      ..addAll(records);
  }
}
