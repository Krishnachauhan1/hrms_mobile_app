class EmployeeProfile {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String? dateOfBirth;
  final String? joiningDate;
  final String? createdAt;
  final String? profileImage;
  final String roleName;
  final String managerName;

  const EmployeeProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.dateOfBirth,
    this.joiningDate,
    this.createdAt,
    this.profileImage,
    required this.roleName,
    required this.managerName,
  });

  factory EmployeeProfile.fromJson(Map<String, dynamic> json) {
    final role = json['role'];
    final manager = json['manager'];

    return EmployeeProfile(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      dateOfBirth: json['date_of_birth']?.toString(),
      joiningDate: json['joining_date']?.toString(),
      createdAt: json['created_at']?.toString(),
      profileImage: json['profile_image']?.toString(),
      roleName: role is Map ? role['name']?.toString() ?? '' : '',
      managerName: manager is Map ? manager['name']?.toString() ?? '' : '',
    );
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
