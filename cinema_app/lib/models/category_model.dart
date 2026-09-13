class Category {
  int id;
  String name;
  String description;
  bool isActive;
  DateTime createdAt;
  DateTime updatedAt;

  // Constructor
  Category({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  // Hiển thị thông tin Category
  void displayInfo() {
    print('ID: $id');
    print('Name: $name');
    print('Description: $description');
    print('Active: $isActive');
    print('Created At: $createdAt');
    print('Updated At: $updatedAt');
  }

  // Chuyển Object -> Map
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

  // Chuyển Map -> Object
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      isActive: json['isActive'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}