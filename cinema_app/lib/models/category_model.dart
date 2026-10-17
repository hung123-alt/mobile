import 'generic_entity.dart';

class Category extends GenericEntity<int> {
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    required int id,
    required String name,
    required String description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  }) : super(
          id: id,
          name: name,
          description: description,
        );

  // Giữ kiểu String cho description của Category.
  // Trong model Category, description là thông tin bắt buộc.
  @override
  String get description => super.description!;

  // Hiển thị thông tin Category
  void displayInfo() {
    print('ID: $id');
    print('Name: $name');
    print('Description: $description');
    print('Active: $isActive');
    print('Created At: $createdAt');
    print('Updated At: $updatedAt');
  }

  // Chuyển Object thành Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Chuyển Map thành Object
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  // Sử dụng phương thức describe() được kế thừa
}