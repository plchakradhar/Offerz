import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_constants.dart';

class AdminService {
  static String get _base => '${ApiConstants.baseUrl}/api/business';
  static const String _adminToken = 'ADMIN_TOKEN_2006';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-Admin-Token': _adminToken,
      };

  /// Admin login with hardcoded credentials.
  static Future<Map<String, dynamic>> login(String phone, String otp) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_base/admin/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'phone': phone, 'otp': otp}),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return {'success': true};
      }
      try {
        final err = jsonDecode(response.body);
        return {'success': false, 'message': err['message'] ?? 'Login failed'};
      } catch (_) {
        return {'success': false, 'message': 'Invalid credentials'};
      }
    } on TimeoutException {
      return {'success': false, 'message': 'Connection timed out'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// Get all registered users.
  static Future<List<dynamic>> getAllUsers() async {
    try {
      final response = await http
          .get(Uri.parse('$_base/admin/users'), headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return jsonDecode(response.body) as List;
    } catch (_) {}
    return [];
  }

  /// Get all business registration requests.
  static Future<List<dynamic>> getAllRequests() async {
    try {
      final response = await http
          .get(Uri.parse('$_base/admin/requests'), headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return jsonDecode(response.body) as List;
    } catch (_) {}
    return [];
  }

  /// Approve or reject a business request.
  static Future<Map<String, dynamic>> actionRequest(
      int id, String status, String remark) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_base/admin/action/$id'),
            headers: _headers,
            body: jsonEncode({'status': status, 'remark': remark}),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return {'success': true};
      try {
        final err = jsonDecode(response.body);
        return {'success': false, 'message': err['message'] ?? 'Action failed'};
      } catch (_) {
        return {'success': false, 'message': response.body};
      }
    } on TimeoutException {
      return {'success': false, 'message': 'Connection timed out'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
}
