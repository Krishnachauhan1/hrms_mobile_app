import 'dart:convert';

import 'package:employee_app/apis.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Admin: GET `/employee-locations` → SharedPreferences cache → UI read.
class AdminLocationSync {
  AdminLocationSync._();

  static const String employeeLocations = '/employee-locations';
  static const String cacheKey = 'admin_location_cache';
  static const String cacheTimeKey = 'admin_location_cache_time';
  static const String tokenKey = 'auth_token';

  static DateTime? _parseTime(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString())?.toLocal();
  }

  /// Fetch all location rows from server and save grouped by employee_id.
  static Future<bool> run() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(tokenKey);
    if (token == null || token.isEmpty) {
      debugPrint('AdminLocationSync: no auth token — login first');
      return false;
    }

    try {
      final uri = Uri.parse('${Apis.baseUrl}$employeeLocations');
      debugPrint('AdminLocationSync: GET $uri');

      final res = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 45));

      debugPrint('AdminLocationSync: HTTP ${res.statusCode}');
      debugPrint('AdminLocationSync: body=${res.body}');

      if (res.statusCode < 200 || res.statusCode >= 300) return false;

      final body = jsonDecode(res.body);
      if (body is! Map) return false;

      final ok = body['status'] == true || body['success'] == true;
      if (!ok) {
        debugPrint('AdminLocationSync: API status not OK — $body');
        return false;
      }

      final raw = body['data'];
      if (raw is! List) {
        debugPrint('AdminLocationSync: data is not a list — $raw');
        return false;
      }

      final grouped = <String, List<Map<String, dynamic>>>{};

      for (final item in raw) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);

        if (map['latitude'] == null || map['longitude'] == null) continue;

        final itemEmpId =
            map['employee_id'] ??
            (map['employee'] is Map ? map['employee']['id'] : null);
        final id = itemEmpId is int
            ? itemEmpId
            : int.tryParse(itemEmpId?.toString() ?? '');
        if (id == null) continue;

        grouped.putIfAbsent('$id', () => []).add(map);
      }

      for (final list in grouped.values) {
        list.sort((a, b) {
          final ta = _parseTime(a['created_at'] ?? a['updated_at']) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final tb = _parseTime(b['created_at'] ?? b['updated_at']) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return tb.compareTo(ta);
        });
      }

      await prefs.setString(cacheKey, jsonEncode(grouped));
      await prefs.setInt(cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
      debugPrint(
        'AdminLocationSync: saved ${raw.length} rows, '
        '${grouped.length} employees',
      );
      return true;
    } catch (e, st) {
      debugPrint('AdminLocationSync error: $e\n$st');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> latestForEmployee(int employeeId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(cacheKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final list = decoded['$employeeId'];
      if (list is List && list.isNotEmpty && list.first is Map) {
        return Map<String, dynamic>.from(list.first as Map);
      }
    } catch (_) {}
    return null;
  }

  static Future<DateTime?> cacheUpdatedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(cacheTimeKey);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
  }
}
