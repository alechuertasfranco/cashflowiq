// lib/features/profile/data/category_service.dart

import 'package:cashflowiq/core/network/api_client.dart';
import 'package:cashflowiq/core/utils/data_cache.dart';
import 'package:cashflowiq/shared/models/category.dart';

class CategoryService {
  Future<List<Category>> getCategories({CategoryType? type}) async {
    final typeKey = type != null ? type.toApi() : 'all';
    final key = 'categories_$typeKey';
    final cached = DataCache.instance.get<List<Category>>(key);
    if (cached != null) return cached;

    final query = type != null ? "?type=${type.toApi()}" : "";
    final response = await ApiClient.getJson("/categories$query");

    if (response is! List) throw Exception("Invalid response");

    final result = response.map<Category>((e) => Category.fromJson(e)).toList();
    DataCache.instance.set(key, result);
    return result;
  }

  Future<List<Category>> getCategoriesWithChildren({CategoryType? type}) async {
    final typeKey = type != null ? type.toApi() : 'all';
    final key = 'categories_with_children_$typeKey';
    final cached = DataCache.instance.get<List<Category>>(key);
    if (cached != null) return cached;

    final query = type != null ? "?type=${type.toApi()}" : "";
    final response = await ApiClient.getJson("/categories/with-children$query");

    if (response is! List) throw Exception("Invalid response");

    final result = response.map<Category>((e) => Category.fromJson(e)).toList();
    DataCache.instance.set(key, result);
    return result;
  }

  Future<Category> createCategory(Category category) async {
    final response = await ApiClient.postJson("/categories", body: category.toCreateJson());
    DataCache.instance.invalidatePrefix('categories');
    return Category.fromJson(response);
  }

  Future<Category> updateCategory(Category category) async {
    final response = await ApiClient.putJson("/categories/${category.id}", body: category.toUpdateJson());
    DataCache.instance.invalidatePrefix('categories');
    return Category.fromJson(response);
  }

  Future<void> deleteCategory(String id) async {
    await ApiClient.delete("/categories/$id");
    DataCache.instance.invalidatePrefix('categories');
  }
}
