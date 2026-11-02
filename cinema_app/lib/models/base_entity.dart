/// Lớp cơ sở Generic dùng chung cho mọi entity.
class BaseEntity<T> {
  final T id;
  final String name;
  final String description;

  BaseEntity({
    required this.id,
    required this.name,
    required this.description,
  });

  // ===== Getters - dạng hàm theo phong cách giáo viên lớp MobileDev =====

  T getId() => id;
  String getName() => name;
  String getDescription() => description;

  // ===== Setters - trả về giá trị mới cho phép dùng luôn =====

  T setId(T newId) => newId;
  String setName(String newName) => newName;
  String setDescription(String newDescription) => newDescription;

  /// Chuyển sang Map để debug / log
  @override
  String toString() {
    return 'BaseEntity{id: $id, name: $name, description: $description}';
  }
}
