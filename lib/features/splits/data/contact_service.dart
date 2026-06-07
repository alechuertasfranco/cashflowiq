// lib/features/splits/data/contact_service.dart

import 'package:cashflowiq/core/network/api_client.dart';
import 'package:cashflowiq/core/utils/data_cache.dart';
import 'package:cashflowiq/shared/models/contact.dart';

class ContactService {
  Future<List<Contact>> fetchAll({int limit = 50, int offset = 0}) async {
    // Only cache the default-page request to keep key cardinality low.
    final key = offset == 0 ? 'contacts' : null;

    if (key != null) {
      final cached = DataCache.instance.get<List<Contact>>(key);
      if (cached != null) return cached;
    }

    final List data =
        await ApiClient.getJson('/contacts?limit=$limit&offset=$offset');
    final result = data.map((json) => Contact.fromJson(json)).toList();

    if (key != null) DataCache.instance.set(key, result);
    return result;
  }

  Future<Contact> create(Map<String, dynamic> data) async {
    final json = await ApiClient.postJson('/contacts', body: data);
    DataCache.instance.invalidate('contacts');
    return Contact.fromJson(json);
  }

  Future<Contact> update(int id, Map<String, dynamic> data) async {
    final json = await ApiClient.putJson('/contacts/$id', body: data);
    DataCache.instance.invalidate('contacts');
    return Contact.fromJson(json);
  }

  Future<void> delete(int id) async {
    await ApiClient.delete('/contacts/$id');
    DataCache.instance.invalidate('contacts');
  }
}
