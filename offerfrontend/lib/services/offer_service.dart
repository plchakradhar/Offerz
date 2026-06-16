import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_constants.dart';

class OfferService {
  static String get _base => '${ApiConstants.baseUrl}/api/offers';

  static Future<Map<String, dynamic>> createOffer(Map<String, dynamic> offerData) async {
    try {
      final response = await http
          .post(
            Uri.parse(_base),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(offerData),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'message': 'Failed to create offer: ${response.statusCode} - ${response.body}'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateOffer(int id, Map<String, dynamic> offerData) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_base/$id'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(offerData),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'message': 'Failed to update offer'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteOffer(int id) async {
    try {
      final response = await http
          .delete(Uri.parse('$_base/$id'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'message': 'Failed to delete offer'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<List<dynamic>> getOffersByBusiness(String mobile) async {
    try {
      final response = await http
          .get(Uri.parse('$_base/business/$mobile'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getOffersByLocation(String city) async {
    try {
      final response = await http
          .get(Uri.parse('$_base/location/$city'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getAllOffers() async {
    try {
      final response = await http
          .get(Uri.parse(_base))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
