import 'package:employee_app/hr_flow/controller/main_shell_controller.dart';
import 'package:employee_app/hr_flow/models/leave_request_model.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../api_service.dart';
import '../../apis.dart';

class LeaveManagementController extends GetxController {
  late final MainShellController _shell;

  String selectedFilter = 'Pending';
  String? selectedLeaveTypeFilter;

  bool isSelectMode = false;
  final Set<String> selectedIds = <String>{};

  // Leave Types
  List<Map<String, dynamic>> leaveTypes = [];
  bool isLeaveTypesLoading = false;

  @override
  void onInit() {
    super.onInit();
    _shell = Get.find<MainShellController>();
    fetchLeaveTypes();
  }

  // Fetch Leave Types
  Future<void> fetchLeaveTypes() async {
    isLeaveTypesLoading = true;
    update();

    try {
      final res = await ApiService.get(Apis.leaveTypes);
      if (res['success'] == true) {
        final List data = res['data'];
        leaveTypes = data.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (e) {
      print('fetchLeaveTypes error $e');
    }
    isLeaveTypesLoading = false;
    update();
  }

  List<LeaveRequest> get filteredLeaves {
    List<LeaveRequest> list = selectedFilter == 'All'
        ? _shell.leaveRequests
        : _shell.leaveRequests
              .where((l) => l.status == selectedFilter)
              .toList();

    if (selectedLeaveTypeFilter != null) {
      list = list.where((l) => l.leaveType == selectedLeaveTypeFilter).toList();
    }

    return list;
  }

  void setFilter(String filter) {
    selectedFilter = filter;
    cancelSelectMode();
    update();
  }

  void setLeaveTypeFilter(String? typeName) {
    selectedLeaveTypeFilter = typeName;
    update();
  }

  //Single Actions
  void approveSingle(LeaveRequest leave) {
    _shell.approveLeave(leave.id);
    update();
    Get.snackbar(
      'Approved',
      '${leave.employeeName}\'s leave has been approved',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void rejectSingle(LeaveRequest leave) {
    final commentController = TextEditingController();
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Leave'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reason for rejecting ${leave.employeeName}\'s leave:'),
            const SizedBox(height: 12),
            TextField(
              controller: commentController,
              decoration: InputDecoration(
                hintText: 'Enter reason______',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              _shell.rejectLeave(leave.id, commentController.text);
              update();
              Get.back();
              Get.snackbar(
                'Rejected',
                '${leave.employeeName}\'s leave has been rejected',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
                duration: const Duration(seconds: 2),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  //Bulk Selection
  void toggleSelectMode() {
    isSelectMode = !isSelectMode;
    if (!isSelectMode) selectedIds.clear();
    update();
  }

  void cancelSelectMode() {
    isSelectMode = false;
    selectedIds.clear();
    update();
  }

  void toggleSelection(String id) {
    if (selectedIds.contains(id)) {
      selectedIds.remove(id);
    } else {
      selectedIds.add(id);
    }
    if (selectedIds.isEmpty) isSelectMode = false;
    update();
  }

  void selectAll() {
    final pending = filteredLeaves
        .where((l) => l.status == 'Pending')
        .map((l) => l.id)
        .toList();
    selectedIds.addAll(pending);
    isSelectMode = selectedIds.isNotEmpty;
    update();
  }

  void bulkApprove() {
    final count = selectedIds.length;
    _shell.bulkApproveLeaves(selectedIds.toList());
    cancelSelectMode();
    update();
    Get.snackbar(
      'Bulk Approved',
      '$count leave request${count > 1 ? 's' : ''} approved successfully',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  void bulkReject() {
    final commentController = TextEditingController();
    final count = selectedIds.length;
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reject $count Leave${count > 1 ? 's' : ''}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rejecting $count selected leave request${count > 1 ? 's' : ''}',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: commentController,
              decoration: InputDecoration(
                hintText: 'Common reason (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              _shell.bulkRejectLeaves(
                selectedIds.toList(),
                commentController.text,
              );
              Get.back();
              cancelSelectMode();
              update();
              Get.snackbar(
                'Bulk Rejected',
                '$count leave request${count > 1 ? 's' : ''} rejected',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject All'),
          ),
        ],
      ),
    );
  }

  int get pendingCount =>
      _shell.leaveRequests.where((l) => l.status == 'Pending').length;
  int get approvedCount =>
      _shell.leaveRequests.where((l) => l.status == 'Approved').length;
  int get rejectedCount =>
      _shell.leaveRequests.where((l) => l.status == 'Rejected').length;
}
