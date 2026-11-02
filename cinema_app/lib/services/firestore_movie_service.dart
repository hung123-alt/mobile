import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/firebase/collection_names.dart';
import '../models/country_model.dart';
import '../models/genre_model.dart';
import '../models/movie_model.dart';

/// Service đọc phim từ Firestore + gắn thể loại / quốc gia từ bảng trung gian.
///
/// BỐI CẢNH LỖI (admin báo 71 phim, app hiện thiếu):
/// - Dữ liệu migrate từ MySQL cũ (crawl vsmov) lưu quan hệ N-N ở
///   `movie_genres(movie_id, genre_id)` và `movie_countries(movie_id, country_id)`,
///   KHÔNG nhúng sẵn mảng `genres`/`countries` trong document `movies`.
/// - Các trang Home/Search/Random/Detail cũ chỉ đọc `movie.genres` nhúng sẵn
///   nên phim nào chưa có mảng nhúng bị coi là "Chưa phân loại" -> lọc theo
///   thể loại ra rất ít (VD Hành động chỉ 3 phim), phim liên quan rỗng.
/// - Service này đọc gộp 4 collections rồi enrich vào [Movie.genres]/[countries]
///   nên mọi trang dùng chung 1 nguồn sự thật.
class FirestoreMovieService {
  FirestoreMovieService._();

  static int _parseInt(dynamic raw, [int fallback = 0]) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw.trim()) ?? fallback;
    if (raw is bool) return raw ? 1 : 0;
    return fallback;
  }

  /// Tải toàn bộ phim đã enrich thể loại + quốc gia.
  ///
  /// [visibleOnly] = true (mặc định) chỉ giữ phim `isVisible == true`
  /// cho user. Admin muốn đếm đủ 71 thì truyền false.
  static Future<List<Movie>> fetchEnrichedMovies({
    bool visibleOnly = true,
  }) async {
    final firestore = FirebaseFirestore.instance;

    final moviesFuture = firestore.collection(CollectionNames.movies).get();
    final genresFuture = firestore.collection(CollectionNames.genres).get();
    final countriesFuture =
        firestore.collection(CollectionNames.countries).get();
    final movieGenresFuture = firestore.collection('movie_genres').get();
    final movieCountriesFuture =
        firestore.collection('movie_countries').get();

    final moviesSnap = await moviesFuture;
    final genresSnap = await genresFuture;
    final countriesSnap = await countriesFuture;
    final movieGenresSnap = await movieGenresFuture;
    final movieCountriesSnap = await movieCountriesFuture;

    // 1. Map genre_id -> Genre
    final genreById = <int, Genre>{};
    for (final doc in genresSnap.docs) {
      try {
        final g = Genre.fromJson(doc.data(), docId: doc.id);
        if (g.id > 0 && g.name.isNotEmpty) genreById[g.id] = g;
      } catch (e) {
        debugPrint('Bỏ qua genre lỗi ${doc.id}: $e');
      }
    }

    // 2. Map country_id -> Country
    final countryById = <int, Country>{};
    for (final doc in countriesSnap.docs) {
      try {
        final c = Country.fromJson(doc.data(), docId: doc.id);
        if (c.id > 0 && c.name.isNotEmpty) countryById[c.id] = c;
      } catch (e) {
        debugPrint('Bỏ qua country lỗi ${doc.id}: $e');
      }
    }

    // 3. movie_id -> {genreIds} (chịu được cả int/String lẫn lộn do migrate)
    final genreIdsByMovie = <int, Set<int>>{};
    for (final doc in movieGenresSnap.docs) {
      final d = doc.data();
      final mId = _parseInt(d['movie_id'] ?? d['movieId']);
      final gId = _parseInt(d['genre_id'] ?? d['genreId']);
      if (mId > 0 && gId > 0) {
        genreIdsByMovie.putIfAbsent(mId, () => <int>{}).add(gId);
      }
    }

    // 4. movie_id -> {countryIds}
    final countryIdsByMovie = <int, Set<int>>{};
    for (final doc in movieCountriesSnap.docs) {
      final d = doc.data();
      final mId = _parseInt(d['movie_id'] ?? d['movieId']);
      final cId = _parseInt(d['country_id'] ?? d['countryId']);
      if (mId > 0 && cId > 0) {
        countryIdsByMovie.putIfAbsent(mId, () => <int>{}).add(cId);
      }
    }

    // 5. Parse phim (parse mềm, không throw khi lẫn kiểu) + enrich
    final movies = <Movie>[];
    for (final doc in moviesSnap.docs) {
      try {
        var movie = Movie.fromJson(doc.data(), docId: doc.id);
        if (movie.name.trim().isEmpty) continue;
        if (visibleOnly && !movie.isVisible) continue;

        // Gộp thể loại nhúng sẵn + từ bảng trung gian (union theo id)
        final mergedGenres = <int, Genre>{};
        for (final g in movie.genres) {
          if (g.id > 0) mergedGenres[g.id] = g;
        }
        final extraGIds = genreIdsByMovie[movie.id];
        if (extraGIds != null) {
          for (final gid in extraGIds) {
            final g = genreById[gid];
            if (g != null) mergedGenres[gid] = g;
          }
        }

        final mergedCountries = <int, Country>{};
        for (final c in movie.countries) {
          if (c.id > 0) mergedCountries[c.id] = c;
        }
        final extraCIds = countryIdsByMovie[movie.id];
        if (extraCIds != null) {
          for (final cid in extraCIds) {
            final c = countryById[cid];
            if (c != null) mergedCountries[cid] = c;
          }
        }

        if (mergedGenres.length != movie.genres.length ||
            mergedCountries.length != movie.countries.length) {
          movie = movie.copyWith(
            genres: mergedGenres.values.toList(),
            countries: mergedCountries.values.toList(),
          );
        }

        movies.add(movie);
      } catch (e) {
        debugPrint('Bỏ qua phim lỗi ${doc.id}: $e');
      }
    }

    // Mới nhất trước (giữ hành vi cũ của Home)
    movies.sort((a, b) {
      final da = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final cmp = db.compareTo(da);
      if (cmp != 0) return cmp;
      return b.id.compareTo(a.id);
    });

    return movies;
  }

  /// Map thể loại để trang Category/Home dùng chung (id -> Genre).
  static Future<Map<int, Genre>> fetchGenreMap() async {
    final snap = await FirebaseFirestore.instance
        .collection(CollectionNames.genres)
        .get();
    final map = <int, Genre>{};
    for (final doc in snap.docs) {
      try {
        final g = Genre.fromJson(doc.data(), docId: doc.id);
        if (g.id > 0 && g.name.isNotEmpty) map[g.id] = g;
      } catch (_) {}
    }
    return map;
  }

  /// Đếm số phim / thể loại từ bảng trung gian (đúng với dữ liệu migrate).
  ///
  /// Trả về map genreId -> số phim (chỉ đếm phim visible nếu [movies] đã lọc).
  static Future<Map<int, int>> countMoviesPerGenre(
    List<Movie> enrichedMovies,
  ) async {
    final counts = <int, int>{};
    for (final m in enrichedMovies) {
      for (final g in m.genres) {
        counts[g.id] = (counts[g.id] ?? 0) + 1;
      }
    }
    return counts;
  }
}
