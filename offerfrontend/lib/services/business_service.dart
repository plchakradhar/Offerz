import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_constants.dart';

class BusinessService {
  static String get _base => '${ApiConstants.baseUrl}/api/business';

  /// Submit a business registration.
  static Future<Map<String, dynamic>> submitRegistration({
    required String mobileNumber,
    required String legalName,
    required String documentType,
    required String documentPhotoBase64,
    required String businessName,
    required String businessType,
    required String gstNumber,
    required String panNumber,
    required String yearsInBusiness,
    required String businessDoor,
    required String businessStreet,
    required String businessCity,
    required String businessState,
    required String businessPincode,
    required String shopPhotosBase64, // pipe-separated base64 strings
  }) async {
    try {
      final body = jsonEncode({
        'mobileNumber': mobileNumber,
        'legalName': legalName,
        'documentType': documentType,
        'documentPhotoBase64': documentPhotoBase64,
        'businessName': businessName,
        'businessType': businessType,
        'gstNumber': gstNumber,
        'panNumber': panNumber,
        'yearsInBusiness': yearsInBusiness,
        'businessDoor': businessDoor,
        'businessStreet': businessStreet,
        'businessCity': businessCity,
        'businessState': businessState,
        'businessPincode': businessPincode,
        'shopPhotosBase64': shopPhotosBase64,
      });

      final response = await http
          .post(
            Uri.parse('$_base/register'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return {'success': true};
      }
      try {
        final err = jsonDecode(response.body);
        return {'success': false, 'message': err['message'] ?? 'Submission failed'};
      } catch (_) {
        return {'success': false, 'message': response.body};
      }
    } on TimeoutException {
      return {'success': false, 'message': 'Connection timed out'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// Get current registration status for a mobile number.
  static Future<Map<String, dynamic>> getStatus(String mobile) async {
    try {
      final response = await http
          .get(Uri.parse('$_base/status?mobile=$mobile'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'data': null};
    } catch (_) {
      return {'success': false, 'data': null};
    }
  }

  /// Update business subscription plan.
  static Future<Map<String, dynamic>> updateSubscription(String mobile, String plan) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_base/subscription?mobile=$mobile'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'plan': plan}),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'message': 'Failed to update subscription'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
