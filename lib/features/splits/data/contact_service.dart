// lib/features/splits/data/contact_service.dart

import 'package:cashflowiq/core/network/api_client.dart';
import 'package:cashflowiq/shared/models/contact.dart';

class ContactService {
  Future<List<Contact>> fetchAll({int limit = 50, int offset = 0}) async {
    final List data =
        await ApiClient.getJson('/contacts?limit=$limit&offset=$offset');
    return data.map((json) => Contact.fromJson(json)).toList();
  }

  Future<Contact> create(Map<String, dynamic> data) async {
    final json = await ApiClient.postJson('/contacts', body: data);
    return Contact.fromJson(json);
  }

  Future<Contact> update(int id, Map<String, dynamic> data) async {
    final json = await ApiClient.putJson('/contacts/$id', body: data);
    return Contact.fromJson(json);
  }

  Future<void> delete(int id) async {
    await ApiClient.delete('/contacts/$id');
  }
}
