import 'package:employee_app/api_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the separate Face Recognition app with auth from this session.
///
/// Deep link format:
/// `facerecognition://launch?token=JWT&employee_id=123&action=checkin`
class FaceRecognitionLauncher {
  FaceRecognitionLauncher._();

  static const String scheme = 'facerecognition';
  static const String host = 'launch';

  static const String actionCheckIn = 'checkin';
  static const String actionCheckOut = 'checkout';
  static const String actionRegisterProfile = 'register_profile';

  static Future<bool> launch({required String action}) async {
    final token = await ApiService.getToken();
    final employeeId = await ApiService.getEmployeeId();

    if (token == null || token.isEmpty) {
      _showError('Session expired', 'Please login again.');
      return false;
    }
    if (employeeId == null) {
      _showError('Employee not found', 'Please login again.');
      return false;
    }

    final uri = Uri(
      scheme: scheme,
      host: host,
      queryParameters: {
        'token': token,
        'employee_id': employeeId.toString(),
        'action': action,
      },
    );

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      _showError(
        'Face Recognition app not found',
        'Install the Face Recognition app and try again.',
      );
    }
    return launched;
  }

  static Future<bool> launchForAttendance({required bool isCheckedIn}) {
    return launch(
      action: isCheckedIn ? actionCheckOut : actionCheckIn,
    );
  }

  static Future<bool> launchForProfileRegistration() {
    return launch(action: actionRegisterProfile);
  }

  static void _showError(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
