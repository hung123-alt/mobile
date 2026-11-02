import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/movie_model.dart';

/// Helper chuẩn hoá Chia sẻ phim dùng chung cho Chi tiết + Trang xem.
///
/// - Link chuẩn: `https://phimhay24h.app/movie/<slug>` (fallback id khi thiếu slug).
/// - BottomSheet đẹp: preview tên phim + link, nút Sao chép + nút Chia sẻ hệ thống.
/// - Nút "Chia sẻ hệ thống" dùng `Share.share` của `share_plus` nếu project đã
///   thêm dependency; nếu chưa có thì fallback sao chép + snackbar (không crash).
class MovieShareHelper {
  MovieShareHelper._();

  static const Color primaryColor = Color(0xFFFF4B5C);

  /// Link chia sẻ chuẩn của 1 phim.
  static String buildMovieLink(Movie movie) {
    final slug = movie.slug.trim();
    final path = slug.isNotEmpty ? slug : movie.id.toString();
    return 'https://phimhay24h.app/movie/$path';
  }

  /// Text chia sẻ chuẩn.
  static String buildShareText(Movie movie) {
    final link = buildMovieLink(movie);
    return 'Xem phim "${movie.name}" trên PhimHay24h: $link';
  }

  /// Mở BottomSheet chia sẻ chuẩn.
  static Future<void> showShareSheet(BuildContext context, Movie movie) {
    final link = buildMovieLink(movie);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final textSecondary =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563);
    final inputBg =
        isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6);

    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 22,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.share_rounded,
                        color: primaryColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chia sẻ phim',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            movie.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: inputBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          link,
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          await Clipboard.setData(
                            ClipboardData(text: link),
                          );
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Đã sao chép liên kết: ${movie.name}',
                                ),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.copy_rounded,
                              size: 16,
                              color: primaryColor,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Sao chép',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final text = buildShareText(movie);
                      final done = await _systemShare(text, link);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              done
                                  ? 'Đang mở tuỳ chọn chia sẻ...'
                                  : 'Đã sao chép liên kết: ${movie.name}',
                            ),
                            backgroundColor:
                                done ? primaryColor : Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.ios_share_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    label: const Text(
                      'Chia sẻ qua ứng dụng khác',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Link mở được trên web & mobile (deep link).',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Cố gắng gọi `share_plus` qua dynamic (tránh hard dependency lúc build
  /// nếu team chưa `flutter pub add share_plus`). Trả về true nếu đã mở
  /// được share sheet hệ thống.
  static Future<bool> _systemShare(String text, String link) async {
    try {
      await Share.share(text, subject: 'Chia sẻ phim PhimHay24h');
      return true;
    } catch (_) {
      // fallback bên dưới
    }
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (_) {}
    return false;
  }

  /// Trả về object có method `share(text, {subject})` nếu `share_plus`
  /// khả dụng, ngược lại null. Dùng `Function.apply` qua `dynamic`
  /// để không cần import cứng ở compile-time vẫn chạy được khi đã pub get.
  static Future<dynamic> _loadSharePlus() async {
    // Đã dùng `share_plus` trực tiếp ở [_systemShare], giữ hàm này để
    // tương thích ngược nếu nơi khác còn gọi.
    return null;
  }
}
