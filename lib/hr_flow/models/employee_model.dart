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
  final String status;
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

  /// ✅ FROM JSON (MAIN FIX)
  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone']?.toString() ?? '',

      // 🔥 role_id → designation
      designation: "Role ${json['role_id'] ?? ''}",

      // 🔥 organization → department
      department: json['organization']?['industry_type'] ?? 'N/A',

      // 🔥 created_at → joiningDate
      joiningDate:
          DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),

      // 🔥 custom employee code
      employeeCode: "EMP${json['id']}",

      // 🔥 salary_structure → salary
      salary:
          double.tryParse(
            json['salary_structure']?['basic_salary']?.toString() ?? '0',
          ) ??
          0.0,

      // 🔥 is_active → status
      status: json['is_active'] == 1 ? "Active" : "Inactive",

      imageUrl: null,

      // 🔥 organization → address
      address: json['organization']?['city'] ?? 'N/A',

      emergencyContact: "N/A",
      bloodGroup: "N/A",

      lastLoginTime: null,
    );
  }

  /// OPTIONAL: toJson (future use)
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "email": email,
      "phone": phone,
      "designation": designation,
      "department": department,
      "joiningDate": joiningDate.toIso8601String(),
      "employeeCode": employeeCode,
      "salary": salary,
      "status": status,
      "address": address,
    };
  }

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
