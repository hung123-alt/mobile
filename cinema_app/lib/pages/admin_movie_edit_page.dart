import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../core/firebase/collection_names.dart';
import '../widgets/admin_bottom_bar.dart';
import '../widgets/admin_top_navbar.dart';

/// Trang Chỉnh sửa phim / Thêm phim mới dành cho Admin (theo wireframe).
///
/// Tái sử dụng [AdminTopNavbar] và [AdminBottomBar].
/// Kết nối trực tiếp với các bảng `movies`, `genres`, `movie_genres`,
/// `countries`, `movie_countries`, và `episodes` trên Firestore.
class AdminMovieEditPage extends StatefulWidget {
  final String? movieDocId;
  final Map<String, dynamic>? initialMovieData;

  const AdminMovieEditPage({
    super.key,
    this.movieDocId,
    this.initialMovieData,
  });

  bool get isEditing => movieDocId != null || initialMovieData != null;

  @override
  State<AdminMovieEditPage> createState() => _AdminMovieEditPageState();
}

class _AdminMovieEditPageState extends State<AdminMovieEditPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late final TextEditingController _titleController;
  late final TextEditingController _totalEpisodesController;
  late String _description;
  late String _posterUrl;
  late String _bannerUrl;
  late String _selectedType; // phim_bo | phim_le | hoat_hinh | anime
  late String _selectedStatus; // ongoing | completed | upcoming
  late int _selectedYear;
  late bool _isVisible;
  late bool _isFeatured;

  int? _movieId;
  String? _docId;

  // Danh sách thể loại & quốc gia tải động từ DB
  List<_SimpleItem> _allGenres = [];
  List<_SimpleItem> _selectedGenres = [];

  List<_SimpleItem> _allCountries = [];
  _SimpleItem? _selectedCountry;

  // Danh sách tập phim của phim này
  List<_EditableEpisode> _episodes = [];
  final List<String> _deletedEpisodeDocIds = [];

  bool _isLoadingMeta = true;
  bool _isSaving = false;

  static const Map<String, String> _movieTypeLabels = {
    'phim_bo': 'Phim bộ',
    'phim_le': 'Phim lẻ',
    'hoat_hinh': 'Hoạt hình',
    'anime': 'Anime',
  };

  static const Map<String, String> _statusLabels = {
    'ongoing': 'Đang chiếu',
    'completed': 'Hoàn thành',
    'upcoming': 'Sắp chiếu',
  };

  @override
  void initState() {
    super.initState();
    final data = widget.initialMovieData ?? {};
    _docId = widget.movieDocId;
    _movieId = _parseInt(data['id'], 0);

    final rawTitle = (data['title'] ?? data['name'] ?? '').toString();
    final rawTotalEp = _parseInt(
      data['totalEpisodes'] ?? data['total_episodes'],
      1,
    );

    _titleController = TextEditingController(text: rawTitle);
    _totalEpisodesController = TextEditingController(
      text: rawTotalEp > 0 ? rawTotalEp.toString() : '1',
    );
    _description = (data['description'] ?? '').toString();
    _posterUrl = (data['posterUrl'] ?? data['poster_url'] ?? '').toString();
    _bannerUrl = (data['bannerUrl'] ?? data['banner_url'] ?? '').toString();

    final rawType = (data['type'] ?? 'phim_bo').toString();
    _selectedType =
        _movieTypeLabels.containsKey(rawType) ? rawType : 'phim_bo';

    final rawStatus = (data['status'] ?? 'ongoing').toString();
    _selectedStatus =
        _statusLabels.containsKey(rawStatus) ? rawStatus : 'ongoing';

    final currentYear = DateTime.now().year;
    final rawYear = _parseInt(
      data['releaseYear'] ?? data['release_year'],
      currentYear,
    );
    _selectedYear =
        (rawYear >= 1980 && rawYear <= currentYear + 2) ? rawYear : currentYear;

    _isVisible = data['isVisible'] == true ||
        data['is_visible'] == 1 ||
        data['isVisible'] == null;
    _isFeatured = data['isFeatured'] == true || data['is_featured'] == 1;

    _loadInitialMetadata();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _totalEpisodesController.dispose();
    super.dispose();
  }

  int _parseInt(dynamic val, [int fallback = 0]) {
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? fallback;
    return fallback;
  }

  String? _resolveDisplayImageUrl() {
    String? raw;
    if (_posterUrl.trim().isNotEmpty && _posterUrl != '{}') {
      raw = _posterUrl.trim();
    } else if (_bannerUrl.trim().isNotEmpty && _bannerUrl != '{}') {
      raw = _bannerUrl.trim();
    }
    if (raw == null) return null;
    if (kIsWeb && raw.startsWith('http')) {
      return 'https://wsrv.nl/?url=${Uri.encodeComponent(raw)}';
    }
    return raw;
  }

  String _slugify(String input) {
    var str = input.toLowerCase().trim();
    const vietnameseMap = {
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
    vietnameseMap.forEach((k, v) {
      str = str.replaceAll(k, v);
    });
    str = str.replaceAll(RegExp(r'[^a-z0-9\s-]'), '');
    str = str.replaceAll(RegExp(r'\s+'), '-');
    str = str.replaceAll(RegExp(r'-+'), '-');
    return str.isEmpty
        ? 'phim-${DateTime.now().millisecondsSinceEpoch}'
        : str;
  }

  Future<void> _loadInitialMetadata() async {
    setState(() => _isLoadingMeta = true);

    try {
      final futures = <Future<QuerySnapshot<Map<String, dynamic>>>>[
        _firestore.collection(CollectionNames.genres).get(),
        _firestore.collection(CollectionNames.countries).get(),
      ];

      final results = await Future.wait(futures);
      final genresSnap = results[0];
      final countriesSnap = results[1];

      final genresList = <_SimpleItem>[];
      for (final doc in genresSnap.docs) {
        final d = doc.data();
        final id = _parseInt(d['id'] ?? doc.id, 0);
        final name = (d['name'] ?? '').toString().trim();
        if (id > 0 && name.isNotEmpty) {
          genresList.add(_SimpleItem(id: id, name: name));
        }
      }
      genresList.sort((a, b) => a.name.compareTo(b.name));

      final countriesList = <_SimpleItem>[];
      for (final doc in countriesSnap.docs) {
        final d = doc.data();
        final id = _parseInt(d['id'] ?? doc.id, 0);
        final name = (d['name'] ?? '').toString().trim();
        if (id > 0 && name.isNotEmpty) {
          countriesList.add(_SimpleItem(id: id, name: name));
        }
      }
      countriesList.sort((a, b) => a.name.compareTo(b.name));

      final selectedG = <_SimpleItem>[];
      _SimpleItem? selectedC;
      final loadedEpisodes = <_EditableEpisode>[];

      if (_movieId != null && _movieId! > 0) {
        // Tải thể loại của phim từ `movie_genres`
        final mgSnap = await _firestore
            .collection('movie_genres')
            .where('movie_id', isEqualTo: _movieId)
            .get();
        final genreIds = mgSnap.docs
            .map((doc) => _parseInt(doc.data()['genre_id'], 0))
            .where((id) => id > 0)
            .toSet();

        for (final g in genresList) {
          if (genreIds.contains(g.id)) {
            selectedG.add(g);
          }
        }

        // Tải quốc gia của phim từ `movie_countries`
        final mcSnap = await _firestore
            .collection('movie_countries')
            .where('movie_id', isEqualTo: _movieId)
            .get();
        if (mcSnap.docs.isNotEmpty) {
          final cId = _parseInt(mcSnap.docs.first.data()['country_id'], 0);
          for (final c in countriesList) {
            if (c.id == cId) {
              selectedC = c;
              break;
            }
          }
        }

        // Tải danh sách tập phim từ `episodes`
        var epSnap = await _firestore
            .collection(CollectionNames.episodes)
            .where('movie_id', isEqualTo: _movieId)
            .get();
        if (epSnap.docs.isEmpty) {
          epSnap = await _firestore
              .collection(CollectionNames.episodes)
              .where('movieId', isEqualTo: _movieId)
              .get();
        }

        for (final doc in epSnap.docs) {
          final d = doc.data();
          final epNum = _parseInt(d['episodeNumber'] ?? d['episode_number'], 1);
          final title = (d['title'] ?? d['name'] ?? 'Tập $epNum').toString();
          final embedUrl = (d['embedUrl'] ?? d['embed_url'] ?? '').toString();
          final serverName =
              (d['serverName'] ?? d['server_name'] ?? 'Vietsub').toString();
          final durationSec = _parseInt(
            d['durationSeconds'] ?? d['duration_seconds'],
            0,
          );
          loadedEpisodes.add(
            _EditableEpisode(
              docId: doc.id,
              id: _parseInt(d['id'], 0),
              episodeNumber: epNum,
              title: title,
              embedUrl: embedUrl,
              serverName: serverName,
              durationSeconds: durationSec,
            ),
          );
        }
        loadedEpisodes.sort(
          (a, b) => a.episodeNumber.compareTo(b.episodeNumber),
        );
      }

      if (selectedC == null && countriesList.isNotEmpty) {
        selectedC = countriesList.first;
      }

      if (!mounted) return;
      setState(() {
        _allGenres = genresList;
        _selectedGenres = selectedG;
        _allCountries = countriesList;
        _selectedCountry = selectedC;
        _episodes = loadedEpisodes;
        _isLoadingMeta = false;
      });
    } catch (e) {
      debugPrint('Load movie metadata error: $e');
      if (!mounted) return;
      setState(() => _isLoadingMeta = false);
    }
  }

  /// Hộp thoại đổi URL ảnh Poster / Banner
  Future<void> _showChangeImageDialog() async {
    final posterCtrl = TextEditingController(text: _posterUrl);
    final bannerCtrl = TextEditingController(text: _bannerUrl);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Đổi ảnh Poster / Banner',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'URL Ảnh Poster (dọc)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: posterCtrl,
                decoration: InputDecoration(
                  hintText: 'https://example.com/poster.jpg',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'URL Ảnh Banner (ngang - tuỳ chọn)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: bannerCtrl,
                decoration: InputDecoration(
                  hintText: 'https://example.com/banner.jpg',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B4E),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Áp dụng'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _posterUrl = posterCtrl.text.trim();
        _bannerUrl = bannerCtrl.text.trim().isNotEmpty
            ? bannerCtrl.text.trim()
            : _posterUrl;
      });
    }
  }

  /// Hộp thoại chọn nhiều thể loại từ danh sách `genres` trên DB
  Future<void> _showGenrePickerDialog() async {
    final tempSelectedIds = _selectedGenres.map((e) => e.id).toSet();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Chọn thể loại phim',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF3B4E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Xong'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.45,
                      ),
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _allGenres.map((genre) {
                            final isSelected =
                                tempSelectedIds.contains(genre.id);
                            return FilterChip(
                              label: Text(genre.name),
                              selected: isSelected,
                              selectedColor: const Color(0xFFFF3B4E)
                                  .withValues(alpha: 0.16),
                              checkmarkColor: const Color(0xFFFF3B4E),
                              labelStyle: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? const Color(0xFFE0314B)
                                    : null,
                              ),
                              onSelected: (val) {
                                setModalState(() {
                                  if (val) {
                                    tempSelectedIds.add(genre.id);
                                  } else {
                                    tempSelectedIds.remove(genre.id);
                                  }
                                });
                                setState(() {
                                  _selectedGenres = _allGenres
                                      .where(
                                        (g) => tempSelectedIds.contains(g.id),
                                      )
                                      .toList();
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Hộp thoại Thêm / Sửa tập phim
  Future<void> _showEpisodeDialog({_EditableEpisode? existing, int? index}) async {
    final nextEpNum = existing?.episodeNumber ?? (_episodes.length + 1);
    final epNumCtrl = TextEditingController(text: nextEpNum.toString());
    final titleCtrl = TextEditingController(
      text: existing?.title ?? '$nextEpNum',
    );
    final embedUrlCtrl = TextEditingController(text: existing?.embedUrl ?? '');
    final serverCtrl = TextEditingController(
      text: existing?.serverName ?? 'Vietsub',
    );
    final durationCtrl = TextEditingController(
      text: existing != null && existing.durationSeconds > 0
          ? existing.formattedDuration
          : '',
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          existing == null ? 'Thêm tập phim mới' : 'Chỉnh sửa tập phim',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: epNumCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Số tập *',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nhãn tập (VD: 1, Full)',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: embedUrlCtrl,
                decoration: InputDecoration(
                  labelText: 'Link phát phim (embedUrl) *',
                  hintText: 'https://...',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: serverCtrl,
                      decoration: InputDecoration(
                        labelText: 'Server',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: durationCtrl,
                      decoration: InputDecoration(
                        labelText: 'Thời lượng (phút:giây)',
                        hintText: '45:20',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B4E),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lưu tập'),
          ),
        ],
      ),
    );

    if (saved == true) {
      final epNum = int.tryParse(epNumCtrl.text.trim()) ?? nextEpNum;
      final epTitle = titleCtrl.text.trim().isNotEmpty
          ? titleCtrl.text.trim()
          : epNum.toString();
      final durationSec = _parseDurationInput(durationCtrl.text.trim());

      final updatedEp = _EditableEpisode(
        docId: existing?.docId,
        id: existing?.id ?? 0,
        episodeNumber: epNum,
        title: epTitle,
        embedUrl: embedUrlCtrl.text.trim(),
        serverName: serverCtrl.text.trim().isNotEmpty
            ? serverCtrl.text.trim()
            : 'Vietsub',
        durationSeconds: durationSec,
      );

      setState(() {
        if (index != null) {
          _episodes[index] = updatedEp;
        } else {
          _episodes.add(updatedEp);
        }
        _episodes.sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));
      });
    }
  }

  int _parseDurationInput(String raw) {
    if (raw.isEmpty) return 0;
    if (raw.contains(':')) {
      final parts = raw.split(':');
      final m = int.tryParse(parts[0].trim()) ?? 0;
      final s = parts.length > 1 ? (int.tryParse(parts[1].trim()) ?? 0) : 0;
      return m * 60 + s;
    }
    return (int.tryParse(raw) ?? 0) * 60;
  }

  /// Hộp thoại sửa mô tả phim (từ menu 3 chấm)
  Future<void> _showEditDescriptionDialog() async {
    final descCtrl = TextEditingController(text: _description);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Mô tả nội dung phim',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: descCtrl,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Nhập nội dung tóm tắt phim...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B4E),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );

    if (saved == true) {
      setState(() => _description = descCtrl.text.trim());
    }
  }

  /// Xóa phim hiện tại khỏi Firestore
  Future<void> _confirmAndDeleteMovie() async {
    if (!widget.isEditing) {
      Navigator.pop(context);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa phim'),
        content: Text(
          'Bạn có chắc chắn muốn xóa phim "${_titleController.text.trim()}" cùng toàn bộ tập phim liên quan không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B4E),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa vĩnh viễn'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _isSaving = true);

    try {
      if (_docId != null) {
        await _firestore
            .collection(CollectionNames.movies)
            .doc(_docId)
            .delete();
      }
      if (_movieId != null && _movieId! > 0) {
        final mgSnap = await _firestore
            .collection('movie_genres')
            .where('movie_id', isEqualTo: _movieId)
            .get();
        for (final doc in mgSnap.docs) {
          await doc.reference.delete();
        }
        final mcSnap = await _firestore
            .collection('movie_countries')
            .where('movie_id', isEqualTo: _movieId)
            .get();
        for (final doc in mcSnap.docs) {
          await doc.reference.delete();
        }
        final epSnap = await _firestore
            .collection(CollectionNames.episodes)
            .where('movie_id', isEqualTo: _movieId)
            .get();
        for (final doc in epSnap.docs) {
          await doc.reference.delete();
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã xóa phim thành công!'),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi xóa phim: $e'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Lưu thay đổi (hoặc tạo mới phim) vào Firestore
  Future<void> _saveChanges() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng nhập Tên phim!'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final totalEp = int.tryParse(_totalEpisodesController.text.trim()) ?? 1;
    setState(() => _isSaving = true);

    try {
      final nowIso = DateTime.now().toIso8601String();
      int targetMovieId = _movieId ?? 0;

      if (targetMovieId <= 0) {
        final allMoviesSnap =
            await _firestore.collection(CollectionNames.movies).get();
        int maxId = 0;
        for (final doc in allMoviesSnap.docs) {
          final id = _parseInt(doc.data()['id'] ?? doc.id, 0);
          if (id > maxId) maxId = id;
        }
        targetMovieId = maxId + 1;
        _movieId = targetMovieId;
      }

      final targetDocId = _docId ?? targetMovieId.toString();
      final existingData = widget.initialMovieData ?? {};
      final slug = (existingData['slug'] != null &&
              existingData['slug'].toString().trim().isNotEmpty)
          ? existingData['slug'].toString()
          : _slugify(title);

      final moviePayload = <String, dynamic>{
        'id': targetMovieId,
        'title': title,
        'name': title,
        'slug': slug,
        'description': _description,
        'posterUrl': _posterUrl.isNotEmpty ? _posterUrl : null,
        'poster_url': _posterUrl.isNotEmpty ? _posterUrl : null,
        'bannerUrl': _bannerUrl.isNotEmpty
            ? _bannerUrl
            : (_posterUrl.isNotEmpty ? _posterUrl : null),
        'banner_url': _bannerUrl.isNotEmpty
            ? _bannerUrl
            : (_posterUrl.isNotEmpty ? _posterUrl : null),
        'type': _selectedType,
        'status': _selectedStatus,
        'releaseYear': _selectedYear,
        'release_year': _selectedYear,
        'totalEpisodes': totalEp,
        'total_episodes': totalEp,
        'isVisible': _isVisible,
        'is_visible': _isVisible ? 1 : 0,
        'isFeatured': _isFeatured,
        'is_featured': _isFeatured ? 1 : 0,
        'viewCount': _parseInt(
          existingData['viewCount'] ?? existingData['view_count'],
          0,
        ),
        'view_count': _parseInt(
          existingData['viewCount'] ?? existingData['view_count'],
          0,
        ),
        'avgRating': existingData['avgRating'] ?? existingData['avg_rating'] ?? 8.0,
        'avg_rating': existingData['avgRating'] ?? existingData['avg_rating'] ?? 8.0,
        'ratingCount': _parseInt(
          existingData['ratingCount'] ?? existingData['rating_count'],
          0,
        ),
        'rating_count': _parseInt(
          existingData['ratingCount'] ?? existingData['rating_count'],
          0,
        ),
        'updatedAt': nowIso,
        'updated_at': nowIso,
        if (!widget.isEditing) ...{
          'createdAt': nowIso,
          'created_at': nowIso,
        },
      };

      await _firestore
          .collection(CollectionNames.movies)
          .doc(targetDocId)
          .set(moviePayload, SetOptions(merge: true));

      // Đồng bộ `movie_genres`
      final oldMg = await _firestore
          .collection('movie_genres')
          .where('movie_id', isEqualTo: targetMovieId)
          .get();
      for (final doc in oldMg.docs) {
        await doc.reference.delete();
      }
      for (final g in _selectedGenres) {
        await _firestore
            .collection('movie_genres')
            .doc('${targetMovieId}_${g.id}')
            .set({
          'movie_id': targetMovieId,
          'genre_id': g.id,
        });
      }

      // Đồng bộ `movie_countries`
      final oldMc = await _firestore
          .collection('movie_countries')
          .where('movie_id', isEqualTo: targetMovieId)
          .get();
      for (final doc in oldMc.docs) {
        await doc.reference.delete();
      }
      if (_selectedCountry != null) {
        await _firestore
            .collection('movie_countries')
            .doc('${targetMovieId}_${_selectedCountry!.id}')
            .set({
          'movie_id': targetMovieId,
          'country_id': _selectedCountry!.id,
        });
      }

      // Xóa các tập đã đánh dấu xóa
      for (final delDocId in _deletedEpisodeDocIds) {
        await _firestore
            .collection(CollectionNames.episodes)
            .doc(delDocId)
            .delete();
      }

      // Lưu / cập nhật các tập phim trong `_episodes`
      for (final ep in _episodes) {
        final epDocId =
            ep.docId ?? '${targetMovieId}_${ep.episodeNumber}';
        final epId = ep.id > 0
            ? ep.id
            : (targetMovieId * 1000 + ep.episodeNumber);
        await _firestore
            .collection(CollectionNames.episodes)
            .doc(epDocId)
            .set({
          'id': epId,
          'movie_id': targetMovieId,
          'movieId': targetMovieId,
          'episode_number': ep.episodeNumber,
          'episodeNumber': ep.episodeNumber,
          'name': ep.title,
          'title': ep.title,
          'embed_url': ep.embedUrl,
          'embedUrl': ep.embedUrl,
          'server_name': ep.serverName,
          'serverName': ep.serverName,
          'duration_seconds': ep.durationSeconds,
          'durationSeconds': ep.durationSeconds,
          'skip_intro_seconds': 0,
          'skipIntroSeconds': 0,
          'updatedAt': nowIso,
          'updated_at': nowIso,
        }, SetOptions(merge: true));
      }

      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Đã lưu thay đổi phim "$title" thành công!'
                : 'Đã thêm phim mới "$title" thành công!',
          ),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Save movie error: $e');
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lưu phim thất bại: $e'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final textSecondary =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563);
    final borderColor =
        isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB);

    final currentYear = DateTime.now().year;
    final yearOptions = List<int>.generate(
      45,
      (idx) => (currentYear + 1) - idx,
    );
    if (!yearOptions.contains(_selectedYear)) {
      yearOptions.add(_selectedYear);
      yearOptions.sort((a, b) => b.compareTo(a));
    }

    final displayPoster = _resolveDisplayImageUrl();

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FB),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Navbar Admin tái sử dụng (có nút Back <- ở bên trái)
            const AdminTopNavbar(showBackIfCanPop: true),

            // 2. Nội dung form Chỉnh sửa / Thêm phim
            Expanded(
              child: _isLoadingMeta
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF3B4E),
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tiêu đề + Menu 3 chấm (⋮)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                widget.isEditing
                                    ? 'Chỉnh sửa phim'
                                    : 'Thêm phim mới',
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert_rounded,
                                  color: textPrimary,
                                ),
                                onSelected: (val) {
                                  if (val == 'desc') {
                                    _showEditDescriptionDialog();
                                  } else if (val == 'visibility') {
                                    setState(() => _isVisible = !_isVisible);
                                  } else if (val == 'featured') {
                                    setState(() => _isFeatured = !_isFeatured);
                                  } else if (val == 'delete') {
                                    _confirmAndDeleteMovie();
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(
                                    value: 'desc',
                                    child: Row(
                                      children: [
                                        Icon(Icons.description_outlined, size: 19),
                                        SizedBox(width: 10),
                                        Text('Sửa mô tả phim'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'visibility',
                                    child: Row(
                                      children: [
                                        Icon(
                                          _isVisible
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          size: 19,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          _isVisible
                                              ? 'Ẩn phim khỏi trang chủ'
                                              : 'Hiển thị phim',
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'featured',
                                    child: Row(
                                      children: [
                                        Icon(
                                          _isFeatured
                                              ? Icons.star_outline_rounded
                                              : Icons.star_rounded,
                                          size: 19,
                                          color: Colors.amber[700],
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          _isFeatured
                                              ? 'Bỏ đánh dấu Nổi bật'
                                              : 'Đặt làm Phim nổi bật',
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (widget.isEditing)
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete_outline_rounded,
                                            size: 19,
                                            color: Color(0xFFFF3B4E),
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            'Xóa phim này',
                                            style: TextStyle(
                                              color: Color(0xFFFF3B4E),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Khối Poster bên trái + Các trường Tên phim, Loại phim, Số tập, Thể loại bên phải
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Poster + Nút "Đổi ảnh"
                              GestureDetector(
                                onTap: _showChangeImageDialog,
                                child: Container(
                                  width: 118,
                                  height: 178,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF262626)
                                        : const Color(0xFFE5E7EB),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      if (displayPoster != null)
                                        Image.network(
                                          displayPoster,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => const Icon(
                                            Icons.movie_outlined,
                                            size: 40,
                                            color: Color(0xFF9CA3AF),
                                          ),
                                        )
                                      else
                                        const Icon(
                                          Icons.add_photo_alternate_outlined,
                                          size: 38,
                                          color: Color(0xFF9CA3AF),
                                        ),
                                      // Overlay nút Đổi ảnh ở dưới cùng
                                      Align(
                                        alignment: Alignment.bottomCenter,
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 7,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.black
                                                    .withValues(alpha: 0.1),
                                                Colors.black
                                                    .withValues(alpha: 0.78),
                                              ],
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.smart_display_outlined,
                                                color: Colors.white,
                                                size: 15,
                                              ),
                                              SizedBox(width: 5),
                                              Text(
                                                'Đổi ảnh',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Cột bên phải: Tên phim *, Loại phim + Số tập *, Thể loại *
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildRequiredLabel(
                                      'Tên phim',
                                      isRequired: true,
                                      textSecondary: textSecondary,
                                    ),
                                    const SizedBox(height: 4),
                                    _buildInputBox(
                                      controller: _titleController,
                                      hintText: 'Nhập tên phim...',
                                      cardBg: cardBg,
                                      borderColor: borderColor,
                                      textPrimary: textPrimary,
                                    ),
                                    const SizedBox(height: 10),

                                    // Hàng Loại phim + Số tập *
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 58,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _buildRequiredLabel(
                                                'Loại phim',
                                                isRequired: false,
                                                textSecondary: textSecondary,
                                              ),
                                              const SizedBox(height: 4),
                                              Container(
                                                height: 40,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: cardBg,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: borderColor,
                                                  ),
                                                ),
                                                child:
                                                    DropdownButtonHideUnderline(
                                                  child: DropdownButton<String>(
                                                    value: _selectedType,
                                                    isExpanded: true,
                                                    icon: Icon(
                                                      Icons
                                                          .keyboard_arrow_down_rounded,
                                                      size: 19,
                                                      color: textSecondary,
                                                    ),
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: textPrimary,
                                                    ),
                                                    dropdownColor: cardBg,
                                                    items: _movieTypeLabels
                                                        .entries
                                                        .map(
                                                          (e) =>
                                                              DropdownMenuItem(
                                                            value: e.key,
                                                            child: Text(
                                                              e.value,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                        )
                                                        .toList(),
                                                    onChanged: (val) {
                                                      if (val != null) {
                                                        setState(() {
                                                          _selectedType = val;
                                                        });
                                                      }
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          flex: 42,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _buildRequiredLabel(
                                                'Số tập',
                                                isRequired: true,
                                                textSecondary: textSecondary,
                                              ),
                                              const SizedBox(height: 4),
                                              _buildInputBox(
                                                controller:
                                                    _totalEpisodesController,
                                                hintText: '16',
                                                keyboardType:
                                                    TextInputType.number,
                                                cardBg: cardBg,
                                                borderColor: borderColor,
                                                textPrimary: textPrimary,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // Thể loại *
                                    _buildRequiredLabel(
                                      'Thể loại',
                                      isRequired: true,
                                      textSecondary: textSecondary,
                                    ),
                                    const SizedBox(height: 4),
                                    GestureDetector(
                                      onTap: _showGenrePickerDialog,
                                      child: Container(
                                        constraints: const BoxConstraints(
                                          minHeight: 40,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: cardBg,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border:
                                              Border.all(color: borderColor),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: _selectedGenres.isEmpty
                                                  ? Text(
                                                      'Chọn thể loại...',
                                                      style: TextStyle(
                                                        fontSize: 12.5,
                                                        color: textSecondary,
                                                      ),
                                                    )
                                                  : Wrap(
                                                      spacing: 6,
                                                      runSpacing: 5,
                                                      children: _selectedGenres
                                                          .map((g) {
                                                        return Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            horizontal: 8,
                                                            vertical: 3,
                                                          ),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: const Color(
                                                              0xFFFFE4E6,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                              14,
                                                            ),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              GestureDetector(
                                                                onTap: () {
                                                                  setState(() {
                                                                    _selectedGenres
                                                                        .removeWhere(
                                                                      (item) =>
                                                                          item.id ==
                                                                          g.id,
                                                                    );
                                                                  });
                                                                },
                                                                child:
                                                                    const Text(
                                                                  '× ',
                                                                  style: TextStyle(
                                                                    color: Color(
                                                                      0xFFE11D48,
                                                                    ),
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        12,
                                                                  ),
                                                                ),
                                                              ),
                                                              Text(
                                                                g.name,
                                                                style:
                                                                    const TextStyle(
                                                                  color: Color(
                                                                    0xFFE11D48,
                                                                  ),
                                                                  fontSize:
                                                                      11.5,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      }).toList(),
                                                    ),
                                            ),
                                            Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              size: 19,
                                              color: textSecondary,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Hàng Quốc gia + Năm phát hành
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildRequiredLabel(
                                      'Quốc gia',
                                      isRequired: false,
                                      textSecondary: textSecondary,
                                    ),
                                    const SizedBox(height: 5),
                                    Container(
                                      height: 42,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: cardBg,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: borderColor),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<_SimpleItem>(
                                          value: _selectedCountry,
                                          isExpanded: true,
                                          hint: Text(
                                            'Chọn quốc gia',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: textSecondary,
                                            ),
                                          ),
                                          icon: Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            size: 20,
                                            color: textSecondary,
                                          ),
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w500,
                                            color: textPrimary,
                                          ),
                                          dropdownColor: cardBg,
                                          items: _allCountries
                                              .map(
                                                (c) => DropdownMenuItem(
                                                  value: c,
                                                  child: Text(
                                                    c.name,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (val) {
                                            setState(
                                              () => _selectedCountry = val,
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildRequiredLabel(
                                      'Năm phát hành',
                                      isRequired: false,
                                      textSecondary: textSecondary,
                                    ),
                                    const SizedBox(height: 5),
                                    Container(
                                      height: 42,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: cardBg,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: borderColor),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<int>(
                                          value: _selectedYear,
                                          isExpanded: true,
                                          icon: Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            size: 20,
                                            color: textSecondary,
                                          ),
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w500,
                                            color: textPrimary,
                                          ),
                                          dropdownColor: cardBg,
                                          items: yearOptions
                                              .map(
                                                (y) => DropdownMenuItem(
                                                  value: y,
                                                  child: Text(y.toString()),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(
                                                () => _selectedYear = val,
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Hàng Trạng thái (label bên trái + dropdown bên phải như hình)
                          Row(
                            children: [
                              SizedBox(
                                width: 88,
                                child: Text(
                                  'Trạng thái',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: textSecondary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 42,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedStatus,
                                      isExpanded: true,
                                      icon: Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 20,
                                        color: textSecondary,
                                      ),
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500,
                                        color: textPrimary,
                                      ),
                                      dropdownColor: cardBg,
                                      items: _statusLabels.entries.map((entry) {
                                        final dotColor = entry.key == 'ongoing'
                                            ? const Color(0xFF16A34A)
                                            : (entry.key == 'completed'
                                                ? const Color(0xFF2563EB)
                                                : const Color(0xFFD97706));
                                        return DropdownMenuItem<String>(
                                          value: entry.key,
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 9,
                                                height: 9,
                                                decoration: BoxDecoration(
                                                  color: dotColor,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(entry.value),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => _selectedStatus = val);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Phần Quản lý tập phim (X) + nút "+ Thêm tập"
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Quản lý tập phim (${_episodes.length})',
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _showEpisodeDialog(),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.add_rounded,
                                      size: 20,
                                      color: Color(0xFFE11D48),
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      'Thêm tập',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFE11D48),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Danh sách các tập phim
                          Container(
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: borderColor),
                            ),
                            child: _episodes.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(18),
                                    child: Center(
                                      child: Text(
                                        'Chưa có tập phim nào. Bấm "+ Thêm tập" để thêm.',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: textSecondary,
                                        ),
                                      ),
                                    ),
                                  )
                                : Column(
                                    children: List.generate(
                                      _episodes.length,
                                      (index) {
                                        final ep = _episodes[index];
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 11,
                                          ),
                                          decoration: BoxDecoration(
                                            border: index > 0
                                                ? Border(
                                                    top: BorderSide(
                                                      color: borderColor
                                                          .withValues(
                                                        alpha: 0.6,
                                                      ),
                                                    ),
                                                  )
                                                : null,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.play_arrow_rounded,
                                                size: 22,
                                                color: textSecondary,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  ep.displayLabel,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: textPrimary,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                ep.durationSeconds > 0
                                                    ? ep.formattedDuration
                                                    : ep.serverName,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: textSecondary,
                                                ),
                                              ),
                                              const SizedBox(width: 14),
                                              GestureDetector(
                                                onTap: () => _showEpisodeDialog(
                                                  existing: ep,
                                                  index: index,
                                                ),
                                                child: Icon(
                                                  Icons.edit_outlined,
                                                  size: 19,
                                                  color: textSecondary,
                                                ),
                                              ),
                                              const SizedBox(width: 14),
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    if (ep.docId != null) {
                                                      _deletedEpisodeDocIds
                                                          .add(ep.docId!);
                                                    }
                                                    _episodes.removeAt(index);
                                                  });
                                                },
                                                child: const Icon(
                                                  Icons.delete_outline_rounded,
                                                  size: 20,
                                                  color: Color(0xFFE11D48),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 22),

                          // Nút Lưu thay đổi
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF3B4E),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _isSaving ? null : _saveChanges,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined, size: 20),
                              label: Text(
                                _isSaving ? 'Đang lưu...' : 'Lưu thay đổi',
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AdminBottomBar(currentIndex: 1),
    );
  }

  Widget _buildRequiredLabel(
    String label, {
    required bool isRequired,
    required Color textSecondary,
  }) {
    return RichText(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: textSecondary,
        ),
        children: [
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(
                color: Color(0xFFE11D48),
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputBox({
    required TextEditingController controller,
    required String hintText,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          filled: true,
          fillColor: cardBg,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFFF3B4E), width: 1.4),
          ),
        ),
      ),
    );
  }
}

class _SimpleItem {
  final int id;
  final String name;

  const _SimpleItem({required this.id, required this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is _SimpleItem && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

class _EditableEpisode {
  final String? docId;
  final int id;
  final int episodeNumber;
  final String title;
  final String embedUrl;
  final String serverName;
  final int durationSeconds;

  const _EditableEpisode({
    required this.docId,
    required this.id,
    required this.episodeNumber,
    required this.title,
    required this.embedUrl,
    required this.serverName,
    required this.durationSeconds,
  });

  String get displayLabel {
    final t = title.trim();
    if (t.isEmpty) return 'Tập $episodeNumber';
    if (t.toLowerCase().startsWith('tập')) return t;
    return 'Tập $t';
  }

  String get formattedDuration {
    final m = durationSeconds ~/ 60;
    final s = (durationSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

