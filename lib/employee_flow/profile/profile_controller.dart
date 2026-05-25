// import 'dart:io';

// import 'package:employee_app/api_service.dart';
// import 'package:employee_app/apis.dart';
// import 'package:employee_app/employee_flow/dashboard/dashboard_controller.dart';
// import 'package:employee_app/employee_flow/profile/employee_profile_model.dart';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';
// import 'package:intl/intl.dart';

// enum JoiningDateSource { none, profile, firstAttendance, enrollment }

// class ProfileController extends GetxController {
//   EmployeeProfile? profile;
//   String? effectiveJoiningDate;
//   JoiningDateSource joiningDateSource = JoiningDateSource.none;
//   bool isLoading = false;
//   bool isSaving = false;
//   String? errorMessage;

//   @override
//   void onInit() {
//     super.onInit();
//     fetchProfile();
//   }

//   Future<void> fetchProfile() async {
//     isLoading = true;
//     errorMessage = null;
//     update();

//     try {
//       final res = await ApiService.get(Apis.employeeProfile);
//       profile = _parseProfile(res);
//       if (profile != null) {
//         effectiveJoiningDate = await _resolveJoiningDate(profile!);
//         await ApiService.saveEmployee(_profileToEmployeeMap(profile!));
//         _syncDashboard();
//       }
//     } on ApiException catch (e) {
//       errorMessage = e.message;
//     } catch (e) {
//       errorMessage = 'Failed to load profile';
//     } finally {
//       isLoading = false;
//       update();
//     }
//   }

//   Future<bool> createProfile(Map<String, dynamic> body) async {
//     isSaving = true;
//     errorMessage = null;
//     update();

//     try {
//       final res = await ApiService.post(Apis.employeeProfile, body: body);
//       profile = _parseProfile(res);
//       if (profile != null) {
//         effectiveJoiningDate = await _resolveJoiningDate(profile!);
//         await ApiService.saveEmployee(_profileToEmployeeMap(profile!));
//         _syncDashboard();
//       }
//       return profile != null;
//     } on ApiException catch (e) {
//       errorMessage = e.message;
//       return false;
//     } catch (_) {
//       errorMessage = 'Failed to save profile';
//       return false;
//     } finally {
//       isSaving = false;
//       update();
//     }
//   }

//   Future<bool> updateProfile(Map<String, dynamic> body) async {
//     isSaving = true;
//     errorMessage = null;
//     update();

//     try {
//       final res = await ApiService.put(Apis.employeeProfile, body);
//       profile = _parseProfile(res);
//       if (profile != null) {
//         effectiveJoiningDate = await _resolveJoiningDate(profile!);
//         await ApiService.saveEmployee(_profileToEmployeeMap(profile!));
//         _syncDashboard();
//       }
//       return profile != null;
//     } on ApiException catch (e) {
//       errorMessage = e.message;
//       return false;
//     } catch (_) {
//       errorMessage = 'Failed to update profile';
//       return false;
//     } finally {
//       isSaving = false;
//       update();
//     }
//   }

//   void _syncDashboard() {
//     final p = profile;
//     if (p == null) return;
//     if (Get.isRegistered<DashboardController>()) {
//       final dash = Get.find<DashboardController>();
//       dash.employeeName = p.name;
//       dash.employeeInitials = p.initials;
//       dash.update();
//     }
//   }

//   Future<bool> uploadProfileImage(File imageFile) async {
//     isSaving = true;
//     errorMessage = null;
//     update();

//     try {
//       final token = await ApiService.getToken();
//       final request = http.MultipartRequest(
//         'POST',
//         Uri.parse('${Apis.baseUrl}/upload-profile-image'),
//       );

//       request.headers.addAll({
//         'Authorization': 'Bearer $token',
//         'Accept': 'application/json',
//       });
//       request.files.add(
//         await http.MultipartFile.fromPath('profile_image', imageFile.path),
//       );

//       final response = await request.send();
//       await response.stream.bytesToString();

//       if (response.statusCode >= 200 && response.statusCode < 300) {
//         await fetchProfile();
//         return true;
//       }
//       errorMessage = 'Unable to upload image. Please try again.';
//       return false;
//     } catch (e) {
//       errorMessage = 'Something went wrong. Please try again.';
//       return false;
//     } finally {
//       isSaving = false;
//       update();
//     }
//   }

//   Future<bool> updateDateOfBirth(DateTime date) async {
//     final formatted = DateFormat('yyyy-MM-dd').format(date);
//     return updateProfile({'date_of_birth': formatted});
//   }

//   Future<bool> updateName(String name) async {
//     final trimmed = name.trim();
//     if (trimmed.isEmpty) {
//       errorMessage = 'Name cannot be empty';
//       update();
//       return false;
//     }
//     return updateProfile({'name': trimmed});
//   }

//   Future<bool> updatePhone(String phone) async {
//     final trimmed = phone.trim();
//     if (trimmed.isEmpty) {
//       errorMessage = 'Phone number cannot be empty';
//       update();
//       return false;
//     }
//     if (trimmed.length < 10) {
//       errorMessage = 'Enter a valid phone number';
//       update();
//       return false;
//     }
//     return updateProfile({'phone': trimmed});
//   }

//   DateTime? get dateOfBirthPickerInitial {
//     final raw = profile?.dateOfBirth;
//     if (_isValidDate(raw)) {
//       try {
//         return DateTime.parse(raw!);
//       } catch (_) {}
//     }
//     return DateTime(1990, 1, 1);
//   }

//   Future<String?> _resolveJoiningDate(EmployeeProfile p) async {
//     if (_isValidDate(p.joiningDate)) {
//       joiningDateSource = JoiningDateSource.profile;
//       return p.joiningDate;
//     }

//     final firstAttendance = await _fetchEarliestAttendanceDate(p.id);
//     if (_isValidDate(firstAttendance)) {
//       joiningDateSource = JoiningDateSource.firstAttendance;
//       return firstAttendance;
//     }

//     if (_isValidDate(p.createdAt)) {
//       joiningDateSource = JoiningDateSource.enrollment;
//       return p.createdAt;
//     }

//     joiningDateSource = JoiningDateSource.none;
//     return null;
//   }

//   Future<String?> _fetchEarliestAttendanceDate(int employeeId) async {
//     try {
//       final res = await ApiService.get(Apis.attendanceHistory(employeeId));
//       final List<dynamic> rawList;
//       if (res is Map && res['data'] is List) {
//         rawList = res['data'] as List;
//       } else if (res is List) {
//         rawList = res;
//       } else {
//         return null;
//       }

//       DateTime? earliest;
//       for (final item in rawList) {
//         if (item is! Map) continue;
//         final map = Map<String, dynamic>.from(item);
//         final loginAt = map['login_at']?.toString();
//         if (!_isValidDate(loginAt)) continue;
//         try {
//           final dt = DateTime.parse(loginAt!).toLocal();
//           if (earliest == null || dt.isBefore(earliest)) {
//             earliest = dt;
//           }
//         } catch (_) {}
//       }
//       return earliest?.toIso8601String();
//     } catch (_) {
//       return null;
//     }
//   }

//   static bool _isValidDate(String? raw) {
//     if (raw == null || raw.isEmpty || raw == 'null') return false;
//     return true;
//   }

//   Future<File?> pickImageFromCamera() async {
//     final picker = ImagePicker();
//     final image = await picker.pickImage(
//       source: ImageSource.camera,
//       imageQuality: 80,
//     );
//     if (image == null) return null;
//     return File(image.path);
//   }

//   static bool isValidDateValue(String? raw) => _isValidDate(raw);

//   static String formatDate(String? raw) {
//     if (!_isValidDate(raw)) return '—';
//     try {
//       return DateFormat('dd MMM yyyy').format(DateTime.parse(raw!));
//     } catch (_) {
//       return raw!;
//     }
//   }

//   static String? resolveImageUrl(String? path) {
//     if (path == null || path.isEmpty || path == 'null') return null;
//     if (path.startsWith('http://') || path.startsWith('https://')) {
//       return path;
//     }
//     const host = 'https://quicksalary.org';
//     return path.startsWith('/') ? '$host$path' : '$host/$path';
//   }

//   EmployeeProfile? _parseProfile(dynamic res) {
//     if (res is! Map<String, dynamic>) return null;
//     final data = res['data'];
//     if (data is Map<String, dynamic>) {
//       return EmployeeProfile.fromJson(data);
//     }
//     if (res.containsKey('id') || res.containsKey('name')) {
//       return EmployeeProfile.fromJson(res);
//     }
//     return null;
//   }

//   Map<String, dynamic> _profileToEmployeeMap(EmployeeProfile p) {
//     return {
//       'id': p.id,
//       'name': p.name,
//       'email': p.email,
//       'phone': p.phone,
//       'profile_image': p.profileImage,
//       'role': p.roleName,
//     };
//   }
// }
