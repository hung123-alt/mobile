/// Bộ tiện ích Generic dùng chung cho toàn app.
///
/// Áp dụng kiến thức tuần 7 - "Generics với hàm" (tuần 3 PDF slide 26)
/// mở rộng lên: tìm kiếm, lọc, sắp xếp, gom nhóm.
///
/// Mục tiêu: viết 1 lần, dùng cho MỌI kiểu dữ liệu (T).
library;

/// Tìm phần tử đầu tiên thỏa điều kiện, trả về null nếu không tìm thấy.
///
/// Tìm phim đầu tiên có điểm >= 8:
///   firstWhereOrNull<Movie>(movies, (m) => m.getRating() >= 8)
T? firstWhereOrNull<T>(List<T> items, bool Function(T item) test) {
  for (final item in items) {
    if (test(item)) {
      return item;
    }
  }
  return null;
}

/// Tìm phần tử đầu tiên thỏa điều kiện, trả về giá trị mặc định nếu không có.
///
///   firstWhereOrElse<Movie>(movies, (m) => m.getRating() >= 8, fallback)
T firstWhereOrElse<T>(
  List<T> items,
  bool Function(T item) test,
  T fallback,
) {
  return firstWhereOrNull<T>(items, test) ?? fallback;
}

/// Đếm số phần tử có giá trị bằng giá trị cho trước.
/// (Đây chính là ví dụ `countItem<T>` trong slide tuần 3)
int countItem<T>(List<T> list, T itemToCount) {
  int count = 0;
  for (final item in list) {
    if (item == itemToCount) {
      count++;
    }
  }
  return count;
}

/// Lọc danh sách theo điều kiện, trả về List<T> (không phải Iterable).
///
///   whereList<Movie>(movies, (m) => m.getType() == 'phim_le')
List<T> whereList<T>(List<T> items, bool Function(T item) test) {
  return items.where(test).toList();
}

/// Lọc theo chuỗi (không phân biệt hoa thường), dùng cho ô tìm kiếm.
///
///   searchBy<Movie>(movies, 'abc', (m) => m.getName())
List<T> searchBy<T>(
  List<T> items,
  String keyword,
  String Function(T item) textOf,
) {
  final key = keyword.trim().toLowerCase();
  if (key.isEmpty) {
    return List<T>.from(items);
  }
  return items
      .where((item) => textOf(item).toLowerCase().contains(key))
      .toList();
}

/// Sắp xếp theo khóa, trả về bản COPY (không thay đổi danh sách gốc).
///
/// Đây là ví dụ dùng 2 tham số generic + ràng buộc Comparable:
///   T = kiểu phần tử, K = kiểu khóa sắp xếp
///
///   sortedBy<Movie, double>(movies, (m) => m.getRating())
List<T> sortedBy<T, K extends Comparable<K>>(
  List<T> items,
  K Function(T item) keyOf,
) {
  final copy = List<T>.from(items);
  copy.sort((a, b) => keyOf(a).compareTo(keyOf(b)));
  return copy;
}

/// Sắp xếp theo khóa, cho phép đảo chiều.
///
///   sortedByDesc<Movie, double>(movies, (m) => m.getRating())
List<T> sortedByDesc<T, K extends Comparable<K>>(
  List<T> items,
  K Function(T item) keyOf,
) {
  final copy = List<T>.from(items);
  copy.sort((a, b) => keyOf(b).compareTo(keyOf(a)));
  return copy;
}

/// Gom các phần tử theo khóa, trả về Map<K, List<T>>.
///
///   groupBy<Movie, String>(movies, (m) => m.getType())
Map<K, List<T>> groupBy<T, K>(List<T> items, K Function(T item) keyOf) {
  final result = <K, List<T>>{};
  for (final item in items) {
    final key = keyOf(item);
    result.putIfAbsent(key, () => <T>[]).add(item);
  }
  return result;
}

/// Đếm số phần tử theo điều kiện.
///
///   countWhere<Movie>(movies, (m) => m.getRating() >= 8)
int countWhere<T>(List<T> items, bool Function(T item) test) {
  int count = 0;
  for (final item in items) {
    if (test(item)) {
      count++;
    }
  }
  return count;
}

/// Lấy tối đa `limit` phần tử đầu tiên.
///
///   takeFirst<Movie>(movies, 10)
List<T> takeFirst<T>(List<T> items, int limit) {
  if (items.length <= limit) {
    return List<T>.from(items);
  }
  return items.take(limit).toList();
}

/// Tách danh sách thành các nhóm nhỏ kích thước `size`.
///
///   chunk<Movie>(movies, 3)  // [[m1,m2,m3], [m4,m5,m6], ...]
List<List<T>> chunk<T>(List<T> items, int size) {
  if (size <= 0) return <List<T>>[];
  final result = <List<T>>[];
  for (int i = 0; i < items.length; i += size) {
    result.add(items.sublist(i, (i + size).clamp(0, items.length)));
  }
  return result;
}

/// Chuyển danh sách thành Map theo khóa (giữ phần tử cuối cùng nếu trùng key).
///
///   toMap<Movie, int>(movies, (m) => m.getId())
Map<K, T> toMap<T, K>(List<T> items, K Function(T item) keyOf) {
  final result = <K, T>{};
  for (final item in items) {
    result[keyOf(item)] = item;
  }
  return result;
}
