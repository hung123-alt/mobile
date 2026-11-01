import 'package:flutter/material.dart';

import '../providers/watch_history_provider.dart';
import '../widgets/app_top_navbar.dart';
import 'player_page.dart';

/// Trang Lịch sử xem phim (điều hướng từ mục "Lịch sử xem" ở trang Tài khoản).
class WatchHistoryPage extends StatefulWidget {
  const WatchHistoryPage({super.key});

  @override
  State<WatchHistoryPage> createState() => _WatchHistoryPageState();
}

class _WatchHistoryPageState extends State<WatchHistoryPage> {
  final WatchHistoryProvider _historyProvider = WatchHistoryProvider.instance;

  @override
  void initState() {
    super.initState();
    _historyProvider.loadHistory();
  }

  Future<void> _confirmClearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá toàn bộ lịch sử?'),
        content: const Text(
          'Bạn có chắc chắn muốn xoá toàn bộ lịch sử xem phim không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4B5C),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá tất cả'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _historyProvider.clearAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa toàn bộ lịch sử xem phim'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _historyProvider,
          builder: (context, _) {
            final list = _historyProvider.history;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Navbar dùng chung
                const AppTopNavbar(showBackIfCanPop: true),

                // Tiêu đề: "Lịch sử xem" + Nút "Xoá tất cả"
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Lịch sử xem',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (list.isNotEmpty)
                        TextButton.icon(
                          onPressed: _confirmClearAll,
                          icon: const Icon(
                            Icons.delete_sweep_outlined,
                            size: 18,
                            color: Color(0xFFFF4B5C),
                          ),
                          label: const Text(
                            'Xoá tất cả',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFFFF4B5C),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Nội dung danh sách
                Expanded(
                  child: _historyProvider.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF4B5C),
                          ),
                        )
                      : list.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.history_rounded,
                                      size: 64,
                                      color: isDark
                                          ? Colors.grey[700]
                                          : Colors.grey[350],
                                    ),
                                    const SizedBox(height: 14),
                                    const Text(
                                      'Chưa có lịch sử xem phim',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Các tập phim bạn đã xem sẽ được lưu lại tại đây để xem tiếp dễ dàng.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              itemCount: list.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 16),
                              itemBuilder: (context, index) {
                                final item = list[index];
                                return _buildHistoryItem(item, isDark);
                              },
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHistoryItem(WatchHistoryRecord record, bool isDark) {
    final movie = record.movie;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerPage(
              movie: movie,
              initialEpisode: record.episodeNumber,
            ),
          ),
        );
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            // Poster phim kèm icon Play ở góc
            Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 56,
                    height: 76,
                    color: isDark
                        ? const Color(0xFF262626)
                        : const Color(0xFFE5E7EB),
                    child: movie.displayImageUrl != null
                        ? Image.network(
                            movie.displayImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.movie_outlined,
                              size: 24,
                              color: Colors.grey,
                            ),
                          )
                        : const Icon(
                            Icons.movie_outlined,
                            size: 24,
                            color: Colors.grey,
                          ),
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // Tên phim, tập đang xem và thời gian xem
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFFF4B5C).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Xem tiếp ${record.episodeLabel}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFF4B5C),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          record.getTimeAgoLabel(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${movie.getTypeLabel()} · ${movie.releaseYear ?? 2026}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),

            // Nút xoá 1 mục
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFF9CA3AF),
                size: 20,
              ),
              onPressed: () => _historyProvider.removeRecord(record),
            ),
          ],
        ),
      ),
    );
  }
}

