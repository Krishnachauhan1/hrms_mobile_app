class LeaveRequest {
  final String id;
  final String employeeId;
  final String employeeName;
  final String department;
  final DateTime fromDate;
  final DateTime toDate;
  final int totalDays;
  final String reason;
  final String status;
  final String leaveTypeName;
  final String leaveType;
  final int? leaveTypeId;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime requestDate;
  final String? hrComment;

  LeaveRequest({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.department,
    required this.fromDate,
    required this.toDate,
    required this.totalDays,
    required this.reason,
    required this.status,
    required this.leaveTypeName,
    required this.leaveType,
    this.leaveTypeId,
    required this.startDate,
    required this.endDate,
    required this.requestDate,
    this.hrComment,
  });

  /// total days calculate
  int get numberOfDays => endDate.difference(startDate).inDays + 1;

  // copyWith
  LeaveRequest copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? department,
    String? leaveType,
    int? leaveTypeId,
    String? leaveTypeName,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? fromDate,
    DateTime? toDate,
    int? totalDays,
    String? reason,
    String? status,
    DateTime? requestDate,
    String? hrComment,
  }) {
    return LeaveRequest(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      department: department ?? this.department,
      leaveType: leaveType ?? this.leaveType,
      leaveTypeId: leaveTypeId ?? this.leaveTypeId,
      leaveTypeName: leaveTypeName ?? this.leaveTypeName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      totalDays: totalDays ?? this.totalDays,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      requestDate: requestDate ?? this.requestDate,
      hrComment: hrComment ?? this.hrComment,
    );
  }

  // fromJson
  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    final leaveTypeObj = json['leave_type'];

    DateTime from =
        DateTime.tryParse(json['from_date'] ?? '') ?? DateTime.now();

    DateTime to = DateTime.tryParse(json['to_date'] ?? '') ?? DateTime.now();

    return LeaveRequest(
      id: json['id'].toString(),
      employeeId: json['employee_id']?.toString() ?? '',
      employeeName: json['employee_name'] ?? '',
      department: json['department'] ?? '',

      fromDate: from,
      toDate: to,

      totalDays: json['total_days'] ?? to.difference(from).inDays + 1,

      leaveTypeName:
          json['leave_type_name'] ??
          (leaveTypeObj is Map ? leaveTypeObj['name'] : ''),

      leaveType:
          json['leave_type_name'] ??
          (leaveTypeObj is Map ? leaveTypeObj['name'] : 'Leave'),

      leaveTypeId: json['leave_type_id'],

      startDate: from,
      endDate: to,
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'Pending',
      requestDate:
          DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      hrComment: json['hr_comment'],
    );
  }
}
