// ignore_for_file: unintended_html_in_doc_comment
/// Response chung của Backend REST API - dùng Generic với 2 tham số.
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
    return ApiResponse<T, E>(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null ? parser(json['data']) : null,
      error: json['error'] as E?,
      message: json['message']?.toString(),
    );
  }

  /// Trả về data nếu thành công, ngược lại trả về giá trị mặc định
  T? getDataOr(T fallback) => success ? (data ?? fallback) : fallback;

  bool get getHasError => error != null;

  @override
  String toString() {
    return 'ApiResponse{success: $success, message: $message, error: $error}';
  }
}
