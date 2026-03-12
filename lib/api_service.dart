import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'apis.dart';

class ApiService {
  //  SharedPrefs keys
  static const String _tokenKey = 'auth_token';
  static const String _isLoginKey = 'is_login';
  static const String _employeeKey = 'auth_employee';
  static const Duration _requestTimeout = Duration(seconds: 40);

  //  Token helpers
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setBool(_isLoginKey, true);
  }

  static Future<void> saveEmployee(Map<String, dynamic> employee) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_employeeKey, jsonEncode(employee));
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoginKey) ?? false;
  }

  static Future<Map<String, dynamic>?> getEmployee() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_employeeKey);
    if (raw == null || raw.isEmpty) {
      return _employeeFromToken();
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return extractEmployee(decoded) ?? decoded;
      }
    } catch (_) {}

    return _employeeFromToken();
  }

  static Future<int?> getEmployeeId() async {
    final employee = await getEmployee();
    return extractEmployeeId(employee) ?? await _employeeIdFromToken();
  }

  static int? extractEmployeeId(Map<String, dynamic>? employee) {
    if (employee == null) return null;

    final dynamic rawId =
        employee['employee_id'] ??
        employee['employeeId'] ??
        employee['id'] ??
        employee['user_id'] ??
        employee['userId'];

    if (rawId is int) return rawId;
    if (rawId is String) return int.tryParse(rawId);
    return null;
  }

  static Map<String, dynamic>? extractEmployee(dynamic source) {
    if (source is! Map) return null;

    final normalized = Map<String, dynamic>.from(source);
    if (extractEmployeeId(normalized) != null) {
      return normalized;
    }

    for (final key in const ['employee', 'user', 'data']) {
      final nested = normalized[key];
      final extracted = extractEmployee(nested);
      if (extracted != null) {
        return extracted;
      }
    }

    return null;
  }

  static Future<int?> _employeeIdFromToken() async {
    final employee = await _employeeFromToken();
    return extractEmployeeId(employee);
  }

  static Future<Map<String, dynamic>?> _employeeFromToken() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return null;

    final claims = _decodeJwtPayload(token);
    if (claims == null) return null;

    final dynamic rawId =
        claims['employee_id'] ??
        claims['employeeId'] ??
        claims['id'] ??
        claims['sub'] ??
        claims['user_id'] ??
        claims['userId'];

    final int? id = rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? '');
    if (id == null) return null;

    return {
      'id': id,
      if (claims['name'] != null) 'name': claims['name'],
      if (claims['email'] != null) 'email': claims['email'],
    };
  }

  static Map<String, dynamic>? _decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length < 2) return null;

    try {
      final normalized = base64.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}

    return null;
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_isLoginKey);
    await prefs.remove(_employeeKey);
  }

  //  Headers builder
  static Future<Map<String, String>> _buildHeaders({
    bool withAuth = true,
  }) async {
    final token = withAuth ? await getToken() : null;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // Auth calls

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('${Apis.baseUrl}${Apis.login}'); // ← from apis.dart
    final headers = await _buildHeaders(withAuth: false);
    final body = jsonEncode({'email': email, 'password': password});

    print('[API] POST $url');
    try {
      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(_requestTimeout);

      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(
        statusCode: 408,
        message: 'Request timed out. Please try again.',
      );
    }
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final url = Uri.parse('${Apis.baseUrl}${Apis.register}');
    final headers = await _buildHeaders(withAuth: false);
    final body = jsonEncode({
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });

    print('[API] POST $url');
    try {
      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(_requestTimeout);

      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(
        statusCode: 408,
        message: 'Request timed out. Please try again.',
      );
    }
  }

  // Generic CRUD helpers

  static Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('${Apis.baseUrl}$endpoint');
    final headers = await _buildHeaders();
    try {
      final response = await http
          .get(url, headers: headers)
          .timeout(_requestTimeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(
        statusCode: 408,
        message: 'Request timed out. Please try again.',
      );
    }
  }

  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('${Apis.baseUrl}$endpoint');
    final headers = await _buildHeaders();
    try {
      final response = await http
          .post(url, headers: headers, body: jsonEncode(body))
          .timeout(_requestTimeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(
        statusCode: 408,
        message: 'Request timed out. Please try again.',
      );
    }
  }

  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${Apis.baseUrl}$endpoint');
    final headers = await _buildHeaders();
    try {
      final response = await http
          .put(url, headers: headers, body: jsonEncode(body))
          .timeout(_requestTimeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(
        statusCode: 408,
        message: 'Request timed out. Please try again.',
      );
    }
  }

  static Future<dynamic> delete(String endpoint) async {
    final url = Uri.parse('${Apis.baseUrl}$endpoint');
    final headers = await _buildHeaders();
    try {
      final response = await http
          .delete(url, headers: headers)
          .timeout(_requestTimeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(
        statusCode: 408,
        message: 'Request timed out. Please try again.',
      );
    }
  }

  static Future<dynamic> postMultipart(
    String endpoint, {
    required Map<String, String> fields,
    String? filePath, // optional — sirf photo ho to pass karo
    String fileField =
        'photo', // API ka field name — apne backend se match karo
  }) async {
    final url = Uri.parse('${Apis.baseUrl}$endpoint');
    final token = await getToken();

    print('[API] MULTIPART POST $url');
    print('[API] Fields: $fields');
    if (filePath != null) print('[API] File: $filePath');

    try {
      final request = http.MultipartRequest('POST', url)
        ..headers['Accept'] = 'application/json'
        ..fields.addAll(fields);

      // Auth token add karo
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Photo file attach karo agar path diya ho
      if (filePath != null && filePath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath(fileField, filePath),
        );
      }

      final streamed = await request.send().timeout(_requestTimeout);
      final response = await http.Response.fromStream(streamed);

      print('[API] Status: ${response.statusCode}');
      print('[API] Body:   ${response.body}');

      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(
        statusCode: 408,
        message: 'Request timed out. Please try again.',
      );
    } catch (e) {
      print('[API] Multipart error: $e');
      rethrow;
    }
  }

  //  error handler
  static Map<String, dynamic> _handleResponse(http.Response response) {
    print('API Status: ${response.statusCode}');
    print('API Body:   ${response.body}');

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    if (response.statusCode == 401) {
      throw ApiException(
        statusCode: 401,
        message: decoded['message'] ?? 'Session expired.',
      );
    }

    if (response.statusCode == 422) {
      final errors = decoded['errors'] as Map<String, dynamic>?;
      final firstError = errors?.values.first;
      final message = firstError is List
          ? firstError.first
          : decoded['message'];
      throw ApiException(
        statusCode: 422,
        message: message ?? 'Validation error',
      );
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: decoded['message'] ?? 'Something went wrong',
    );
  }
}

// Custom Exception
class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
