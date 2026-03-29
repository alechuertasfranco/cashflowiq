// lib\shared\models\bank_entity.dart

class BankEntity {
  final String id;
  final String name;
  final String code;
  final String? colorHex;

  BankEntity({required this.id, required this.name, required this.code, this.colorHex});

  factory BankEntity.fromJson(Map<String, dynamic> json) {
    return BankEntity(id: json['id'].toString(), name: json['name'], code: json['code'], colorHex: json['color']);
  }

  Map<String, dynamic> toJson() {
    return {"name": name, "code": code, "color": colorHex};
  }
}
