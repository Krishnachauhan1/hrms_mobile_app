import 'package:get/get.dart';
import 'package:employee_app/hr_flow/models/attendance_model.dart';
import 'package:employee_app/hr_flow/models/employee_model.dart';
import 'package:employee_app/hr_flow/models/leave_request_model.dart';
import '../../api_service.dart';
import '../../apis.dart';

class MainShellController extends GetxController {
  int currentIndex = 0;
  final List<Employee> employees = <Employee>[];
  final List<LeaveRequest> leaveRequests = [];
  final List<Attendance> attendanceRecords = <Attendance>[];

  bool isLeaveLoading = false;

  @override
  void onInit() {
    super.onInit();
    fetchLeaveApplications();
  }

  void changePage(int index) {
    currentIndex = index;
    update();
  }

  //  Fetch Leave Applications from API
  Future<void> fetchLeaveApplications() async {
    isLeaveLoading = true;
    update();
    try {
      final res = await ApiService.get(Apis.leaveApplications);

      print('leaves data $res');

      if (res["success"] == true) {
        final List data = res["data"];
        leaveRequests.clear();
        leaveRequests.addAll(
          data
              .map((e) => LeaveRequest.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      }
    } catch (e) {
      print(e);
    }
    isLeaveLoading = false;
    update();
  }

  // Stats
  int get totalEmployees => employees.length;
  int get activeCount => employees.where((e) => e.status == 'Active').length;
  int get onLeaveCount => employees.where((e) => e.status == 'On Leave').length;
  int get loggedInCount => employees.where((e) => e.isLoggedIn).length;
  int get pendingLeaveCount =>
      leaveRequests.where((l) => l.status.toLowerCase() == 'pending').length;

  //  Leave Actions with patch api
  Future<void> approveLeave(String leaveId) async {
    final index = leaveRequests.indexWhere((l) => l.id == leaveId);
    if (index != -1) {
      leaveRequests[index] = leaveRequests[index].copyWith(
        status: 'Approved',
        hrComment: 'Approved by HR',
      );
      update();
    }
    try {
      await ApiService.patch(
        Apis.leaveApplicationStatus(leaveId),
        body: {'status': 'approved'},
      );
    } catch (e) {
      // print('approveLeave error============ $e');

      if (index != -1) {
        leaveRequests[index] = leaveRequests[index].copyWith(status: 'Pending');
        update();
      }
    }
  }

  Future<void> rejectLeave(String leaveId, String comment) async {
    final index = leaveRequests.indexWhere((l) => l.id == leaveId);
    if (index != -1) {
      leaveRequests[index] = leaveRequests[index].copyWith(
        status: 'Rejected',
        hrComment: comment.isEmpty ? 'Rejected by HR' : comment,
      );
      update();
    }

    try {
      await ApiService.patch(
        Apis.leaveApplicationStatus(leaveId),
        body: {
          'status': 'rejected',
          if (comment.isNotEmpty) 'hr_comment': comment,
        },
      );
    } catch (e) {
      // print('rejectLeave error================== $e');
      if (index != -1) {
        leaveRequests[index] = leaveRequests[index].copyWith(status: 'Pending');
        update();
      }
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
}
