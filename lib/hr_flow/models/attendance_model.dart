class Attendance {
  final String id;
  final String employeeId;
  final String employeeName;
  final String department;
  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String status; // Present, Absent, Half Day, On Leave
  final String? remarks;

  Attendance({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.department,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    required this.status,
    this.remarks,
  });

  String get workingHours {
    if (checkInTime != null && checkOutTime != null) {
      final duration = checkOutTime!.difference(checkInTime!);
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      return '${hours}h ${minutes}m';
    }
    return 'N/A';
  }

  Attendance copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? department,
    DateTime? date,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? status,
    String? remarks,
  }) {
    return Attendance(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      department: department ?? this.department,
      date: date ?? this.date,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
    );
  }
}
