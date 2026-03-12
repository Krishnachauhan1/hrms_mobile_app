class Employee {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String designation;
  final String department;
  final DateTime joiningDate;
  final String employeeCode;
  final double salary;
  final String status; // Active, On Leave, Inactive
  final String? imageUrl;
  final String address;
  final String emergencyContact;
  final String bloodGroup;
  final int totalLeaves;
  final int usedLeaves;
  final bool isLoggedIn;
  final DateTime? lastLoginTime;

  Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.designation,
    required this.department,
    required this.joiningDate,
    required this.employeeCode,
    required this.salary,
    required this.status,
    this.imageUrl,
    required this.address,
    required this.emergencyContact,
    required this.bloodGroup,
    this.totalLeaves = 24,
    this.usedLeaves = 0,
    this.isLoggedIn = false,
    this.lastLoginTime,
  });

  int get remainingLeaves => totalLeaves - usedLeaves;

  Employee copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? designation,
    String? department,
    DateTime? joiningDate,
    String? employeeCode,
    double? salary,
    String? status,
    String? imageUrl,
    String? address,
    String? emergencyContact,
    String? bloodGroup,
    int? totalLeaves,
    int? usedLeaves,
    bool? isLoggedIn,
    DateTime? lastLoginTime,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      designation: designation ?? this.designation,
      department: department ?? this.department,
      joiningDate: joiningDate ?? this.joiningDate,
      employeeCode: employeeCode ?? this.employeeCode,
      salary: salary ?? this.salary,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      address: address ?? this.address,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      totalLeaves: totalLeaves ?? this.totalLeaves,
      usedLeaves: usedLeaves ?? this.usedLeaves,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      lastLoginTime: lastLoginTime ?? this.lastLoginTime,
    );
  }
}
