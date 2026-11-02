/// LOP 6 - LOC DAU VAO PHIA CLIENT (XSS) (P2).
///
/// VÌ SAO CAN?
/// - Server NestJS da co sanitize-html: mobile gui noi dung len, server tu
///   lam sach truoc khi luu. Nhung mobile van phai:
///   1. Cat chuoi qua dai truoc khi gui (do ton RAM/data).
///   2. KHONG tu render HTML (khong dung flutter_html de hien noi dung
///      server tra ve). Chi hien bang Text -> the <script> cung chi la chu.
///   3. Goi bo the HTML neu user paste tu web vao o nhap.
///
/// Quy tac: Service CHI goi ham nay de lam sach, KHONG try/catch o day;
/// Repository/Provider bat loi o ranh gioi I/O.
class InputSanitizer {
  InputSanitizer._();

  static final RegExp _htmlTags = RegExp(r'<[^>]*>', multiLine: true);
  static final RegExp _multiSpace = RegExp(r'\s+');

  /// Loai bo the HTML, gon khoang trang, cat do dai toi da.
  /// [maxLength] mac dinh 2000 (khop AppConstants.commentMaxLength).
  static String cleanText(String input, {int maxLength = 2000}) {
    var out = input.replaceAll(_htmlTags, '');
    out = out.replaceAll(_multiSpace, ' ').trim();
    if (out.length > maxLength) {
      out = out.substring(0, maxLength).trim();
    }
    return out;
  }

  /// Kiem tra noi dung binh luan truoc khi gui (tra ve loi tieng Viet).
  static String? validateComment(String input) {
    final cleaned = cleanText(input);
    if (cleaned.isEmpty) return 'Vui lòng nhập nội dung bình luận';
    return null; // hop le
  }

  /// Kiem tra URL anh dai dien: chi cho https (hoac asset noi bo).
  static bool isSafeImageUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return false;
    if (uri.scheme == 'https') return true;
    if (uri.scheme.isEmpty) return true; // duong dan asset noi bo
    return false; // chan file://, javascript:, data:, http
  }
}
