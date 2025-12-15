import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Api {
  // ⚠️ IMPORTANT: Change this based on your setup
  // Android Emulator: "http://10.0.2.2:3000"
  // iOS Simulator: "http://localhost:3000"
  // Physical Device: "http://YOUR_COMPUTER_IP:3000"
  static const String baseUrl = "http://10.27.36.55:3000";

  // Get stored token
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Handle token expiration and redirect to login screen (401/403 errors)
  static Future<Map<String, dynamic>> _handleTokenExpiration(
    http.Response response,
  ) async {
    if (response.statusCode == 401 || response.statusCode == 403) {
      // Clear the expired token
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');

      print('⚠️ Token expired or invalid - cleared from storage');

      return {
        'success': false,
        'tokenExpired': true,
        'message': 'Your session has expired. Please log in again.',
      };
    }

    // Not a token expiration error, return null
    return {};
  }

  // GET request
  static Future<Map<String, dynamic>?> get(String endpoint) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('$baseUrl$endpoint');

      print('GET Request: $url');

      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      print('GET Response Status: ${response.statusCode}');
      print('GET Response Body: ${response.body}');

      // Check for token expiration first
      final tokenExpiredResponse = await _handleTokenExpiration(response);
      if (tokenExpiredResponse.isNotEmpty) {
        return tokenExpiredResponse;
      }

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('GET Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('GET Exception: $e');
      return null;
    }
  }

  // POST request
  static Future<Map<String, dynamic>?> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('$baseUrl$endpoint');

      print('POST Request: $url');
      print('POST Body: ${jsonEncode(body)}');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      print('POST Response Status: ${response.statusCode}');
      print('POST Response Body: ${response.body}');

      // Check for token expiration first
      final tokenExpiredResponse = await _handleTokenExpiration(response);
      if (tokenExpiredResponse.isNotEmpty) {
        return tokenExpiredResponse;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        print('POST Error: ${response.statusCode} - ${response.body}');
        return jsonDecode(response.body); // Return error message
      }
    } catch (e) {
      print('POST Exception: $e');
      return null;
    }
  }

  // PATCH request
  static Future<Map<String, dynamic>?> patch(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('$baseUrl$endpoint');

      print('PATCH Request: $url');
      print('PATCH Body: ${jsonEncode(body)}');

      final response = await http
          .patch(
            url,
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      print('PATCH Response Status: ${response.statusCode}');
      print('PATCH Response Body: ${response.body}');

      // Check for token expiration first
      final tokenExpiredResponse = await _handleTokenExpiration(response);
      if (tokenExpiredResponse.isNotEmpty) {
        return tokenExpiredResponse;
      }

      // Return decoded response for both success and error cases
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else if (response.statusCode >= 400 && response.statusCode < 600) {
        // Return error response so UI can show specific error message
        try {
          return jsonDecode(response.body);
        } catch (e) {
          return {
            'success': false,
            'message': 'Server error: ${response.statusCode}',
          };
        }
      } else {
        print('PATCH Error: ${response.statusCode} - ${response.body}');
        return {'success': false, 'message': 'Unexpected error occurred'};
      }
    } catch (e) {
      print('PATCH Exception: $e');
      return null;
    }
  }

  // DELETE request
  static Future<Map<String, dynamic>?> delete(String endpoint) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('$baseUrl$endpoint');

      print('DELETE Request: $url');

      final response = await http
          .delete(
            url,
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      print('DELETE Response Status: ${response.statusCode}');
      print('DELETE Response Body: ${response.body}');

      // Check for token expiration first
      final tokenExpiredResponse = await _handleTokenExpiration(response);
      if (tokenExpiredResponse.isNotEmpty) {
        return tokenExpiredResponse;
      }

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('DELETE Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('DELETE Exception: $e');
      return null;
    }
  }
}
