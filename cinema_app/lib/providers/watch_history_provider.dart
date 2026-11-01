import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/firebase/collection_names.dart';
import '../models/episode_model.dart';
import '../models/movie_model.dart';
import 'auth_provider.dart';

class WatchHistoryRecord {
  final String? docId;
  final int id;
  final int userId;
  final Movie movie;
  final int episodeId;
  final int episodeNumber;
  final String episodeLabel;
  final DateTime watchedAt;

  WatchHistoryRecord({
    this.docId,
    required this.id,
    required this.userId,
    required this.movie,
    required this.episodeId,
    required this.episodeNumber,
    required this.episodeLabel,
    required this.watchedAt,
  });

  String getTimeAgoLabel() {
    final diff = DateTime.now().difference(watchedAt);
    if (diff.isNegative || diff.inMinutes < 1) return 'Vừa xem xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 30) return '${diff.inDays} ngày trước';
    final d = watchedAt.day.toString().padLeft(2, '0');
    final m = watchedAt.month.toString().padLeft(2, '0');
    return '$d/$m/${watchedAt.year}';
  }

  Map<String, dynamic> toLocalJson() {
    return {
      'docId': docId,
      'id': id,
      'userId': userId,
      'episodeId': episodeId,
      'episodeNumber': episodeNumber,
      'episodeLabel': episodeLabel,
      'watchedAt': watchedAt.toIso8601String(),
      'movie': {
        'id': movie.id,
        'title': movie.name,
        'name': movie.name,
        'description': movie.description,
        'slug': movie.slug,
        'posterUrl': movie.posterUrl,
        'bannerUrl': movie.bannerUrl,
        'type': movie.type,
        'status': movie.status,
        'releaseYear': movie.releaseYear,
        'totalEpisodes': movie.totalEpisodes,
        'viewCount': movie.viewCount,
        'avgRating': movie.avgRating,
        'ratingCount': movie.ratingCount,
        'isFeatured': movie.isFeatured,
        'isVisible': movie.isVisible,
      },
    };
  }

  factory WatchHistoryRecord.fromLocalJson(Map<String, dynamic> json) {
    final movieMap = json['movie'] as Map<String, dynamic>? ?? {};
    final epNum = (json['episodeNumber'] as num?)?.toInt() ?? 1;
    return WatchHistoryRecord(
      docId: json['docId']?.toString(),
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      movie: Movie.fromJson(movieMap),
      episodeId: (json['episodeId'] as num?)?.toInt() ?? 0,
      episodeNumber: epNum,
      episodeLabel: json['episodeLabel']?.toString() ?? 'Tập $epNum',
      watchedAt: DateTime.tryParse(json['watchedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class WatchHistoryProvider extends ChangeNotifier {
  WatchHistoryProvider._();

  static final WatchHistoryProvider instance = WatchHistoryProvider._();
  factory WatchHistoryProvider() => instance;

  static const String _localKey = 'watch_history_local_v1';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<WatchHistoryRecord> _history = [];
  bool _isLoading = false;

  List<WatchHistoryRecord> get history => _history;
  bool get isLoading => _isLoading;

  static int _parseInt(dynamic val, [int fallback = 0]) {
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? fallback;
    return fallback;
  }

  static DateTime _parseDate(dynamic raw) {
    if (raw == null) return DateTime.now();
    final str = raw.toString().trim();
    if (str.isEmpty) return DateTime.now();
    return DateTime.tryParse(str) ??
        DateTime.tryParse(str.replaceFirst(' ', 'T')) ??
        DateTime.now();
  }

  /// Tải danh sách lịch sử xem từ Firestore (nếu đã đăng nhập) + bộ nhớ cục bộ
  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = AuthProvider.instance.currentUser;
      final prefs = await SharedPreferences.getInstance();
      final localRaw = prefs.getStringList(_localKey) ?? [];

      final localRecords = <WatchHistoryRecord>[];
      for (final str in localRaw) {
        try {
          final map = jsonDecode(str) as Map<String, dynamic>;
          final rec = WatchHistoryRecord.fromLocalJson(map);
          if (user == null || rec.userId == 0 || rec.userId == user.id) {
            localRecords.add(rec);
          }
        } catch (_) {}
      }

      if (user == null) {
        _history = localRecords;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Truy vấn lịch sử trên Firestore theo userId hoặc user_id
      final snapCamel = await _firestore
          .collection(CollectionNames.watchHistory)
          .where('userId', isEqualTo: user.id)
          .get();
      final snapSnake = await _firestore
          .collection(CollectionNames.watchHistory)
          .where('user_id', isEqualTo: user.id)
          .get();

      final docMap = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
      for (final d in snapCamel.docs) {
        docMap[d.id] = d;
      }
      for (final d in snapSnake.docs) {
        docMap[d.id] = d;
      }

      if (docMap.isEmpty) {
        _history = localRecords;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Tải danh sách phim từ collection movies để ghép thông tin
      final moviesSnap =
          await _firestore.collection(CollectionNames.movies).get();
      final movieMap = <int, Movie>{};
      for (final mDoc in moviesSnap.docs) {
        try {
          final m = Movie.fromJson(mDoc.data());
          movieMap[m.id] = m;
        } catch (_) {}
      }

      // Gom các episodeId cần tra cứu số tập (nếu bản ghi cũ chưa lưu episodeNumber)
      final episodeNumCache = <int, int>{};

      // Chỉ giữ bản ghi mới nhất cho mỗi bộ phim của user
      final latestByMovie = <int, WatchHistoryRecord>{};

      for (final entry in docMap.entries) {
        final data = entry.value.data();
        final movieId = _parseInt(data['movieId'] ?? data['movie_id'], 0);
        final movie = movieMap[movieId];
        if (movie == null) continue;

        final epId = _parseInt(data['episodeId'] ?? data['episode_id'], 0);
        int epNum = _parseInt(data['episodeNumber'] ?? data['episode_number'], 0);

        if (epNum <= 0 && epId > 0) {
          if (episodeNumCache.containsKey(epId)) {
            epNum = episodeNumCache[epId]!;
          } else {
            try {
              final epDoc = await _firestore
                  .collection(CollectionNames.episodes)
                  .doc(epId.toString())
                  .get();
              if (epDoc.exists && epDoc.data() != null) {
                epNum = _parseInt(
                  epDoc.data()!['episodeNumber'] ??
                      epDoc.data()!['episode_number'],
                  1,
                );
                episodeNumCache[epId] = epNum;
              }
            } catch (_) {}
          }
        }
        if (epNum <= 0) epNum = 1;

        final epLabel =
            data['episodeLabel']?.toString() ?? 'Tập $epNum';
        final watchedAt = _parseDate(data['watchedAt'] ?? data['watched_at']);

        final record = WatchHistoryRecord(
          docId: entry.key,
          id: _parseInt(data['id'], 0),
          userId: user.id,
          movie: movie,
          episodeId: epId,
          episodeNumber: epNum,
          episodeLabel: epLabel,
          watchedAt: watchedAt,
        );

        final existing = latestByMovie[movieId];
        if (existing == null || watchedAt.isAfter(existing.watchedAt)) {
          latestByMovie[movieId] = record;
        }
      }

      final combined = latestByMovie.values.toList()
        ..sort((a, b) => b.watchedAt.compareTo(a.watchedAt));

      _history = combined;
      await _saveLocalCache();
    } catch (e) {
      debugPrint('Lỗi tải watch_history: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ghi nhận khi người dùng mở xem một tập phim
  Future<void> recordWatch({
    required Movie movie,
    Episode? episode,
    int? fallbackEpisodeNumber,
  }) async {
    final user = AuthProvider.instance.currentUser;
    final uid = user?.id ?? 0;
    final epId = episode?.id ?? 0;
    final epNum = episode?.episodeNumber ?? fallbackEpisodeNumber ?? 1;
    final epLabel = episode?.getEpisodeLabel() ?? 'Tập $epNum';
    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final docId = uid > 0 ? '${uid}_${movie.id}' : 'guest_${movie.id}';

    final newRecord = WatchHistoryRecord(
      docId: docId,
      id: movie.id,
      userId: uid,
      movie: movie,
      episodeId: epId,
      episodeNumber: epNum,
      episodeLabel: epLabel,
      watchedAt: now,
    );

    _history.removeWhere((item) => item.movie.id == movie.id);
    _history.insert(0, newRecord);
    notifyListeners();

    await _saveLocalCache();

    if (uid > 0) {
      try {
        await _firestore
            .collection(CollectionNames.watchHistory)
            .doc(docId)
            .set({
          'id': movie.id,
          'userId': uid,
          'user_id': uid,
          'movieId': movie.id,
          'movie_id': movie.id,
          'episodeId': epId,
          'episode_id': epId,
          'episodeNumber': epNum,
          'episode_number': epNum,
          'episodeLabel': epLabel,
          'progressSeconds': 0,
          'progress_seconds': 0,
          'watchedAt': nowIso,
          'watched_at': nowIso,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Lỗi lưu watch_history lên Firestore: $e');
      }
    }
  }

  /// Xoá 1 mục khỏi lịch sử xem
  Future<void> removeRecord(WatchHistoryRecord record) async {
    _history.removeWhere((e) => e.movie.id == record.movie.id);
    notifyListeners();
    await _saveLocalCache();

    final user = AuthProvider.instance.currentUser;
    if (user != null) {
      try {
        if (record.docId != null) {
          await _firestore
              .collection(CollectionNames.watchHistory)
              .doc(record.docId!)
              .delete();
        }
        // Xoá thêm các bản ghi cũ trùng movie_id của user này nếu có
        final oldSnake = await _firestore
            .collection(CollectionNames.watchHistory)
            .where('user_id', isEqualTo: user.id)
            .where('movie_id', isEqualTo: record.movie.id)
            .get();
        for (final doc in oldSnake.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        debugPrint('Lỗi xoá mục lịch sử xem: $e');
      }
    }
  }

  /// Xoá toàn bộ lịch sử xem của người dùng hiện tại
  Future<void> clearAll() async {
    _history.clear();
    notifyListeners();
    await _saveLocalCache();

    final user = AuthProvider.instance.currentUser;
    if (user != null) {
      try {
        final snap1 = await _firestore
            .collection(CollectionNames.watchHistory)
            .where('userId', isEqualTo: user.id)
            .get();
        for (final d in snap1.docs) {
          await d.reference.delete();
        }
        final snap2 = await _firestore
            .collection(CollectionNames.watchHistory)
            .where('user_id', isEqualTo: user.id)
            .get();
        for (final d in snap2.docs) {
          await d.reference.delete();
        }
      } catch (e) {
        debugPrint('Lỗi xoá toàn bộ lịch sử xem: $e');
      }
    }
  }

  Future<void> _saveLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded =
          _history.take(50).map((e) => jsonEncode(e.toLocalJson())).toList();
      await prefs.setStringList(_localKey, encoded);
    } catch (_) {}
  }
}

