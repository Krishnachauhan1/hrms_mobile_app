class LeaveRequest {
  final String id;
  final String employeeId;
  final String employeeName;
  final String department;

  final String leaveType;
  final int? leaveTypeId;
  final String? leaveTypeName;

  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String status;
  final DateTime requestDate;
  final String? hrComment;

  LeaveRequest({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.department,
    required this.leaveType,
    this.leaveTypeId,
    this.leaveTypeName,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    required this.requestDate,
    this.hrComment,
  });

  int get numberOfDays => endDate.difference(startDate).inDays + 1;

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
      reason: reason ?? this.reason,
      status: status ?? this.status,
      requestDate: requestDate ?? this.requestDate,
      hrComment: hrComment ?? this.hrComment,
    );
  }

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    final leaveTypeObj = json['leave_type'];

    return LeaveRequest(
      id: json['id'].toString(),
      employeeId: json['employee_id']?.toString() ?? '',
      employeeName: json['employee_name'] ?? '',
      department: json['department'] ?? '',

      leaveTypeName:
          json['leave_type_name'] ??
          (leaveTypeObj is Map ? leaveTypeObj['name'] : null),

      leaveTypeId: json['leave_type_id'],

      leaveType:
          json['leave_type_name'] ??
          (leaveTypeObj is Map ? leaveTypeObj['name'] : 'Leave'),

      startDate: DateTime.tryParse(json['from_date'] ?? '') ?? DateTime.now(),

      endDate: DateTime.tryParse(json['to_date'] ?? '') ?? DateTime.now(),

      reason: json['reason'] ?? '',

      status: json['status'] ?? 'Pending',

      requestDate:
          DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),

      hrComment: json['hr_comment'],
    );
  }
}
