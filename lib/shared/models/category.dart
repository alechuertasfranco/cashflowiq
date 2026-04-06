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
}

class Category {
  final String id;
  final String name;
  final CategoryType type;
  final String? icon;
  final String? color;
  final String? parentId;

  Category({required this.id, required this.name, required this.type, this.icon, this.color, this.parentId});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      type: CategoryType.fromString(json['type']),
      icon: json['icon'],
      color: json['color'],
      parentId: json['parent_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {"name": name, "type": type.toApi(), "icon": icon, "color": color, "parent_id": parentId};
  }
}
