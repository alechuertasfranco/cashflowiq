// lib\shared\models\category.dart

enum CategoryType {
  income,
  expense;

  factory CategoryType.fromString(String value) {
    switch (value.toUpperCase()) {
      case 'INCOME':
        return CategoryType.income;
      case 'EXPENSE':
        return CategoryType.expense;
      default:
        throw Exception("Unknown category type: $value");
    }
  }

  String toApi() => name.toUpperCase();

  String toLabel() {
    switch (this) {
      case CategoryType.income:
        return "Ingreso";
      case CategoryType.expense:
        return "Gasto";
    }
  }
}

class Category {
  final String id;
  final String name;
  final CategoryType type;
  final String? icon;
  final String? color;
  final String? parentId;
  final Category? parent;
  final List<Category> children;

  Category({
    required this.id,
    required this.name,
    required this.type,
    this.icon,
    this.color,
    this.parentId,
    this.parent,
    this.children = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      type: CategoryType.fromString(json['type']),
      icon: json['icon'],
      color: json['color'],
      parentId: json['parent_id']?.toString(),
      parent: json['parent'] != null ? Category.fromJson(json['parent']) : null,
      children: json['children'] != null ? (json['children'] as List).map((e) => Category.fromJson(e)).toList() : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {"id": id, "name": name, "type": type.toApi(), "icon": icon, "color": color, "parent_id": parentId};
  }
}
