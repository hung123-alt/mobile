/// Response chung của API - dùng Generic với 2 tham số.
///
/// Theo yêu cầu tuần 7 - "Generics với nhiều tham số":
///   class ApiResponse<T, E> { ... }
///
///   T = kiểu dữ liệu trong trường `data`
///   E = kiểu dữ liệu trong trường `error`
///
/// Dùng cho mọi service gọi về backend NestJS:
///   final res = await ApiResponse<List<Movie>, String>.fromJson(
///     json,
///     (e) => (e as List).map((m) => Movie.fromJson(m)).toList(),
///   );
class ApiResponse<T, E> {
  final bool success;
  final T? data;
  final E? error;
  final String? message;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.message,
  });

  /// Parser từ JSON, nhận hàm `parser` để biến `dynamic` thành kiểu T
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic raw) parser,
  ) {
    return ApiResponse<T, String>(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null ? parser(json['data']) : null,
      error: json['error']?.toString(),
      message: json['message']?.toString(),
    );
  }

  /// Trả về data nếu thành công, ngược lại trả về giá trị mặc định
  T? getDataOr(T fallback) => success ? (data ?? fallback) : fallback;

  bool getHasError => error != null;

  @override
  String toString() {
    return 'ApiResponse{success: $success, message: $message, error: $error}';
  }
}
