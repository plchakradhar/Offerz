import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static Future<String> getCurrentCity() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return "Location off";

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return "Permission denied";
      }
      if (permission == LocationPermission.deniedForever) return "Permission denied forever";

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude,
        );
        if (placemarks.isNotEmpty) {
          return placemarks.first.locality ?? placemarks.first.administrativeArea ?? "Unknown City";
        }
      } catch (_) {
        return "Demo Location";
      }
      return "Demo Location";
    } catch (_) {
      return "Demo Location";
    }
  }

  /// Fetches city/state from an Indian pincode using India Post API.
  /// Falls back to zippopotam.us if India Post fails.
  static Future<Map<String, String>?> fetchDetailsFromZipcode(String zipcode) async {
    // Primary: India Post API (most reliable for Indian pincodes)
    try {
      final response = await http
          .get(Uri.parse("https://api.postalpincode.in/pincode/$zipcode"))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          final postOffices = data[0]['PostOffice'];
          if (postOffices != null && postOffices.isNotEmpty) {
            final po = postOffices[0];
            return {
              "city": po['District'] ?? po['Name'] ?? "",
              "state": po['State'] ?? "",
            };
          }
        }
      }
    } catch (_) {
      // Fall through to backup
    }

    // Backup: zippopotam.us
    try {
      final response = await http
          .get(Uri.parse("https://api.zippopotam.us/in/$zipcode"))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['places'] != null && data['places'].isNotEmpty) {
          final place = data['places'][0];
          return {
            "city": place['place name'] ?? "",
            "state": place['state'] ?? "",
          };
        }
      }
    } catch (_) {}

    return null;
  }
}