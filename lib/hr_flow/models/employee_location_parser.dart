/// Parses GET `/employee-locations` responses for admin display.
class EmployeeLocationParser {
  EmployeeLocationParser._();

  /// True when API returned org employee list instead of location rows.
  static bool isEmployeeListResponse(Map<String, dynamic> res) {
    if (res['total_employees'] != null) return true;
    final data = res['data'];
    if (data is! List || data.isEmpty) return false;
    final first = data.first;
    if (first is! Map) return false;
    final map = Map<String, dynamic>.from(first);
    return map.containsKey('name') &&
        map.containsKey('email') &&
        !map.containsKey('latitude');
  }

  static List<Map<String, dynamic>> parse(
    dynamic res, {
    required int employeeId,
  }) {
    if (res is! Map) return [];

    final root = Map<String, dynamic>.from(res);
    if (isEmployeeListResponse(root)) {
      return [];
    }

    final data = root['data'];
    final rawItems = <Map<String, dynamic>>[];

    if (data is List) {
      for (final item in data) {
        if (item is! Map) continue;
        final normalized = _normalizeLocationRow(
          Map<String, dynamic>.from(item),
          employeeId,
        );
        if (normalized != null) rawItems.add(normalized);
      }
    } else if (data is Map) {
      final normalized = _normalizeLocationRow(
        Map<String, dynamic>.from(data),
        employeeId,
      );
      if (normalized != null) rawItems.add(normalized);
    } else if (root.containsKey('latitude')) {
      final normalized = _normalizeLocationRow(root, employeeId);
      if (normalized != null) rawItems.add(normalized);
    }

    rawItems.sort(_compareLatestFirst);
    return rawItems;
  }

  static Map<String, dynamic>? _normalizeLocationRow(
    Map<String, dynamic> item,
    int employeeId,
  ) {
    Map<String, dynamic>? row;

    if (_hasCoordinates(item)) {
      row = item;
    } else {
      for (final key in const [
        'latest_location',
        'employee_location',
        'location',
        'current_location',
      ]) {
        final nested = item[key];
        if (nested is Map && _hasCoordinates(Map<String, dynamic>.from(nested))) {
          row = Map<String, dynamic>.from(nested);
          break;
        }
      }
    }

    if (row == null) return null;

    final recordEmployeeId = _readInt(
      row['employee_id'] ?? item['employee_id'] ?? item['id'],
    );
    if (recordEmployeeId != null && recordEmployeeId != employeeId) {
      return null;
    }

    return row;
  }

  static bool _hasCoordinates(Map<String, dynamic> item) {
    return _readDouble(item['latitude']) != null &&
        _readDouble(item['longitude']) != null;
  }

  static double? _readDouble(dynamic raw) {
    if (raw == null) return null;
    return double.tryParse(raw.toString());
  }

  static int? _readInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  static int _compareLatestFirst(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    final byTime = locationTime(b).compareTo(locationTime(a));
    if (byTime != 0) return byTime;
    final idA = _readInt(a['id']) ?? 0;
    final idB = _readInt(b['id']) ?? 0;
    return idB.compareTo(idA);
  }

  static DateTime locationTime(Map<String, dynamic> item) {
    final raw =
        item['created_at']?.toString() ??
        item['recorded_at']?.toString() ??
        item['updated_at']?.toString() ??
        '';
    return DateTime.tryParse(raw)?.toLocal() ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }
}
