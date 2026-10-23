/// Lớp cơ sở Generic có ràng buộc kiểu dữ liệu cho thuộc tính `id`.
///
/// Theo yêu cầu tuần 7 - "Generics với việc hạn chế kiểu dữ liệu":
/// sử dụng từ khóa `extends` để giới hạn T chỉ nhận một số kiểu nhất định.
///
/// Ở đây ta chọn `num` (gồm int và double) vì trong database:
///   - movies.id, users.id, comments.id  -> int
///   - ratings.score                     -> double
///
/// Kết quả: truyền sai kiểu sẽ báo LỖI NGAY LÚC CODE (compile time),
/// thay vì chạy mới phát hiện.
///
///   class Movie extends IdEntity<int> { ... }    // OK
///   class Movie extends IdEntity<String> { ... } // LỖI compile
class IdEntity<T extends num> {
  final T id;

  IdEntity({required this.id});

  T getId() => id;
  T setId(T newId) => newId;

  @override
  String toString() => 'IdEntity{id: $id}';
}
