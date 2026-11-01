import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/firebase/collection_names.dart';
import '../models/episode_model.dart';

/// Widget hiển thị lưới tập phim (hỗ trợ chọn Server nếu có nhiều server).
///
/// Dùng chung cho cả `MovieDetailPage` và `PlayerPage`.
class EpisodeGrid extends StatefulWidget {
  final List<Episode> episodes;
  final bool isLoading;
  final Episode? selectedEpisode;
  final ValueChanged<Episode> onEpisodeTap;

  const EpisodeGrid({
    super.key,
    required this.episodes,
    required this.onEpisodeTap,
    this.isLoading = false,
    this.selectedEpisode,
  });

  /// Tải danh sách tập phim của một bộ phim theo [movieId] từ Firestore collection `episodes`.
  static Future<List<Episode>> fetchEpisodesForMovie(int movieId) async {
    final firestore = FirebaseFirestore.instance;

    try {
      var snap = await firestore
          .collection(CollectionNames.episodes)
          .where('movieId', isEqualTo: movieId)
          .get();

      if (snap.docs.isEmpty) {
        snap = await firestore
            .collection(CollectionNames.episodes)
            .where('movie_id', isEqualTo: movieId)
            .get();
      }

      final list = <Episode>[];
      for (final doc in snap.docs) {
        try {
          list.add(Episode.fromJson(doc.data()));
        } catch (e) {
          debugPrint('Lỗi parse episode doc ${doc.id}: $e');
        }
      }

      list.sort((a, b) {
        final cmp = a.episodeNumber.compareTo(b.episodeNumber);
        if (cmp != 0) return cmp;
        return a.id.compareTo(b.id);
      });

      return list;
    } catch (e) {
      debugPrint('Lỗi tải episodes cho movieId=$movieId: $e');
      return <Episode>[];
    }
  }

  @override
  State<EpisodeGrid> createState() => _EpisodeGridState();
}

class _EpisodeGridState extends State<EpisodeGrid> {
  String? _activeServer;

  List<String> get _servers {
    final set = <String>{};
    for (final ep in widget.episodes) {
      final s = ep.serverName.trim().isNotEmpty ? ep.serverName.trim() : 'Vietsub';
      set.add(s);
    }
    return set.toList();
  }

  @override
  void initState() {
    super.initState();
    _syncActiveServer();
  }

  @override
  void didUpdateWidget(covariant EpisodeGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.episodes != widget.episodes ||
        oldWidget.selectedEpisode != widget.selectedEpisode) {
      _syncActiveServer();
    }
  }

  void _syncActiveServer() {
    if (widget.selectedEpisode != null) {
      final selServer = widget.selectedEpisode!.serverName.trim();
      if (selServer.isNotEmpty) {
        _activeServer = selServer;
        return;
      }
    }
    final servers = _servers;
    if (servers.isNotEmpty &&
        (_activeServer == null || !servers.contains(_activeServer))) {
      _activeServer = servers.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Color(0xFFFF4B5C),
            ),
          ),
        ),
      );
    }

    if (widget.episodes.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 20,
              color: isDark ? Colors.white54 : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 8),
            Text(
              'Đang cập nhật tập phim',
              style: TextStyle(
                fontSize: 13.5,
                color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final servers = _servers;
    final currentServer = _activeServer ?? servers.first;
    final filteredEpisodes = servers.length > 1
        ? widget.episodes
            .where((ep) =>
                (ep.serverName.trim().isNotEmpty
                    ? ep.serverName.trim()
                    : 'Vietsub') ==
                currentServer)
            .toList()
        : widget.episodes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thanh chọn Server (nếu phim có nhiều hơn 1 server)
        if (servers.length > 1) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: servers.map((srv) {
              final isSelectedSrv = srv == currentServer;
              return GestureDetector(
                onTap: () {
                  setState(() => _activeServer = srv);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelectedSrv
                        ? const Color(0xFFFF4B5C).withValues(alpha: 0.14)
                        : (isDark
                            ? const Color(0xFF262626)
                            : const Color(0xFFF3F4F6)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelectedSrv
                          ? const Color(0xFFFF4B5C)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.dns_rounded,
                        size: 14,
                        color: isSelectedSrv
                            ? const Color(0xFFFF4B5C)
                            : const Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        srv,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelectedSrv
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelectedSrv
                              ? const Color(0xFFFF4B5C)
                              : (isDark
                                  ? Colors.white70
                                  : const Color(0xFF4B5563)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],

        // Lưới các nút chọn tập (5 tập mỗi hàng ngang rồi xuống dòng)
        GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredEpisodes.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 42,
          ),
          itemBuilder: (context, index) {
            final ep = filteredEpisodes[index];
            final isSelected = widget.selectedEpisode != null &&
                (widget.selectedEpisode!.id == ep.id && ep.id != 0 ||
                    (widget.selectedEpisode!.episodeNumber ==
                            ep.episodeNumber &&
                        widget.selectedEpisode!.serverName == ep.serverName));
            final label = ep.getShortLabel();

            return GestureDetector(
              onTap: () => widget.onEpisodeTap(ep),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFF4B5C)
                      : (isDark
                          ? const Color(0xFF262626)
                          : const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color:
                                const Color(0xFFFF4B5C).withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : const Color(0xFF374151)),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
