import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_constants.dart';

class ProfileService {
  static const String _userAvatarKey = 'userAvatar';
  static const String _userEmailKey = 'userEmail';

  static Future<Map<String, dynamic>> getProfile(String mobile) async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/api/user/profile?mobileNumber=$mobile"),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Cache locally for offline display
        final prefs = await SharedPreferences.getInstance();
        if (data['avatarUrl'] != null && data['avatarUrl'].toString().isNotEmpty) {
          await prefs.setString(_userAvatarKey, data['avatarUrl']);
        }
        if (data['fullName'] != null) {
          await prefs.setString('userName', data['fullName']);
        }
        if (data['email'] != null) {
          await prefs.setString(_userEmailKey, data['email']);
        }
        return {"success": true, "data": data};
      }
      return {"success": false, "message": "Server error: ${response.statusCode}"};
    } on TimeoutException {
      return {"success": false, "message": "Connection timed out"};
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  static Future<Map<String, dynamic>> updateProfile(
      String mobile, String fullName, String email, String avatarUrl) async {
    try {
      final response = await http.put(
        Uri.parse("${ApiConstants.baseUrl}/api/user/profile?mobileNumber=$mobile"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "fullName": fullName,
          "email": email,
          "avatarUrl": avatarUrl
        }),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userName', fullName);
        await prefs.setString(_userAvatarKey, avatarUrl);
        await prefs.setString(_userEmailKey, email);
        return {"success": true};
      }
      // Parse error message from backend
      try {
        final err = jsonDecode(response.body);
        return {"success": false, "message": err['message'] ?? "Update failed"};
      } catch (_) {
        return {"success": false, "message": response.body};
      }
    } on TimeoutException {
      return {"success": false, "message": "Connection timed out"};
    } catch (e) {
      return {"success": false, "message": "Connection error"};
    }
  }

  static Future<Map<String, dynamic>> addAddress(
      String mobile, Map<String, String> addressData) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConstants.baseUrl}/api/user/address?mobileNumber=$mobile"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(addressData),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return {"success": true};
      }
      try {
        final err = jsonDecode(response.body);
        return {"success": false, "message": err['message'] ?? "Failed to add address"};
      } catch (_) {
        return {"success": false, "message": response.body};
      }
    } on TimeoutException {
      return {"success": false, "message": "Connection timed out"};
    } catch (e) {
      return {"success": false, "message": "Connection error"};
    }
  }

  static Future<String> getAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userAvatarKey) ?? "";
  }

  static Future<String> getCachedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey) ?? "";
  }
}
