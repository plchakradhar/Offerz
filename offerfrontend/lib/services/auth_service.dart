import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_constants.dart';

class AuthService {
  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _userNameKey = 'userName';
  static const String _userMobileKey = 'userMobile';

  // ─── Helper ───────────────────────────────────────────────────────────────

  /// Maps raw HTTP/socket exceptions to user-friendly messages.
  static String _friendlyError(dynamic e) {
    if (e is TimeoutException) return 'ERROR: Server is taking too long. Make sure it is running.';
    final msg = e.toString().toLowerCase();
    if (msg.contains('socket') || msg.contains('connection') || msg.contains('network')) {
      return kIsWeb
          ? 'ERROR: Cannot reach server. Make sure the backend is running and CORS is enabled.'
          : 'ERROR: Cannot reach server. Check USB cable & run: adb reverse tcp:8080 tcp:8080';
    }
    return 'ERROR: ${e.toString()}';
  }

  // ─── OTP / Login ──────────────────────────────────────────────────────────

  Future<String> getOtp(String mobile) async {
    try {
      final response = await http
          .post(Uri.parse('${ApiConstants.baseUrl}/auth/login/getotp?mobile=$mobile'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) return response.body;   // "OTP: 1234"
      if (response.statusCode == 404) return 'ERROR: ${response.body}';
      if (response.statusCode == 403) return 'ERROR: Server rejected request (403). Please restart the backend server.';
      return 'ERROR: Server error (${response.statusCode}): ${response.body}';
    } catch (e) {
      return _friendlyError(e);
    }
  }

  Future<Map<String, dynamic>> verifyLogin(String mobile, String otp) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}/auth/login/verify'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'mobileNumber': mobile, 'otp': otp}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          await _saveSession(mobile, data['fullName'] ?? 'User');
          return {'success': true, 'fullName': data['fullName'] ?? 'User'};
        }
      }
      final msg = response.statusCode == 403
          ? 'Server rejected request (403). Please restart the backend.'
          : (response.body.isNotEmpty ? response.body : 'Invalid OTP');
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': _friendlyError(e).replaceFirst('ERROR: ', '')};
    }
  }

  // ─── Signup ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> signup(String name, String email, String mobile) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}/auth/signup'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'fullName': name, 'email': email, 'mobileNumber': mobile}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return {'success': true, 'otpMessage': response.body}; // "OTP: 1234"
      }

      String errorText;
      if (response.statusCode == 403) {
        errorText = 'Server rejected the request (403 Forbidden). Please restart your Spring Boot backend.';
      } else if (response.statusCode == 400) {
        errorText = response.body.isNotEmpty ? response.body : 'Signup failed. Please check your details.';
      } else {
        errorText = 'Server error (${response.statusCode}). Please try again.';
      }
      return {'success': false, 'error': errorText};
    } on TimeoutException {
      return {'success': false, 'error': 'Server timed out. Make sure your Spring Boot backend is running.'};
    } catch (e) {
      return {'success': false, 'error': 'Connection error: ${e.toString()}'};
    }
  }

  Future<bool> verifySignup(String mobile, String otp) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}/auth/verify-signup'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'mobileNumber': mobile, 'otp': otp}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          await _saveSession(mobile, '');
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ─── Session ──────────────────────────────────────────────────────────────

  Future<void> _saveSession(String mobile, String fullName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_userMobileKey, mobile);
    await prefs.setString(_userNameKey, fullName);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  static Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey) ?? '';
  }

  static Future<String> getUserMobile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userMobileKey) ?? '';
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}