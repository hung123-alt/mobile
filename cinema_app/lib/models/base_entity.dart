/// Lớp cơ sở Generic dùng chung cho mọi entity.
///
/// Mục đích: tránh lặp lại các thuộc tính giống nhau
/// (id / name / description) cho từng model.
///
/// Theo yêu cầu tuần 7 - Generics trong Dart:
///   class BaseEntity<T> { ... }
///
/// Lớp con chỉ cần khai báo, không viết lại phần chung:
///   class Movie extends BaseEntity<int> { ... }
///
/// Quy ước đặt tên tham số generic:
///   - 1 chữ cái: T, E, K, V
///   - Nhiều chữ cái: TKey, TValue
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
