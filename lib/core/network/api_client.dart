// lib/core/network/api_client.dart

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

  // 📥 GET
  static Future<http.Response> get(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse("$baseUrl$endpoint"), headers: headers);
      _handleError(response);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // ➕ POST
  static Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse("$baseUrl$endpoint"),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );

      _handleError(response);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // ✏️ PUT
  static Future<http.Response> put(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse("$baseUrl$endpoint"),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );

      _handleError(response);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // ❌ DELETE
  static Future<http.Response> delete(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(Uri.parse("$baseUrl$endpoint"), headers: headers);
      _handleError(response);

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // 🔄 GET JSON
  static Future<dynamic> getJson(String endpoint) async {
    try {
      final response = await get(endpoint);
      return jsonDecode(response.body);
    } catch (e) {
      rethrow;
    }
  }

  // 🔄 POST JSON
  static Future<dynamic> postJson(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final response = await post(endpoint, body: body);
      return jsonDecode(response.body);
    } catch (e) {
      rethrow;
    }
  }

  // 🔄 PUT JSON
  static Future<dynamic> putJson(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final response = await put(endpoint, body: body);
      return jsonDecode(response.body);
    } catch (e) {
      rethrow;
    }
  }

  static void _handleError(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception("API Error ${response.statusCode}: ${response.body}");
  }
}
