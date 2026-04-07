// lib\features\profile\data\category_service.dart

import 'package:cashflowiq/core/network/api_client.dart';
import 'package:cashflowiq/shared/models/category.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart';

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
    debugPrint("API response for categories: $response");
    if (response is! List) throw Exception("Invalid response");
    return response.map<Category>((e) => Category.fromJson(e)).toList();
  }

  Future<Category> createCategory(Category category) async {
    final response = await ApiClient.postJson("/categories", body: category.toJson());
    return Category.fromJson(response);
  }

  Future<Category> updateCategory(Category category) async {
    final response = await ApiClient.putJson("/categories/${category.id}", body: category.toJson());
    return Category.fromJson(response);
  }

  Future<Response> deleteCategory(Category category) async {
    return await ApiClient.delete("/categories/${category.id}");
  }
}
