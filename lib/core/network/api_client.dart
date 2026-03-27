import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiClient {
  static final String baseUrl = dotenv.env['API_BASE_URL'] ?? "http://10.0.2.2:8000";

  static Future<Map<String, String>> _getHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Usuario no autenticado");
    final token = await user.getIdToken(true);
    return {"Authorization": "Bearer $token", "Content-Type": "application/json"};
  }

  static Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    final headers = await _getHeaders();
    final response = await http.post(Uri.parse("$baseUrl$endpoint"), headers: headers, body: body != null ? jsonEncode(body) : null);
    _handleError(response);
    return response;
  }

  static Future<http.Response> get(String endpoint) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse("$baseUrl$endpoint"), headers: headers);
    _handleError(response);
    return response;
  }

  static void _handleError(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception("API Error ${response.statusCode}: ${response.body}");
  }
}
