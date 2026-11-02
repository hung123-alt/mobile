/// Chuẩn hoá tiếng Việt: bỏ dấu, thường hoá, gọn khoảng trắng.
/// Dùng chung cho STT, wake-word và tìm phim không dấu.
class TextNormalizer {
  TextNormalizer._();

  static const Map<String, String> _vietnameseMap = {
    'á': 'a', 'à': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a',
    'ă': 'a', 'ắ': 'a', 'ằ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
    'â': 'a', 'ấ': 'a', 'ầ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a',
    'đ': 'd',
    'é': 'e', 'è': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
    'ê': 'e', 'ế': 'e', 'ề': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',
    'í': 'i', 'ì': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
    'ó': 'o', 'ò': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o',
    'ô': 'o', 'ố': 'o', 'ồ': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o',
    'ơ': 'o', 'ớ': 'o', 'ờ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',
    'ú': 'u', 'ù': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
    'ư': 'u', 'ứ': 'u', 'ừ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u',
    'ý': 'y', 'ỳ': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
  };

  static final RegExp _multiSpace = RegExp(r'\s+');
  static final RegExp _punct = RegExp(r'''[.,;:!?'"“”‘’()\[\]{}<>|/\\\-_=+*#@%^&~`$]''');

  /// "Dấu Vết Trọn Đời!" -> "dau vet tron doi"
  static String normalize(String input) {
    var out = input.toLowerCase().trim();
    final buf = StringBuffer();
    for (var i = 0; i < out.length; i++) {
      final ch = out[i];
      buf.write(_vietnameseMap[ch] ?? ch);
    }
    var s = buf.toString();
    s = s.replaceAll(_punct, ' ');
    s = s.replaceAll(_multiSpace, ' ').trim();
    return s;
  }

  /// Tách token để chấm điểm: "dau vet tron doi" -> ["dau","vet","tron","doi"]
  static List<String> tokens(String normalized) {
    if (normalized.isEmpty) return const [];
    return normalized.split(' ').where((t) => t.isNotEmpty).toList();
  }

  /// Kiểm tra wake-word sau khi đã chuẩn hoá cả 2 phía.
  static bool matchesWakeWord(String spoken, List<String> wakeWords) {
    final n = normalize(spoken);
    for (final w in wakeWords) {
      if (n == w || n.endsWith(' $w') || n.startsWith('$w ')) return true;
      if (n.contains(w)) return true;
    }
    return false;
  }

  /// Chấm điểm khớp tên phim: 100 = slug khớp, 80 = chứa nguyên cụm, 50+ = đủ token.
  static int scoreTitle({
    required String queryNorm,
    required List<String> queryTokens,
    required String titleNorm,
    required String slug,
  }) {
    if (queryNorm.isEmpty || titleNorm.isEmpty) return 0;
    if (queryNorm == slug || queryNorm == titleNorm) return 100;
    if (titleNorm.contains(queryNorm)) return 80;
    if (queryNorm.length >= 4 && slug.contains(queryNorm.replaceAll(' ', '-'))) {
      return 75;
    }
    if (queryTokens.isEmpty) return 0;
    var hit = 0;
    for (final t in queryTokens) {
      if (t.length < 2) continue;
      if (titleNorm.contains(t)) hit++;
    }
    if (hit == 0) return 0;
    final ratio = hit / queryTokens.length;
    if (ratio >= 1.0) return 60;
    if (ratio >= 0.6) return 40;
    if (ratio >= 0.4) return 20;
    return 0;
  }
}
