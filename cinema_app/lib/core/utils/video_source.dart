/// Chuẩn hoá mọi link phim admin dán vào: YouTube / VSMOV / mp4 / m3u8 / iframe.
library;

/// Loại nguồn phát sau khi phân loại.
enum VideoSourceType {
  youtube,
  directVideo, // .mp4 / .webm / .ogg / .mkv
  hls, // .m3u8 (VSMOV hay trả loại này)
  iframeEmbed, // link nhúng generic (vsmov, ok.ru, dailymotion, file embed...)
  unsupported,
}

class VideoSource {
  VideoSource._();

  /// Chuẩn hoá link thô thành link phát được.
  /// - YouTube `watch?v=`, `youtu.be/`, `shorts/`, `live/` -> `.../embed/ID`
  /// - Giữ nguyên link embed / mp4 / m3u8 / vsmov.
  /// - Tự thêm `https://` nếu thiếu scheme.
  static String normalize(String raw) {
    var url = raw.trim();
    if (url.isEmpty) return '';
    if (!url.contains('://')) {
      url = 'https://$url';
    }
    // YouTube -> embed
    final ytId = getYoutubeId(url);
    if (ytId.isNotEmpty) {
      // Giữ thêm tham số start nếu có (?t=90 / ?start=90)
      final start = _youtubeStartSeconds(url);
      final suffix = start > 0 ? '?start=$start' : '';
      return 'https://www.youtube.com/embed/$ytId$suffix';
    }
    return url;
  }

  /// Tách YouTube ID từ mọi dạng link phổ biến.
  static String getYoutubeId(String url) {
    if (url.trim().isEmpty) return '';
    final u = url.trim();
    final lower = u.toLowerCase();
    final isYtHost = lower.contains('youtube.com') || lower.contains('youtu.be');
    if (!isYtHost) return '';
    final regExp = RegExp(
      r'(youtu\.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=|shorts\/|live\/)([^#\&\?]{11})',
    );
    final match = regExp.firstMatch(u);
    final id = match?.group(2) ?? '';
    if (id.length == 11) return id;
    // Trường hợp link embed đã chuẩn: .../embed/ID...
    final embedReg = RegExp(r'embed\/([^#\&\?\/]{11})');
    final m2 = embedReg.firstMatch(u);
    return m2?.group(1) ?? '';
  }

  static int _youtubeStartSeconds(String url) {
    try {
      final uri = Uri.parse(url);
      final t = uri.queryParameters['t'] ?? uri.queryParameters['start'];
      if (t == null || t.isEmpty) return 0;
      // Hỗ trợ dạng 1h2m30s lẫn số giây thuần.
      final onlyDigits = RegExp(r'^\d+$').hasMatch(t);
      if (onlyDigits) return int.tryParse(t) ?? 0;
      var total = 0;
      final h = RegExp(r'(\d+)h').firstMatch(t);
      final m = RegExp(r'(\d+)m').firstMatch(t);
      final s = RegExp(r'(\d+)s').firstMatch(t);
      if (h != null) total += (int.tryParse(h.group(1)!) ?? 0) * 3600;
      if (m != null) total += (int.tryParse(m.group(1)!) ?? 0) * 60;
      if (s != null) total += int.tryParse(s.group(1)!) ?? 0;
      return total;
    } catch (_) {
      return 0;
    }
  }

  /// Phân loại nguồn phát.
  static VideoSourceType classify(String rawUrl) {
    final url = normalize(rawUrl);
    if (url.isEmpty) return VideoSourceType.unsupported;
    Uri? uri;
    try {
      uri = Uri.parse(url);
    } catch (_) {
      return VideoSourceType.unsupported;
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return VideoSourceType.unsupported;
    }
    if (getYoutubeId(url).isNotEmpty) return VideoSourceType.youtube;
    final path = uri.path.toLowerCase();
    final full = url.toLowerCase();
    if (path.endsWith('.m3u8') || full.contains('.m3u8')) {
      return VideoSourceType.hls;
    }
    const directExts = ['.mp4', '.webm', '.ogg', '.ogv', '.mkv', '.mov'];
    for (final ext in directExts) {
      if (path.endsWith(ext)) return VideoSourceType.directVideo;
    }
    return VideoSourceType.iframeEmbed;
  }

  /// Link có được phép mở trong WebView/iframe không.
  ///
  /// Quy tắc mới (thay whitelist cứng cũ chỉ cho YouTube):
  /// - Chặn scheme nguy hiểm: `file://`, `javascript:`, `data:`, `blob:` tuỳ ý.
  /// - Chấp nhận mọi `https` (và `http` ở localhost/dev) vì link do
  ///   **admin** nhập (rules Firestore chỉ cho admin ghi `episodes`),
  ///   nên tin cậy hơn nội dung user. VSMOV và các nguồn mới vì vậy
  ///   chạy được mà không phải vá whitelist mỗi lần thêm host.
  static bool isSupported(String rawUrl) {
    final url = rawUrl.trim();
    if (url.isEmpty) return false;
    final lower = url.toLowerCase();
    if (lower.startsWith('javascript:') ||
        lower.startsWith('data:') ||
        lower.startsWith('file:') ||
        lower.startsWith('blob:')) {
      return false;
    }
    Uri? uri;
    try {
      uri = Uri.parse(normalize(url));
    } catch (_) {
      return false;
    }
    if (uri.scheme == 'https') return true;
    // Cho phép http chỉ với host dev local (giống ApiService LỚP 4).
    if (uri.scheme == 'http') {
      const devHosts = {'localhost', '10.0.2.2', '127.0.0.1'};
      return devHosts.contains(uri.host.toLowerCase());
    }
    return false;
  }

  /// Nhãn gợi ý hiển thị trong form admin ("đã nhận diện: YouTube / HLS...").
  static String detectLabel(String rawUrl) {
    switch (classify(rawUrl)) {
      case VideoSourceType.youtube:
        return 'YouTube';
      case VideoSourceType.hls:
        return 'HLS (.m3u8) — VSMOV / stream';
      case VideoSourceType.directVideo:
        return 'Video trực tiếp (.mp4...)';
      case VideoSourceType.iframeEmbed:
        return 'Link nhúng (VSMOV / embed)';
      case VideoSourceType.unsupported:
        return 'Link chưa hợp lệ';
    }
  }

  /// Gợi ý tên server theo nguồn (để admin khỏi gõ tay sai).
  static String suggestServerName(String rawUrl) {
    switch (classify(rawUrl)) {
      case VideoSourceType.youtube:
        return 'YouTube';
      case VideoSourceType.hls:
        return 'VSMOV';
      case VideoSourceType.directVideo:
        return 'Server 1';
      case VideoSourceType.iframeEmbed:
        final lower = rawUrl.toLowerCase();
        if (lower.contains('vsmov')) return 'VSMOV';
        if (lower.contains('youtube') || lower.contains('youtu.be')) {
          return 'YouTube';
        }
        return 'Vietsub';
      case VideoSourceType.unsupported:
        return 'Vietsub';
    }
  }
}
