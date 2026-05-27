import 'dart:convert';

import 'package:employee_app/apis.dart';
import 'package:employee_app/employee_flow/location/location_snapshot.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Background + foreground — sirf existing APIs.
/// lastAttempt / lastError SharedPreferences me (UI nahi) — debug ke liye.
class LocationSyncTask {
  LocationSyncTask._();

  static const Duration refreshInterval = Duration(minutes: 10);
  static const String trackingEnabledKey = 'location_tracking_enabled';
  static const String lastSentKey = 'last_location_sent_ms';
  static const String lastAttemptKey = 'last_location_attempt_ms';
  static const String lastErrorKey = 'last_location_error';
  static const String lastLatKey = 'last_location_lat';
  static const String lastLngKey = 'last_location_lng';
  static const String tokenKey = 'auth_token';
  static const String orgIdKey = 'organization_id';
  static const String employeeKey = 'auth_employee';

  static Future<void> setTrackingEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(trackingEnabledKey, enabled);
    if (!enabled) {
      await prefs.remove(lastSentKey);
      await prefs.remove(lastAttemptKey);
      await prefs.remove(lastErrorKey);
      await prefs.remove(lastLatKey);
      await prefs.remove(lastLngKey);
    }
  }

  static Future<LocationSnapshot> readSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final sentMs = prefs.getInt(lastSentKey);
    final attemptMs = prefs.getInt(lastAttemptKey);
    return LocationSnapshot(
      trackingEnabled: prefs.getBool(trackingEnabledKey) ?? false,
      latitude: prefs.getDouble(lastLatKey),
      longitude: prefs.getDouble(lastLngKey),
      lastSentAt: sentMs != null
          ? DateTime.fromMillisecondsSinceEpoch(sentMs).toLocal()
          : null,
      lastAttemptAt: attemptMs != null
          ? DateTime.fromMillisecondsSinceEpoch(attemptMs).toLocal()
          : null,
      lastError: prefs.getString(lastErrorKey),
    );
  }

  /// Console debug — UI me nahi dikhega.
  static Future<void> logDebugState() async {
    final s = await readSnapshot();
    debugPrint(
      'LocationSync DEBUG => '
      'tracking=${s.trackingEnabled}, '
      'lastAttempt=${s.lastAttemptAt}, '
      'lastSent=${s.lastSentAt}, '
      'coords=${s.coordinatesText}, '
      'error=${s.lastError ?? "none"}',
    );
  }

  static Future<bool> isTrackingEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(trackingEnabledKey) ?? false;
  }

  static Future<void> run({bool force = false}) async {
    if (!await isTrackingEnabled()) return;

    final prefs = await SharedPreferences.getInstance();

    if (!force) {
      final lastMs = prefs.getInt(lastSentKey);
      if (lastMs != null) {
        final last = DateTime.fromMillisecondsSinceEpoch(lastMs);
        if (DateTime.now().difference(last) < refreshInterval) {
          debugPrint('LocationSync: skipped — within 10 min interval');
          return;
        }
      }
    }

    await _markAttempt(prefs);

    final token = prefs.getString(tokenKey);
    if (token == null || token.isEmpty) {
      await _markError(prefs, 'No auth token');
      return;
    }

    final employeeId = _readEmployeeId(prefs);
    if (employeeId == null) {
      await _markError(prefs, 'Employee ID missing');
      return;
    }

    if (!await _isCheckedIn(token, employeeId)) {
      await _markError(prefs, 'Not checked in');
      return;
    }

    final position = await _getPosition();
    if (position == null) {
      await _markError(prefs, 'GPS unavailable or permission denied');
      return;
    }

    final orgId = int.tryParse(prefs.getString(orgIdKey) ?? '0') ?? 0;
    final postError = await _sendLocation(
      token: token,
      organizationId: orgId,
      employeeId: employeeId,
      latitude: position.latitude,
      longitude: position.longitude,
    );

    if (postError == null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(lastSentKey, now);
      await prefs.setDouble(lastLatKey, position.latitude);
      await prefs.setDouble(lastLngKey, position.longitude);
      await prefs.remove(lastErrorKey);
      debugPrint(
        'LocationSync: OK ${position.latitude}, ${position.longitude}',
      );
      await logDebugState();
      return;
    }

    await _markError(prefs, postError);
  }

  static Future<void> _markAttempt(SharedPreferences prefs) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(lastAttemptKey, now);
    debugPrint(
      'LocationSync: attempt at ${DateTime.fromMillisecondsSinceEpoch(now).toLocal()}',
    );
  }

  static Future<void> _markError(SharedPreferences prefs, String message) async {
    await prefs.setString(lastErrorKey, message);
    debugPrint('LocationSync: FAILED — $message');
    await logDebugState();
  }

  static int? _readEmployeeId(SharedPreferences prefs) {
    final raw = prefs.getString(employeeKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      if (map is Map<String, dynamic>) {
        final id = map['id'] ?? map['employee_id'];
        if (id is int) return id;
        if (id is String) return int.tryParse(id);
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> _isCheckedIn(String token, int employeeId) async {
    try {
      final url = Uri.parse(
        '${Apis.baseUrl}${Apis.attendanceStatus(employeeId)}',
      );
      final res = await http
          .get(
            url,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode < 200 || res.statusCode >= 300) {
        debugPrint('LocationSync: status HTTP ${res.statusCode}');
        return false;
      }

      final body = jsonDecode(res.body);
      if (body is! Map) return false;

      final status = (body['status'] ?? '').toString().toLowerCase();
      const checkedIn = {'checked_in', 'logged_in', 'present'};
      return checkedIn.contains(status);
    } catch (e) {
      debugPrint('LocationSync: status error — $e');
      return false;
    }
  }

  static Future<Position?> _getPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 25),
        ),
      );
    } catch (e) {
      debugPrint('LocationSync: GPS error — $e');
      return null;
    }
  }

  /// Returns null on success, error message on failure.
  static Future<String?> _sendLocation({
    required String token,
    required int organizationId,
    required int employeeId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = Uri.parse('${Apis.baseUrl}/employee-locations');
      final res = await http
          .post(
            url,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'organization_id': organizationId,
              'employee_id': employeeId,
              'latitude': latitude,
              'longitude': longitude,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode >= 200 && res.statusCode < 300) return null;

      final body = res.body.length > 120
          ? '${res.body.substring(0, 120)}...'
          : res.body;
      return 'POST failed HTTP ${res.statusCode}: $body';
    } catch (e) {
      return 'POST error: $e';
    }
  }
}
