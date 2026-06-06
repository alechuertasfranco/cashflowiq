// lib/features/profile/data/category_service.dart

import 'package:cashflowiq/core/network/api_client.dart';
import 'package:cashflowiq/shared/models/category.dart';

class CategoryService {
  Future<List<Category>> getCategories({CategoryType? type}) async {
    final query = type != null ? "?type=${type.toApi()}" : "";
    final response = await ApiClient.getJson("/categories$query");

    if (response is! List) throw Exception("Invalid response");

    return response.map<Category>((e) => Category.fromJson(e)).toList();
  }

  Future<List<Category>> getCategoriesWithChildren({CategoryType? type}) async {
    final query = type != null ? "?type=${type.toApi()}" : "";
    final response = await ApiClient.getJson("/categories/with-children$query");

    if (response is! List) throw Exception("Invalid response");

    return response.map<Category>((e) => Category.fromJson(e)).toList();
  }

  Future<Category> createCategory(Category category) async {
    final response = await ApiClient.postJson("/categories", body: category.toCreateJson());

    return Category.fromJson(response);
  }

  Future<Category> updateCategory(Category category) async {
    final response = await ApiClient.putJson("/categories/${category.id}", body: category.toUpdateJson());

    return Category.fromJson(response);
  }

  Future<void> deleteCategory(String id) async {
    await ApiClient.delete("/categories/$id");
  }
}
