import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/firebase/collection_names.dart';
import '../models/comment_model.dart';

/// Tab "Quản lý bình luận" dành cho Admin.
///
/// Câu hỏi của màn hình: "Bình luận nào cần xử lý hôm nay?"
/// - Dải KPI chia ô bằng hairline: Tổng / Đang hiện / Đang ẩn / Hôm nay.
/// - Danh sách hàng 2 dòng: avatar người viết, tên + thời gian, tên phim,
///   nội dung, like/dislike, pill trạng thái, nút Ẩn/Hiện + Xóa.
/// - Lọc: tìm kiếm + trạng thái + sắp xếp. Ẩn/hiện và xóa ghi cả
///   camelCase lẫn snake_case để tương thích dữ liệu migrate MySQL cũ.
class AdminCommentsTab extends StatefulWidget {
  final VoidCallback? onDataChanged;

  const AdminCommentsTab({super.key, this.onDataChanged});

  @override
  State<AdminCommentsTab> createState() => _AdminCommentsTabState();
}

class _AdminCommentsTabState extends State<AdminCommentsTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<_AdminCommentRow> _allRows = [];

  String _statusFilter = 'all'; // all | visible | hidden
  String _sortBy = 'Mới nhất';
  static const List<String> _sortOptions = ['Mới nhất', 'Nhiều like', 'Cũ nhất'];

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static int _parseInt(dynamic raw, [int fallback = 0]) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw.trim()) ?? fallback;
    if (raw is bool) return raw ? 1 : 0;
    return fallback;
  }

  Future<void> _loadComments() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _firestore.collection(CollectionNames.comments).get(),
        _firestore.collection(CollectionNames.movies).get(),
        _firestore.collection(CollectionNames.users).get(),
      ]);
      final commentsSnap = results[0];
      final moviesSnap = results[1];
      final usersSnap = results[2];

      // movieId -> tên phim (chịu cả docId slug lẫn field id số).
      final movieTitleById = <int, String>{};
      for (final doc in moviesSnap.docs) {
        final d = doc.data();
        final id = _parseInt(d['id'] ?? doc.id, 0);
        final title = (d['title'] ?? d['name'] ?? '').toString().trim();
        if (id > 0 && title.isNotEmpty) movieTitleById[id] = title;
      }

      // userId -> tên + avatar.
      final userNameById = <int, String>{};
      final userAvatarById = <int, String>{};
      for (final doc in usersSnap.docs) {
        final d = doc.data();
        final id = _parseInt(d['id'] ?? doc.id, 0);
        if (id <= 0) continue;
        final name = (d['username'] ?? d['fullName'] ?? d['email'] ?? 'Người dùng #$id')
            .toString()
            .trim();
        userNameById[id] = name;
        final avatar = (d['avatarUrl'] ?? d['avatar_url'])?.toString() ?? '';
        if (avatar.isNotEmpty && avatar != 'null') userAvatarById[id] = avatar;
      }

      final rows = <_AdminCommentRow>[];
      for (final doc in commentsSnap.docs) {
        try {
          var c = Comment.fromJson(doc.data(), docId: doc.id);
          if (c.content.trim().isEmpty) continue;
          final fallbackName = userNameById[c.userId];
          final fallbackAvatar = userAvatarById[c.userId];
          if ((c.authorName == null || c.authorName!.trim().isEmpty) &&
              fallbackName != null) {
            c = c.copyWith(authorName: fallbackName);
          }
          if ((c.authorAvatar == null || c.authorAvatar!.isEmpty) &&
              fallbackAvatar != null) {
            c = c.copyWith(authorAvatar: fallbackAvatar);
          }
          rows.add(_AdminCommentRow(
            docId: doc.id,
            comment: c,
            movieTitle: movieTitleById[c.movieId] ?? 'Phim #${c.movieId}',
          ));
        } catch (_) {}
      }

      rows.sort((a, b) {
        final da = a.comment.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = b.comment.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final cmp = db.compareTo(da);
        if (cmp != 0) return cmp;
        return b.comment.id.compareTo(a.comment.id);
      });

      if (!mounted) return;
      setState(() {
        _allRows = rows;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('AdminCommentsTab load error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  int get _hiddenCount => _allRows.where((r) => r.comment.isHidden).length;
  int get _visibleCount => _allRows.length - _hiddenCount;
  int get _todayCount {
    final now = DateTime.now();
    return _allRows.where((r) {
      final d = r.comment.createdAt;
      return d != null && d.year == now.year && d.month == now.month && d.day == now.day;
    }).length;
  }

  List<_AdminCommentRow> get _filteredRows {
    final q = _searchController.text.trim().toLowerCase();
    final list = _allRows.where((r) {
      if (_statusFilter == 'visible' && r.comment.isHidden) return false;
      if (_statusFilter == 'hidden' && !r.comment.isHidden) return false;
      if (q.isNotEmpty) {
        final author = (r.comment.authorName ?? '').toLowerCase();
        final content = r.comment.content.toLowerCase();
        final movie = r.movieTitle.toLowerCase();
        if (!author.contains(q) && !content.contains(q) && !movie.contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();

    list.sort((a, b) {
      switch (_sortBy) {
        case 'Nhiều like':
          final cmp = b.comment.likeCount.compareTo(a.comment.likeCount);
          if (cmp != 0) return cmp;
          return b.comment.id.compareTo(a.comment.id);
        case 'Cũ nhất':
          final da = a.comment.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final db = b.comment.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final cmp = da.compareTo(db);
          if (cmp != 0) return cmp;
          return a.comment.id.compareTo(b.comment.id);
        case 'Mới nhất':
        default:
          final da = a.comment.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final db = b.comment.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final cmp = db.compareTo(da);
          if (cmp != 0) return cmp;
          return b.comment.id.compareTo(a.comment.id);
      }
    });
    return list;
  }

  String _formatNumber(int value) {
    final str = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  Future<void> _toggleHidden(_AdminCommentRow row) async {
    final next = !row.comment.isHidden;
    setState(() {
      final idx = _allRows.indexWhere((e) => e.docId == row.docId);
      if (idx != -1) {
        _allRows[idx] = _AdminCommentRow(
          docId: row.docId,
          comment: row.comment.copyWith(isHidden: next),
          movieTitle: row.movieTitle,
        );
      }
    });
    try {
      await _firestore.collection(CollectionNames.comments).doc(row.docId).set({
        'isHidden': next,
        'is_hidden': next ? 1 : 0,
        'updatedAt': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
      widget.onDataChanged?.call();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(next ? 'Đã ẩn bình luận #${row.comment.id}' : 'Đã hiện lại bình luận #${row.comment.id}'),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      await _loadComments();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cập nhật thất bại: $e'), backgroundColor: Colors.red[700]),
      );
    }
  }

  Future<void> _confirmDelete(_AdminCommentRow row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa bình luận'),
        content: Text('Xóa vĩnh viễn bình luận #${row.comment.id} của "${row.comment.authorName ?? 'người dùng'}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B4E),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _firestore.collection(CollectionNames.comments).doc(row.docId).delete();
      if (!mounted) return;
      setState(() => _allRows.removeWhere((e) => e.docId == row.docId));
      widget.onDataChanged?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã xóa bình luận'),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xóa thất bại: $e'), backgroundColor: Colors.red[700]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final textSecondary = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final borderColor = isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB);

    final rows = _filteredRows;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quản lý bình luận',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: textPrimary)),
          const SizedBox(height: 4),
          Text('Ẩn bình luận vi phạm, hiện lại khi cần, xóa rác — thay đổi áp dụng ngay cho người dùng.',
              style: TextStyle(fontSize: 12.5, color: textSecondary)),
          const SizedBox(height: 12),

          // Dải KPI chia ô bằng hairline: Tổng / Đang hiện / Đang ẩn / Hôm nay.
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                _buildKpiCell('Tổng', _formatNumber(_allRows.length), textPrimary, textSecondary, true, isDark),
                _buildKpiCell('Đang hiện', _formatNumber(_visibleCount), textPrimary, textSecondary, false, isDark),
                _buildKpiCell('Đang ẩn', _formatNumber(_hiddenCount), textPrimary, textSecondary, false, isDark),
                _buildKpiCell('Hôm nay', _formatNumber(_todayCount), textPrimary, textSecondary, false, isDark,
                    last: true),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Thanh tìm kiếm.
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF262626) : const Color(0xFFF1F3F6),
              borderRadius: BorderRadius.circular(22),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: TextStyle(fontSize: 13.5, color: textPrimary),
              decoration: InputDecoration(
                hintText: 'Tìm nội dung, người viết, tên phim...',
                hintStyle: TextStyle(fontSize: 13.5, color: textSecondary),
                prefixIcon: Icon(Icons.search_rounded, size: 20, color: textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded, size: 18, color: textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Hàng lọc trạng thái + sắp xếp.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterChip(keyName: 'all', label: 'Tất cả', isDark: isDark),
                const SizedBox(width: 8),
                _buildFilterChip(keyName: 'visible', label: 'Đang hiện', isDark: isDark),
                const SizedBox(width: 8),
                _buildFilterChip(keyName: 'hidden', label: 'Đang ẩn', isDark: isDark),
                const SizedBox(width: 12),
                Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sortBy,
                      icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: textSecondary),
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textPrimary),
                      dropdownColor: cardBg,
                      items: _sortOptions.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _sortBy = v);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          Text('Danh sách (${_formatNumber(rows.length)})',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary)),

          const SizedBox(height: 8),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF3B4E)))
                : RefreshIndicator(
                    color: const Color(0xFFFF3B4E),
                    onRefresh: _loadComments,
                    child: rows.isEmpty
                        ? ListView(children: [
                            const SizedBox(height: 60),
                            Center(
                                child: Text('Không có bình luận nào khớp bộ lọc',
                                    style: TextStyle(color: textSecondary, fontSize: 13.5)))
                          ])
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            padding: const EdgeInsets.only(bottom: 20),
                            itemCount: rows.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, index) => _buildRowCard(
                              row: rows[index],
                              isDark: isDark,
                              cardBg: cardBg,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              borderColor: borderColor,
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCell(String label, String value, Color textPrimary, Color textSecondary,
      bool first, bool isDark,
      {bool last = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            left: first ? BorderSide.none : BorderSide(color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFF0F0F0)),
          ),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11.5, color: textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({required String keyName, required String label, required bool isDark}) {
    final selected = _statusFilter == keyName;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = selected ? 'all' : keyName),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFF3B4E) : (isDark ? const Color(0xFF262626) : const Color(0xFFF1F3F6)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF374151)))),
      ),
    );
  }

  Widget _buildRowCard({
    required _AdminCommentRow row,
    required bool isDark,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
  }) {
    final c = row.comment;
    final hidden = c.isHidden;
    final author = (c.authorName != null && c.authorName!.trim().isNotEmpty)
        ? c.authorName!.trim()
        : 'Người dùng #${c.userId}';
    final time = c.getTimeAgoLabel();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildAvatar(c.authorAvatar, author),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(author,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: textPrimary)),
                        ),
                        const SizedBox(width: 6),
                        Text('#${c.id}',
                            style: TextStyle(fontSize: 11, color: textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('$time · ${row.movieTitle}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11.5, color: textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: hidden ? const Color(0xFFFFEDEA) : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(hidden ? 'Đang ẩn' : 'Đang hiện',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: hidden ? const Color(0xFF831C1E) : const Color(0xFF15803D))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(c.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13.5, color: textPrimary, height: 1.4)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.thumb_up_alt_outlined, size: 14, color: textSecondary),
              const SizedBox(width: 4),
              Text('${c.likeCount}', style: TextStyle(fontSize: 12, color: textSecondary)),
              const SizedBox(width: 12),
              Icon(Icons.thumb_down_alt_outlined, size: 14, color: textSecondary),
              const SizedBox(width: 4),
              Text('${c.dislikeCount}', style: TextStyle(fontSize: 12, color: textSecondary)),
              if (c.getIsReply()) ...[
                const SizedBox(width: 12),
                Text('Trả lời #${c.parentId}', style: TextStyle(fontSize: 11.5, color: textSecondary)),
              ],
              const Spacer(),
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: () => _toggleHidden(row),
                icon: Icon(hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 16, color: hidden ? Colors.green[700] : Colors.orange[800]),
                label: Text(hidden ? 'Hiện' : 'Ẩn',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: hidden ? Colors.green[700] : Colors.orange[800])),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Xóa',
                onPressed: () => _confirmDelete(row),
                icon: const Icon(Icons.delete_outline_rounded, size: 19, color: Color(0xFFE11D48)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl, String name) {
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty && avatarUrl != 'null';
    final initial = name.trim().isNotEmpty ? name.trim().substring(0, 1).toUpperCase() : '?';
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(color: Color(0xFFD1D5DB), shape: BoxShape.circle),
      child: ClipOval(
        child: hasAvatar
            ? Image.network(avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                      color: const Color(0xFFFF3B4E).withValues(alpha: 0.15),
                      alignment: Alignment.center,
                      child: Text(initial,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Color(0xFFFF3B4E), fontSize: 15)),
                    ))
            : Container(
                color: const Color(0xFFFF3B4E).withValues(alpha: 0.15),
                alignment: Alignment.center,
                child: Text(initial,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Color(0xFFFF3B4E), fontSize: 15)),
              ),
      ),
    );
  }
}

class _AdminCommentRow {
  final String docId;
  final Comment comment;
  final String movieTitle;

  const _AdminCommentRow({required this.docId, required this.comment, required this.movieTitle});
}
