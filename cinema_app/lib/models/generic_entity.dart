class GenericEntity<TId> {
  final TId id;
  final String name;
  final String? description;

  const GenericEntity({
    required this.id,
    required this.name,
    this.description,
  });

  // Phương thức chung: lấy ID
  TId getId() {
    return id;
  }

  // Phương thức chung: lấy tên
  String getName() {
    return name;
  }

  // Phương thức chung: lấy mô tả
  String? getDescription() {
    return description;
  }

  // Phương thức chung: hiển thị thông tin tóm tắt
  String describe() {
    return '#$id - $name';
  }
}