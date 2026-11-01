/// Kết quả phân trang - dùng Generic 1 tham số.
///
/// Server NestJS trả về dạng:
///   { items: [...], total: 90, page: 1, limit: 12 }
///
/// Dùng cho mọi danh sách có phân trang (danh sách phim, bình luận...):
///   final result = await PageResult<Movie>.fromJson(
///     json,
///     (e) => Movie.fromJson(e),
///   );
///   result.getTotalPages();
class PageResult<T> {
  final List<T> items;
  final int total;
  final int page;
  final int limit;

  PageResult({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  /// Tổng số trang
  int getTotalPages() => limit == 0 ? 0 : (total / limit).ceil();

  /// Còn trang sau không
  bool getHasNext() => page < getTotalPages();

  /// Còn trang trước không
  bool getHasPrevious() => page > 1;

  /// Trang kế tiếp
  int getNextPage() => getHasNext() ? page + 1 : page;

  /// Trang trước
  int getPreviousPage() => getHasPrevious() ? page - 1 : page;

  /// Danh sách rỗng
  factory PageResult.empty() {
    return PageResult<T>(
      items: <T>[],
      total: 0,
      page: 1,
      limit: 10,
    );
  }

  factory PageResult.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic raw) parser,
  ) {
    return PageResult<T>(
      items: (json['items'] as List?)
              ?.map((e) => parser(e))
              .toList() ??
          <T>[],
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 10,
    );
  }

  @override
  String toString() {
    return 'PageResult{page: $page/$getTotalPages(), total: $total, items: ${items.length}}';
  }
}
