import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:employee_app/api_service.dart';
import 'package:employee_app/apis.dart';

//  LeaveType ke liye model
class LeaveType {
  final int id;
  final String name;
  final int totalDays;

  LeaveType({required this.id, required this.name, required this.totalDays});

  factory LeaveType.fromJson(Map<String, dynamic> json) => LeaveType(
    id: json['id'] as int,
    name: json['name'] as String,
    totalDays: json['total_days'] as int? ?? 0,
  );
}

// LeaveApplication
class LeaveApplication {
  final int id;
  final String leaveTypeName;
  final String fromDate;
  final String toDate;
  final String reason;
  final String status;

  LeaveApplication({
    required this.id,
    required this.leaveTypeName,
    required this.fromDate,
    required this.toDate,
    required this.reason,
    required this.status,
  });

  factory LeaveApplication.fromJson(Map<String, dynamic> json) {
    final leaveTypeRaw = json['leave_type'];
    final typeName = leaveTypeRaw is Map
        ? (leaveTypeRaw['name'] as String? ?? 'Leave')
        : (json['leave_type_name'] as String? ?? 'Leave');

    return LeaveApplication(
      id: json['id'] as int,
      leaveTypeName: typeName,
      fromDate: json['from_date'] as String? ?? '',
      toDate: json['to_date'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
    );
  }

  // Helper status color for UI
  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF00B894);
      case 'rejected':
        return const Color(0xFFFF7675);
      default:
        return const Color(0xFFFDAA2B);
    }
  }

  //  Helper formatted display string
  String get displayStatus => status[0].toUpperCase() + status.substring(1);
}

// Controller
class LeaveController extends GetxController {
  //  Form
  final reasonController = TextEditingController();

  //  Dropdown data
  List<LeaveType> leaveTypes = [];
  LeaveType? selectedType;

  // History list
  List<LeaveApplication> leaveHistory = [];

  //  Balance computed from leaveTypes (total_days per type)
  Map<String, Map<String, int>> leaveBalance = {};

  //  Dates

  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();

  // Loading flags

  bool isLoadingTypes = false;
  bool isLoadingHistory = false;
  bool isSubmitting = false;

  // Error
  String? errorMessage;

  @override
  void onInit() {
    super.onInit();
    print('LEAVE onInit fetching all data............');
    fetchLeaveTypes(); // Api keave type
    fetchLeaveHistory(); // Api leave-applicatio
  }

  // leave-types api is

  Future<void> fetchLeaveTypes() async {
    print('leave type api os....... ${Apis.baseUrl}${Apis.leaveTypes}');

    isLoadingTypes = true;
    _safeUpdate();

    try {
      final dynamic response = await ApiService.get(Apis.leaveTypes);
      print('Api Status: 200');
      print('Api Raw: $response');

      List<dynamic> rawList = [];
      if (response is List) {
        rawList = response;
      } else if (response is Map && response['data'] != null) {
        rawList = response['data'] as List<dynamic>;
      }

      leaveTypes = rawList
          .map((e) => LeaveType.fromJson(e as Map<String, dynamic>))
          .toList();

      print('Api is ${leaveTypes.length} leave types loaded:');
      for (final t in leaveTypes) {
        print('│   id:${t.id}  name:${t.name}  total_days:${t.totalDays}');
      }

      if (leaveTypes.isEmpty) {
        selectedType = null;
        errorMessage = 'No leave types available right now.';
      } else {
        errorMessage = null;
        final selectedId = selectedType?.id;
        selectedType = leaveTypes.firstWhereOrNull(
          (type) => type.id == selectedId,
        );
        selectedType ??= leaveTypes.first;
      }

      _computeBalance();
      isLoadingTypes = false;
      _safeUpdate();
    } on ApiException catch (e) {
      print('Api is.......${e.statusCode}: ${e.message}');
      isLoadingTypes = false;
      selectedType = null;
      errorMessage = 'Could not load leave types: ${e.message}';
      _safeUpdate();
      _showError(errorMessage!);
    } catch (e) {
      print('Leacve- tyoe Api Unknown $e');
      isLoadingTypes = false;
      selectedType = null;
      errorMessage = 'Network error while loading leave types.';
      _safeUpdate();
      _showError(errorMessage!);
    }
  }

  //  Api calling for leave-applications

  Future<void> fetchLeaveHistory() async {
    print(
      'leave-applications Api is............ ${Apis.baseUrl}${Apis.leaveApplications}',
    );
    isLoadingHistory = true;
    _safeUpdate();

    try {
      final dynamic response = await ApiService.get(Apis.leaveApplications);
      print('leave-applications Api Status is 200....................');
      print('leave-applications Api Raw is $response');
      List<dynamic> rawList = [];
      if (response is List) {
        rawList = response;
      } else if (response is Map && response['data'] != null) {
        rawList = response['data'] as List<dynamic>;
      }
      leaveHistory = rawList
          .map((e) => LeaveApplication.fromJson(e as Map<String, dynamic>))
          .toList();
      print(
        'leave-applications Api  ${leaveHistory.length} applications loaded.......',
      );
      for (final a in leaveHistory) {
        print(
          'id...${a.id}  type....${a.leaveTypeName}  ${a.fromDate}→${a.toDate}  status is ....${a.status}',
        );
      }
      _computeBalance();
      isLoadingHistory = false;
      _safeUpdate();
    } on ApiException catch (e) {
      print('leave-applications Api is ${e.statusCode}: ${e.message}');
      isLoadingHistory = false;
      _safeUpdate();
      _showError('Could not load leave history is ${e.message}');
    } catch (e) {
      print('leave-applications Api Unknown is $e');
      isLoadingHistory = false;
      _safeUpdate();
      _showError('Network error. Try again.');
    }
    print('.........................................................');
  }

  //  Compute leave balance from types & history
  // total  = leaveType.totalDay
  void _computeBalance() {
    leaveBalance = {};

    for (final type in leaveTypes) {
      final usedCount = leaveHistory
          .where(
            (a) =>
                a.leaveTypeName.toLowerCase() == type.name.toLowerCase() &&
                a.status.toLowerCase() == 'approved',
          )
          .length;

      leaveBalance[type.name] = {
        'total': type.totalDays,
        'used': usedCount,
        'remaining': type.totalDays - usedCount,
      };
    }

    print('LEAVE BALANCE Computed is................... $leaveBalance');
  }

  //  Date pickers
  Future<void> selectStartDate(BuildContext context) async {
    print('[LEAVE] Opening start date picker');
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      startDate = picked;
      if (endDate.isBefore(startDate)) endDate = startDate;
      print('[LEAVE] Start date → ${_formatDate(startDate)}');
      _safeUpdate();
    }
  }

  Future<void> selectEndDate(BuildContext context) async {
    print('[LEAVE] Opening end date picker');
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate,
      firstDate: startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      endDate = picked;
      print('[LEAVE] End date → ${_formatDate(endDate)}');
      _safeUpdate();
    }
  }

  void onLeaveTypeChanged(LeaveType? type) {
    if (type == null) return;
    selectedType = type;
    print('[LEAVE] Type changed → id:${type.id} name:${type.name}');
    _safeUpdate();
  }

  // API leave-applications
  Future<void> submitLeave() async {
    print(
      'leave-applications Api POST ${Apis.baseUrl}${Apis.leaveApplications}',
    );

    // Validation
    if (selectedType == null) {
      print('API ❌ No leave type selected');
      _showError('Please select a leave type');
      return;
    }
    final reason = reasonController.text.trim();
    print('find the ${reason}');

    if (reason.isEmpty) {
      print('API ❌ Reason empty');
      _showError('Please enter a reason');
      return;
    }
    if (endDate.isBefore(startDate)) {
      print('API ❌ End date before start date');
      _showError('End date cannot be before start date');
      return;
    }

    final Map<String, dynamic> body = {
      'leave_type_id': selectedType!.id,
      'from_date': _formatDate(startDate),
      'to_date': _formatDate(endDate),
      'reason': reason,
    };

    print('API Body: $body');

    isSubmitting = true;
    _safeUpdate();

    try {
      final dynamic response = await ApiService.post(
        Apis.leaveApplications,
        body,
      );
      print('leave-applications post API Success: $response');

      // Reset form
      reasonController.clear();
      startDate = DateTime.now();
      endDate = DateTime.now();
      isSubmitting = false;
      _safeUpdate();

      _showSuccess('Leave application submitted!');

      // Refresh history so new entry shows up
      print('│ [API 3] Refreshing history...');
      await fetchLeaveHistory();
    } on ApiException catch (e) {
      print('API leave-applications  ${e.statusCode}: ${e.message}');
      isSubmitting = false;
      _safeUpdate();
      _showError(e.message);
    } catch (e) {
      print('API leave-applications  Unknown: $e');
      isSubmitting = false;
      _safeUpdate();
      _showError('Network error. Check your connection.');
    }
  }

  // Date formatter → "YYYY-MM-DD"
  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // Display date → "01 Mar 2026"
  String formatDisplayDate(String raw) {
    try {
      final d = DateTime.parse(raw);
      const months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${d.day.toString().padLeft(2, '0')} ${months[d.month]} ${d.year}';
    } catch (_) {
      return raw;
    }
  }

  void _safeUpdate() {
    if (!isClosed) update();
  }

  void _showSuccess(String msg) => Get.snackbar(
    'Success!',
    msg,
    backgroundColor: const Color.fromARGB(255, 11, 127, 222),
    colorText: Colors.white,
    snackPosition: SnackPosition.TOP,
    borderRadius: 12,
    margin: const EdgeInsets.all(16),
    duration: const Duration(seconds: 3),
  );

  void _showError(String msg) => Get.snackbar(
    'Error',
    msg,
    backgroundColor: const Color(0xFFFF7675),
    colorText: Colors.white,
    snackPosition: SnackPosition.TOP,
    borderRadius: 12,
    margin: const EdgeInsets.all(16),
  );

  @override
  void onClose() {
    reasonController.dispose();
    super.onClose();
  }
}
