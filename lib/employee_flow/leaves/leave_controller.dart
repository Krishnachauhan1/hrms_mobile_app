import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:employee_app/api_service.dart';
import 'package:employee_app/apis.dart';

//  LeaveType model
class LeaveType {
  final int id;
  final String name;
  final int totalDays;
  final bool isPaid;
  LeaveType({
    required this.id,
    required this.name,
    required this.totalDays,
    this.isPaid = true,
  });
  factory LeaveType.fromJson(Map<String, dynamic> json) => LeaveType(
    id: json['id'] as int,
    name: json['name'] as String,
    totalDays: json['total_days'] as int? ?? 0,
    isPaid: json['is_paid'] == true || json['is_paid'] == 1,
  );

  String get displayName => isPaid ? name : '$name (Unpaid)';
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

  // status color for UI
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
  final reasonController = TextEditingController();

  //  Dropdown data
  List<LeaveType> leaveTypes = [];
  LeaveType? selectedType;

  // History list
  List<LeaveApplication> leaveHistory = [];
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
    fetchLeaveTypes();
    fetchLeaveHistory();
  }

  // leave-types api is
  Future<void> fetchLeaveTypes() async {
    isLoadingTypes = true;
    _safeUpdate();

    try {
      final dynamic response = await ApiService.get(Apis.leaveTypes);
      print("leave type is ${Apis.leaveTypes}");
      List<dynamic> rawList = [];
      if (response is List) {
        rawList = response;
      } else if (response is Map && response['data'] != null) {
        rawList = response['data'] as List<dynamic>;
      }
      leaveTypes = rawList
          .map((e) => LeaveType.fromJson(e as Map<String, dynamic>))
          .toList();
      for (final t in leaveTypes) {
        print(
          'employee id is ${t.id}  employee name ${t.name}  total_days:${t.totalDays}',
        );
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
      isLoadingTypes = false;
      selectedType = null;
      errorMessage = 'Could not load leave types: ${e.message}';
      _safeUpdate();
      _showError(errorMessage!);
    } catch (e) {
      isLoadingTypes = false;
      selectedType = null;
      errorMessage = 'Network error while loading leave types.';
      _safeUpdate();
      _showError(errorMessage!);
    }
  }

  //  Api calling for leave-applications
  Future<void> fetchLeaveHistory() async {
    isLoadingHistory = true;
    _safeUpdate();

    try {
      final dynamic response = await ApiService.get(Apis.leaveApplications);
      print("leave application ${Apis.leaveApplications}");
      print("Full API response: $response");
      print("Response type: ${response.runtimeType}");
      List<dynamic> rawList = [];
      if (response is List) {
        rawList = response;
      } else if (response is Map && response['data'] != null) {
        rawList = response['data'] as List<dynamic>;
        print("print the leave data is=======$rawList");
      }
      leaveHistory = rawList
          .map((e) => LeaveApplication.fromJson(e as Map<String, dynamic>))
          .toList();

      for (final a in leaveHistory) {
        print(
          'id...${a.id}  type....${a.leaveTypeName}  ${a.fromDate}→${a.toDate}  status is ....${a.status}',
        );
      }
      _computeBalance();
      isLoadingHistory = false;
      _safeUpdate();
    } on ApiException catch (e) {
      isLoadingHistory = false;
      _safeUpdate();
      _showError('Could not load leave history is ${e.message}');
    } catch (e) {
      isLoadingHistory = false;
      _safeUpdate();
      _showError('Network error. Try again.');
    }
  }

  //  Compute leave balance
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

      if (!type.isPaid) {
        leaveBalance[type.name] = {
          'total': 0,
          'used': usedCount,
          'remaining': -1,
        };
        continue;
      }

      leaveBalance[type.name] = {
        'total': type.totalDays,
        'used': usedCount,
        'remaining': type.totalDays - usedCount,
      };
    }
  }

  //  Date pickers
  Future<void> selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      startDate = picked;
      if (endDate.isBefore(startDate)) endDate = startDate;
      _safeUpdate();
    }
  }

  Future<void> selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate,
      firstDate: startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      endDate = picked;
      _safeUpdate();
    }
  }

  void onLeaveTypeChanged(LeaveType? type) {
    if (type == null) return;
    selectedType = type;
    _safeUpdate();
  }

  // API leave-applications
  Future<void> submitLeave() async {
    // Validation
    if (selectedType == null) {
      _showError('Please select a leave type');
      return;
    }

    final reason = reasonController.text.trim();

    if (reason.isEmpty) {
      _showError('Please enter a reason');
      return;
    }

    if (endDate.isBefore(startDate)) {
      _showError('End date cannot be before start date');
      return;
    }

    // Request body
    final Map<String, dynamic> body = {
      'leave_type_id': selectedType!.id,
      'from_date': _formatDate(startDate),
      'to_date': _formatDate(endDate),
      'reason': reason,
    };

    isSubmitting = true;
    _safeUpdate();

    try {
      print("========== LEAVE SUBMIT ==========");
      print("API => ${Apis.leaveApplications}");
      print("Selected Type => ${selectedType?.name}");
      print("Selected Type ID => ${selectedType?.id}");
      print("Start Date => ${_formatDate(startDate)}");
      print("End Date => ${_formatDate(endDate)}");
      print("Reason => $reason");
      print("Request Body => $body");

      // API CALL
      final response = await ApiService.post(
        Apis.leaveApplications,
        body: body,
        isAuth: true,
      );

      print("SUCCESS RESPONSE => $response");
      print("Response Type => ${response.runtimeType}");

      // Reset form after success
      reasonController.clear();
      startDate = DateTime.now();
      endDate = DateTime.now();

      isSubmitting = false;
      _safeUpdate();

      _showSuccess('Leave application submitted!');

      // Refresh leave history + balance
      await fetchLeaveHistory();
    } on ApiException catch (e) {
      print("========== API ERROR ==========");
      print("Error => ${e.message}");
      print("Request Body => $body");

      isSubmitting = false;
      _safeUpdate();

      _showError(e.message);
    } catch (e, stackTrace) {
      print("========== UNKNOWN ERROR ==========");
      print("Error => $e");
      print("Stack => $stackTrace");

      isSubmitting = false;
      _safeUpdate();

      _showError('Network error. Check your connection.');
    }
  }

  // Date formatter
  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // Display date
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
