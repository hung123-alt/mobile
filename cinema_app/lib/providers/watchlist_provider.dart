import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/firebase/collection_names.dart';
import '../models/movie_model.dart';
import 'auth_provider.dart';

/// Provider quản lý danh sách phim Yêu thích (Watchlist / Favorites)
class WatchlistProvider extends ChangeNotifier {
  WatchlistProvider._();

  static final WatchlistProvider instance = WatchlistProvider._();
  factory WatchlistProvider() => instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<Movie> _favorites = [];
  bool _isLoading = false;

  List<Movie> get favorites => List.unmodifiable(_favorites);
  bool get isLoading => _isLoading;

  bool isFavorite(int movieId) {
    return _favorites.any((m) => m.id == movieId);
  }

  Future<void> loadFavorites() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = AuthProvider.instance.currentUser;
      _favorites.clear();

      if (user != null) {
        // Đọc từ Firestore sub-collection users/{uid}/favorites
        final snap = await _firestore
            .collection(CollectionNames.userFavorites(user.id.toString()))
            .get();

        for (final doc in snap.docs) {
          try {
            _favorites.add(Movie.fromJson(doc.data()));
          } catch (_) {}
        }
      }

      // Đọc thêm từ SharedPreferences cục bộ nếu có
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getString('local_favorites');
      if (localJson != null && localJson.isNotEmpty) {
        final list = jsonDecode(localJson) as List;
        for (final item in list) {
          final m = Movie.fromJson(item as Map<String, dynamic>);
          if (!isFavorite(m.id)) {
            _favorites.add(m);
          }
        }
      }
    } catch (e) {
      debugPrint('loadFavorites error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(Movie movie) async {
    final exists = isFavorite(movie.id);

    if (exists) {
      _favorites.removeWhere((m) => m.id == movie.id);
    } else {
      _favorites.add(movie);
    }
    notifyListeners();

    // Lưu local
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapList = _favorites.map((m) => {
        'id': m.id,
        'title': m.name,
        'name': m.name,
        'slug': m.slug,
        'description': m.description,
        'posterUrl': m.posterUrl,
        'poster_url': m.posterUrl,
        'bannerUrl': m.bannerUrl,
        'banner_url': m.bannerUrl,
        'type': m.type,
        'status': m.status,
        'releaseYear': m.releaseYear,
        'release_year': m.releaseYear,
        'totalEpisodes': m.totalEpisodes,
        'total_episodes': m.totalEpisodes,
        'viewCount': m.viewCount,
        'view_count': m.viewCount,
        'avgRating': m.avgRating,
        'avg_rating': m.avgRating,
      }).toList();
      await prefs.setString('local_favorites', jsonEncode(mapList));
    } catch (_) {}

    // Đồng bộ Firestore nếu có user
    final user = AuthProvider.instance.currentUser;
    if (user != null) {
      final ref = _firestore
          .collection(CollectionNames.userFavorites(user.id.toString()))
          .doc(movie.id.toString());

      if (exists) {
        await ref.delete().catchError((_) {});
      } else {
        await ref.set({
          'id': movie.id,
          'title': movie.name,
          'slug': movie.slug,
          'posterUrl': movie.posterUrl,
          'type': movie.type,
          'totalEpisodes': movie.totalEpisodes,
          'avgRating': movie.avgRating,
          'addedAt': DateTime.now().toIso8601String(),
        }).catchError((_) {});
      }
    }
  }
}
