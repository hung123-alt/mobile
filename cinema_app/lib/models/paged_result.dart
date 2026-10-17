class PagedResult<T> {
  final List<T> data;
  final int page;
  final int limit;
  final bool hasMore;

  const PagedResult({
    required this.data,
    required this.page,
    required this.limit,
    required this.hasMore,
  });

  // fromItem: hàm cho biết cách chuyển 1 Map thành 1 đối tượng kiểu T
  factory PagedResult.fromMap(
    Map<String, dynamic> map,
    T Function(Map<String, dynamic>) fromItem,
  ) {
    final raw = map['data'] as List<dynamic>;
    return PagedResult<T>(
      data: raw.map((e) => fromItem(e as Map<String, dynamic>)).toList(),
      page: map['page'] as int,
      limit: map['limit'] as int,
      hasMore: map['hasMore'] as bool,
    );
  }

  // Nối trang sau vào trang trước (cho nút "Tải thêm")
  PagedResult<T> noiThem(PagedResult<T> trangSau) {
    return PagedResult<T>(
      data: [...data, ...trangSau.data],
      page: trangSau.page,
      limit: trangSau.limit,
      hasMore: trangSau.hasMore,
    );
  }

  bool get isEmpty => data.isEmpty;
}