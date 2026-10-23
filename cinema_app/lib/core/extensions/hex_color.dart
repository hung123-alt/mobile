/// Extension để đổi chuỗi hex thành màu Color.
///
/// Cùng kiểu với ví dụ `extension Hexcolor on Color` trong tài liệu
/// MobileDev (Đánh giá ứng dụng đầu tiên).
///
/// Dùng:
///   Container(color: '#E50914'.toColor())
extension HexColor on String {
  /// Chuyển "#RRGGBB" hoặc "RRGGBB" thành Color
  Color toColor() {
    final hex = replaceFirst('#', '');
    final buffer = StringBuffer();

    // Nếu là mã 6 ký tự thì thêm alpha FF cho đủ 8 ký tự
    if (hex.length == 6) {
      buffer.write('ff');
    }
    buffer.write(hex);

    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Chuyển thành màu với độ mờ cho sẵn (0.0 - 1.0)
  Color toColorWithOpacity(double opacity) {
    return toColor().withValues(alpha: opacity);
  }
}

/// Extension tiện ích cho String khác
extension StringExtension on String {
  /// Viết hoa chữ cái đầu tiên
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  /// Cắt chuỗi dài thêm "..."
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }
}
