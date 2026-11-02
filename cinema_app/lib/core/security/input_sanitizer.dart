
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
    if (uri.scheme.isEmpty) return true; 
    return false; 
  }
}
