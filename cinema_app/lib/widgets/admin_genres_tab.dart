import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/firebase/collection_names.dart';
import '../models/genre_model.dart';

/// Tab "Quản lý thể loại" dành cho Admin.
///
/// Câu hỏi của màn hình: "Thể loại nào đang nuôi bao nhiêu phim?"
/// - Dải KPI chia ô bằng hairline: Tổng / Đang hiện / Đang ẩn / Lượt gắn phim.
/// - Mỗi hàng: tên thể loại lớn, slug + mã + số phim, pill trạng thái,
///   nút Ẩn/Hiện, Sửa, Xóa.
/// - Thêm/Sửa: dialog nhập tên → tự sinh slug, chọn hiển thị.
///   Xóa: xác nhận + dọn liên kết ở `movie_genres` để khỏi rác mồ côi.
class AdminGenresTab extends StatefulWidget {
  final VoidCallback? onDataChanged;

  const AdminGenresTab({super.key, this.onDataChanged});

  @override
  State<AdminGenresTab> createState() => _AdminGenresTabState();
}

class _AdminGenresTabState extends State<AdminGenresTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<_AdminGenreRow> _allRows = [];
  String _statusFilter = 'all'; // all | visible | hidden

  @override
  void initState() {
    super.initState();
    _loadGenres();
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

  /// Sinh slug latin từ tên tiếng Việt: "Hành Động" -> "hanh-dong".
  static String slugify(String input) {
    var s = input.trim().toLowerCase();
    const map = {
      'à': 'a', 'á': 'a', 'ạ': 'a', 'ả': 'a', 'ã': 'a',
      'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ậ': 'a', 'ẩ': 'a', 'ẫ': 'a',
      'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ặ': 'a', 'ẳ': 'a', 'ẵ': 'a',
      'è': 'e', 'é': 'e', 'ẹ': 'e', 'ẻ': 'e', 'ẽ': 'e',
      'ê': 'e', 'ề': 'e', 'ế': 'e', 'ệ': 'e', 'ể': 'e', 'ễ': 'e',
      'ì': 'i', 'í': 'i', 'ị': 'i', 'ỉ': 'i', 'ĩ': 'i',
      'ò': 'o', 'ó': 'o', 'ọ': 'o', 'ỏ': 'o', 'õ': 'o',
      'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ộ': 'o', 'ổ': 'o', 'ỗ': 'o',
      'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ợ': 'o', 'ở': 'o', 'ỡ': 'o',
      'ù': 'u', 'ú': 'u', 'ụ': 'u', 'ủ': 'u', 'ũ': 'u',
      'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ự': 'u', 'ử': 'u', 'ữ': 'u',
      'ỳ': 'y', 'ý': 'y', 'ỵ': 'y', 'ỷ': 'y', 'ỹ': 'y',
      'đ': 'd',
    };
    final buf = StringBuffer();
    for (final ch in s.split('')) {
      buf.write(map[ch] ?? ch);
    }
    s = buf.toString();
    s = s.replaceAll(RegExp(r'[^a-z0-9\s-]'), '');
    s = s.replaceAll(RegExp(r'[\s_]+'), '-');
    s = s.replaceAll(RegExp(r'-+'), '-');
    s = s.replaceAll(RegExp(r'^-|-$'), '');
    return s;
  }

  Future<void> _loadGenres() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _firestore.collection(CollectionNames.genres).get(),
        _firestore.collection('movie_genres').get(),
      ]);
      final genresSnap = results[0];
      final linksSnap = results[1];

      final countByGenre = <int, int>{};
      for (final doc in linksSnap.docs) {
        final d = doc.data();
        final gId = _parseInt(d['genre_id'] ?? d['genreId']);
        if (gId > 0) countByGenre[gId] = (countByGenre[gId] ?? 0) + 1;
      }

      final rows = <_AdminGenreRow>[];
      for (final doc in genresSnap.docs) {
        try {
          final g = Genre.fromJson(doc.data(), docId: doc.id);
          if (g.name.trim().isEmpty) continue;
          rows.add(_AdminGenreRow(
            docId: doc.id,
            genre: g,
            movieCount: countByGenre[g.id] ?? 0,
          ));
        } catch (_) {}
      }

      rows.sort((a, b) {
        final cmp = b.movieCount.compareTo(a.movieCount);
        if (cmp != 0) return cmp;
        return a.genre.name.compareTo(b.genre.name);
      });

      if (!mounted) return;
      setState(() {
        _allRows = rows;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('AdminGenresTab load error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  int get _visibleCount => _allRows.where((r) => r.genre.isVisible).length;
  int get _hiddenCount => _allRows.length - _visibleCount;
  int get _totalLinks => _allRows.fold(0, (total, r) => total + r.movieCount);

  List<_AdminGenreRow> get _filteredRows {
    final q = _searchController.text.trim().toLowerCase();
    return _allRows.where((r) {
      if (_statusFilter == 'visible' && !r.genre.isVisible) return false;
      if (_statusFilter == 'hidden' && r.genre.isVisible) return false;
      if (q.isNotEmpty) {
        final name = r.genre.name.toLowerCase();
        final slug = r.genre.slug.toLowerCase();
        if (!name.contains(q) && !slug.contains(q) && '#${r.genre.id}' != q) return false;
      }
      return true;
    }).toList();
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

  int _nextGenreId() {
    var maxId = 0;
    for (final r in _allRows) {
      if (r.genre.id > maxId) maxId = r.genre.id;
    }
    return maxId + 1;
  }

  Future<void> _toggleVisible(_AdminGenreRow row) async {
    final next = !row.genre.isVisible;
    setState(() {
      final idx = _allRows.indexWhere((e) => e.docId == row.docId);
      if (idx != -1) {
        _allRows[idx] = _AdminGenreRow(
          docId: row.docId,
          genre: Genre(
            id: row.genre.id,
            name: row.genre.name,
            description: row.genre.description,
            slug: row.genre.slug,
            isVisible: next,
            createdAt: row.genre.createdAt,
            updatedAt: DateTime.now(),
          ),
          movieCount: row.movieCount,
        );
      }
    });
    try {
      final nowIso = DateTime.now().toIso8601String();
      await _firestore.collection(CollectionNames.genres).doc(row.docId).set({
        'isVisible': next,
        'is_visible': next ? 1 : 0,
        'updatedAt': nowIso,
        'updated_at': nowIso,
      }, SetOptions(merge: true));
      widget.onDataChanged?.call();
    } catch (e) {
      await _loadGenres();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cập nhật thất bại: $e'), backgroundColor: Colors.red[700]),
      );
    }
  }

  Future<void> _confirmDelete(_AdminGenreRow row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa thể loại'),
        content: Text(
          'Xóa "${row.genre.name}"? ${row.movieCount} liên kết phim sẽ bị gỡ. Hành động không thể hoàn tác.',
        ),
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
      // Dọn liên kết mồ côi trong movie_genres trước.
      final links = await _firestore
          .collection('movie_genres')
          .where('genre_id', isEqualTo: row.genre.id)
          .get();
      final batch = _firestore.batch();
      for (final d in links.docs) {
        batch.delete(d.reference);
      }
      final linksCamel = await _firestore
          .collection('movie_genres')
          .where('genreId', isEqualTo: row.genre.id)
          .get();
      for (final d in linksCamel.docs) {
        batch.delete(d.reference);
      }
      batch.delete(_firestore.collection(CollectionNames.genres).doc(row.docId));
      await batch.commit();

      if (!mounted) return;
      setState(() => _allRows.removeWhere((e) => e.docId == row.docId));
      widget.onDataChanged?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa thể loại "${row.genre.name}"'),
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
      await _loadGenres();
    }
  }

  /// Dialog thêm / sửa thể loại. [existing] null nghĩa là thêm mới.
  Future<void> _showGenreDialog({_AdminGenreRow? existing}) async {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.genre.name ?? '');
    final slugCtrl = TextEditingController(text: existing?.genre.slug ?? '');
    final descCtrl = TextEditingController(text: existing?.genre.description ?? '');
    bool isVisible = existing?.genre.isVisible ?? true;
    String? errorMsg;
    bool isSubmitting = false;
    bool slugTouched = isEdit;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Text(isEdit ? 'Sửa thể loại' : 'Thêm thể loại mới',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (errorMsg != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(errorMsg!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 12.5, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 10),
                  ],
                  TextField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Tên thể loại *',
                      hintText: 'VD: Hành động',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (v) {
                      if (!slugTouched) {
                        setDialogState(() => slugCtrl.text = slugify(v));
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: slugCtrl,
                    decoration: InputDecoration(
                      labelText: 'Slug *',
                      hintText: 'VD: hanh-dong',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (_) {
                      if (!slugTouched) setDialogState(() => slugTouched = true);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Mô tả (tùy chọn)',
                      hintText: 'VD: Phim hành động nghẹt thở...',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Hiển thị cho người dùng',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    value: isVisible,
                    activeThumbColor: const Color(0xFFFF3B4E),
                    onChanged: (v) => setDialogState(() => isVisible = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(ctx, false),
                  child: const Text('Hủy')),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF3B4E),
                  foregroundColor: Colors.white,
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        var slug = slugCtrl.text.trim().toLowerCase();
                        if (name.isEmpty) {
                          setDialogState(() => errorMsg = 'Vui lòng nhập tên thể loại');
                          return;
                        }
                        if (slug.isEmpty) slug = slugify(name);
                        if (slug.isEmpty) {
                          setDialogState(() => errorMsg = 'Slug không hợp lệ');
                          return;
                        }
                        final dup = _allRows.any((r) =>
                            r.genre.slug.toLowerCase() == slug &&
                            (existing == null || r.docId != existing.docId));
                        final dupName = _allRows.any((r) =>
                            r.genre.name.toLowerCase() == name.toLowerCase() &&
                            (existing == null || r.docId != existing.docId));
                        if (dup) {
                          setDialogState(() => errorMsg = 'Slug "$slug" đã tồn tại, đổi tên khác');
                          return;
                        }
                        if (dupName) {
                          setDialogState(() => errorMsg = 'Tên "$name" đã tồn tại');
                          return;
                        }

                        setDialogState(() {
                          isSubmitting = true;
                          errorMsg = null;
                        });

                        try {
                          final nowIso = DateTime.now().toIso8601String();
                          final editingRow = existing;
                          if (editingRow != null) {
                            await _firestore
                                .collection(CollectionNames.genres)
                                .doc(editingRow.docId)
                                .set({
                              'name': name,
                              'title': name,
                              'slug': slug,
                              'description': descCtrl.text.trim(),
                              'isVisible': isVisible,
                              'is_visible': isVisible ? 1 : 0,
                              'updatedAt': nowIso,
                              'updated_at': nowIso,
                            }, SetOptions(merge: true));
                          } else {
                            final nextId = _nextGenreId();
                            await _firestore
                                .collection(CollectionNames.genres)
                                .doc(nextId.toString())
                                .set({
                              'id': nextId,
                              'genre_id': nextId,
                              'name': name,
                              'title': name,
                              'slug': slug,
                              'description': descCtrl.text.trim(),
                              'isVisible': isVisible,
                              'is_visible': isVisible ? 1 : 0,
                              'createdAt': nowIso,
                              'created_at': nowIso,
                              'updatedAt': nowIso,
                              'updated_at': nowIso,
                            });
                          }
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        } catch (e) {
                          setDialogState(() {
                            isSubmitting = false;
                            errorMsg = 'Lưu thất bại: $e';
                          });
                        }
                      },
                icon: Icon(isEdit ? Icons.save_outlined : Icons.add_rounded, size: 17),
                label: Text(isEdit
                    ? (isSubmitting ? 'Đang lưu...' : 'Lưu thay đổi')
                    : (isSubmitting ? 'Đang thêm...' : 'Thêm thể loại')),
              ),
            ],
          );
        },
      ),
    );

    nameCtrl.dispose();
    slugCtrl.dispose();
    descCtrl.dispose();

    if (saved == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'Đã cập nhật thể loại' : 'Đã thêm thể loại mới'),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
      await _loadGenres();
      widget.onDataChanged?.call();
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quản lý thể loại',
                        style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: textPrimary)),
                    const SizedBox(height: 2),
                    Text('Thêm, đổi tên, ẩn/hiện — số phim đếm từ liên kết thật.',
                        style: TextStyle(fontSize: 12.5, color: textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 38,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF3B4E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: () => _showGenreDialog(),
                  icon: const Icon(Icons.add_rounded, size: 19),
                  label: const Text('Thêm', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Dải KPI chia ô bằng hairline.
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                _buildKpiCell('Thể loại', _formatNumber(_allRows.length), textPrimary, textSecondary, true, isDark),
                _buildKpiCell('Đang hiện', _formatNumber(_visibleCount), textPrimary, textSecondary, false, isDark),
                _buildKpiCell('Đang ẩn', _formatNumber(_hiddenCount), textPrimary, textSecondary, false, isDark),
                _buildKpiCell('Lượt gắn', _formatNumber(_totalLinks), textPrimary, textSecondary, false, isDark,
                    last: true),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tìm kiếm.
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
                hintText: 'Tìm tên thể loại, slug...',
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
                    onRefresh: _loadGenres,
                    child: rows.isEmpty
                        ? ListView(children: [
                            const SizedBox(height: 60),
                            Center(
                                child: Text('Chưa có thể loại nào khớp bộ lọc',
                                    style: TextStyle(color: textSecondary, fontSize: 13.5)))
                          ])
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            padding: const EdgeInsets.only(bottom: 20),
                            itemCount: rows.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, index) => _buildGenreCard(
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
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary)),
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

  Widget _buildGenreCard({
    required _AdminGenreRow row,
    required bool isDark,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
  }) {
    final g = row.genre;
    final visible = g.isVisible;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ô chữ cái đầu: nhận diện nhanh từng thể loại.
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2B191D) : const Color(0xFFFFECEE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              g.name.trim().isNotEmpty ? g.name.trim().substring(0, 1).toUpperCase() : '?',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFFE11D48)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(g.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: textPrimary)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: visible ? const Color(0xFFDCFCE7) : const Color(0xFFFFEDEA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(visible ? 'Đang hiện' : 'Đang ẩn',
                          style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: visible ? const Color(0xFF15803D) : const Color(0xFF831C1E))),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text('${g.slug.isEmpty ? '—' : g.slug} · #${g.id} · ${row.movieCount} phim',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            tooltip: 'Thao tác',
            padding: EdgeInsets.zero,
            icon: Icon(Icons.more_vert_rounded, size: 20, color: textSecondary),
            onSelected: (val) {
              if (val == 'toggle') _toggleVisible(row);
              if (val == 'edit') _showGenreDialog(existing: row);
              if (val == 'delete') _confirmDelete(row);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle',
                child: Row(children: [
                  Icon(visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 18, color: Colors.orange[800]),
                  const SizedBox(width: 8),
                  Text(visible ? 'Ẩn thể loại' : 'Hiện thể loại'),
                ]),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(children: [
                  Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Sửa tên / slug'),
                ]),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text('Xóa', style: TextStyle(color: Colors.redAccent)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminGenreRow {
  final String docId;
  final Genre genre;
  final int movieCount;

  const _AdminGenreRow({required this.docId, required this.genre, required this.movieCount});
}
