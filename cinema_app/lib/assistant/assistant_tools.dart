// ignore_for_file: use_build_context_synchronously
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/firebase/collection_names.dart';
import '../models/genre_model.dart';
import '../models/movie_model.dart';
import '../pages/movie_detail_page.dart';
import '../pages/player_page.dart';
import '../pages/search_page.dart';
import '../providers/auth_provider.dart';
import '../providers/watch_history_provider.dart';
import '../providers/watchlist_provider.dart';
import '../routes/app_routes.dart';
import '../services/firestore_movie_service.dart';
import '../widgets/episode_grid.dart';
import 'assistant_persona.dart';
import 'text_normalizer.dart';

/// Kết quả thực thi 1 tool: trả về cho Gemini dưới dạng functionResponse.
class ToolOutcome {
  final Map<String, dynamic> data;
  final String speakHint;
  ToolOutcome(this.data, {this.speakHint = ''});
}

/// Registry 11 tool phim. Triết lý Mark-LIV: thêm tool = thêm 1 case ở đây,
/// Brain không hardcode if-else theo tên tool.
class AssistantTools {
  AssistantTools._();

  /// Khai báo function_declarations gửi cho Gemini.
  static List<Map<String, dynamic>> declarations() {
    Map<String, dynamic> fn(
      String name,
      String desc,
      Map<String, dynamic> props, [
      List<String>? required,
    ]) {
      return {
        'name': name,
        'description': desc,
        'parameters': {
          'type': 'OBJECT',
          'properties': props,
          if (required != null && required.isNotEmpty) 'required': required,
        },
      };
    }

    Map<String, dynamic> str(String d) => {'type': 'STRING', 'description': d};
    Map<String, dynamic> int_(String d) => {'type': 'INTEGER', 'description': d};

    return [
      fn('searchMovies', 'Tìm phim trong kho Firestore. keyword nên là tên không dấu hoặc có dấu đều được.',
          {'keyword': str('Từ khoá tên phim, VD dau vet tron doi'), 'genre': str('Tên thể loại hoặc slug, VD hanh-dong'), 'country': str('Tên quốc gia hoặc slug'), 'type': str('phim_le | phim_bo | hoat_hinh | anime'), 'status': str('ongoing | completed | upcoming'), 'limit': int_('Số kết quả, mặc định 5')}, ['keyword']),
      fn('getMovieDetail', 'Lấy mô tả, diễn viên, năm, điểm, số tập của 1 phim.',
          {'title': str('Tên phim hoặc slug, VD dau-vet-tron-doi')}, ['title']),
      fn('listEpisodes', 'Liệt kê tập phim: số tập, tên tập, thời lượng, server.',
          {'title': str('Tên phim hoặc slug')}, ['title']),
      fn('getRandomMovie', 'Lấy ngẫu nhiên 1 phim, có thể lọc theo thể loại.',
          {'genre': str('Slug thể loại, VD hanh-dong. Bỏ trống = mọi thể loại')}),
      fn('getTopMovies', 'Top phim thịnh hành theo lượt xem / điểm / mới nhất.',
          {'sortBy': str('views | rating | newest'), 'genre': str('Slug thể loại, có thể bỏ trống'), 'limit': int_('Mặc định 5')}),
      fn('getGenres', 'Danh sách thể loại đang có trong kho để map tên tiếng Việt sang slug.', {}),
      fn('openMovie', 'Mở màn hình chi tiết phim. BẮT BUỘC dùng slug lấy từ searchMovies/getMovieDetail, không tự đoán.',
          {'slug': str('Slug phim, VD dau-vet-tron-doi')}, ['slug']),
      fn('playEpisode', 'Mở trình phát đúng tập. BẮT BUỘC dùng slug từ tool tìm kiếm.',
          {'slug': str('Slug phim'), 'episode': int_('Số tập, mặc định 1')}, ['slug']),
      fn('openCategory', 'Mở trang thể loại theo slug.',
          {'genre': str('Slug thể loại, VD hanh-dong')}, ['genre']),
      fn('openPage', 'Mở trang trong app: home | search | category | favorite | history | profile | random.',
          {'page': str('Tên trang')}, ['page']),
      fn('toggleFavorite', 'Thêm/xoá phim khỏi Yêu thích của user hiện tại.',
          {'title': str('Tên phim hoặc slug')}, ['title']),
    ];
  }

  /// Thực thi tool, trả Map để nhét vào functionResponse.
  static Future<ToolOutcome> run(
    String name,
    Map<String, dynamic> args, {
    BuildContext? context,
  }) async {
    try {
      switch (name) {
        case 'searchMovies':
          return await _searchMovies(args);
        case 'getMovieDetail':
          return await _movieDetail(args);
        case 'listEpisodes':
          return await _listEpisodes(args);
        case 'getRandomMovie':
          return await _random(args);
        case 'getTopMovies':
          return await _top(args);
        case 'getGenres':
          return await _genres();
        case 'openMovie':
          return await _openMovie(args, context);
        case 'playEpisode':
          return await _playEpisode(args, context);
        case 'openCategory':
          return await _openCategory(args, context);
        case 'openPage':
          return await _openPage(args, context);
        case 'toggleFavorite':
          return await _toggleFavorite(args);
        default:
          return ToolOutcome({'error': 'Tool không tồn tại: $name'});
      }
    } catch (e) {
      return ToolOutcome({'error': 'Tool $name lỗi: $e'});
    }
  }

  // ---------- nhóm đọc ----------

  static Future<List<Movie>> _all() =>
      FirestoreMovieService.fetchEnrichedMovies();

  static Future<ToolOutcome> _searchMovies(Map<String, dynamic> args) async {
    final keyword = (args['keyword'] ?? '').toString();
    final genreF = (args['genre'] ?? '').toString().toLowerCase().trim();
    final countryF = (args['country'] ?? '').toString().toLowerCase().trim();
    final typeF = (args['type'] ?? '').toString().toLowerCase().trim();
    final statusF = (args['status'] ?? '').toString().toLowerCase().trim();
    final limit = int.tryParse('${args['limit'] ?? 5}') ?? 5;

    final movies = await _all();
    final qNorm = TextNormalizer.normalize(keyword);
    final qTok = TextNormalizer.tokens(qNorm);

    final scored = <({Movie m, int s})>[];
    for (final m in movies) {
      if (genreF.isNotEmpty) {
        final gNorm = genreF.replaceAll('-', ' ');
        final hit = m.genres.any((g) =>
            g.slug.toLowerCase() == genreF ||
            TextNormalizer.normalize(g.getName()).contains(gNorm) ||
            g.getName().toLowerCase().contains(genreF));
        if (!hit) continue;
      }
      if (countryF.isNotEmpty) {
        final cNorm = countryF.replaceAll('-', ' ');
        final hit = m.countries.any((c) =>
            c.slug.toLowerCase() == countryF ||
            TextNormalizer.normalize(c.getName()).contains(cNorm));
        if (!hit) continue;
      }
      if (typeF.isNotEmpty && m.type.toLowerCase() != typeF) continue;
      if (statusF.isNotEmpty && m.status.toLowerCase() != statusF) continue;
      final titleNorm = TextNormalizer.normalize(m.name);
      final s = qNorm.isEmpty
          ? 50
          : TextNormalizer.scoreTitle(
              queryNorm: qNorm, queryTokens: qTok, titleNorm: titleNorm, slug: m.slug.toLowerCase());
      if (qNorm.isEmpty || s > 0) scored.add((m: m, s: s));
    }
    scored.sort((a, b) {
      final c = b.s.compareTo(a.s);
      if (c != 0) return c;
      return b.m.viewCount.compareTo(a.m.viewCount);
    });
    final top = scored.take(limit.clamp(1, 10)).toList();
    return ToolOutcome({
      'results': top
          .map((e) => {
                'title': e.m.name,
                'slug': e.m.slug,
                'year': e.m.releaseYear,
                'rating': e.m.avgRating,
                'type': e.m.type,
                'episodes': e.m.totalEpisodes,
                'genres': e.m.genres.map((g) => g.getName()).take(3).toList(),
              })
          .toList(),
    }, speakHint: top.isEmpty ? 'empty' : 'found');
  }

  static Future<Movie?> _findBest(String raw) async {
    final movies = await _all();
    final q = raw.trim().toLowerCase();
    for (final m in movies) {
      if (m.slug.toLowerCase() == q) return m;
    }
    final qNorm = TextNormalizer.normalize(raw);
    final qTok = TextNormalizer.tokens(qNorm);
    Movie? best;
    var bestScore = 0;
    for (final m in movies) {
      final s = TextNormalizer.scoreTitle(
        queryNorm: qNorm,
        queryTokens: qTok,
        titleNorm: TextNormalizer.normalize(m.name),
        slug: m.slug.toLowerCase(),
      );
      if (s > bestScore) {
        bestScore = s;
        best = m;
      }
    }
    return bestScore > 0 ? best : null;
  }

  static Future<ToolOutcome> _movieDetail(Map<String, dynamic> args) async {
    final title = (args['title'] ?? '').toString();
    final m = await _findBest(title);
    if (m == null) return ToolOutcome({'error': 'Em chưa tìm thấy phim "$title"'});
    return ToolOutcome({
      'title': m.name,
      'slug': m.slug,
      'description': m.description.isEmpty ? 'Chưa có mô tả.' : m.description,
      'year': m.releaseYear,
      'rating': m.avgRating,
      'ratingCount': m.ratingCount,
      'views': m.viewCount,
      'type': m.getTypeLabel(),
      'status': m.getStatusLabel(),
      'episodes': m.totalEpisodes,
      'genres': m.genres.map((g) => g.getName()).toList(),
      'countries': m.countries.map((c) => c.getName()).toList(),
    });
  }

  static Future<ToolOutcome> _listEpisodes(Map<String, dynamic> args) async {
    final title = (args['title'] ?? '').toString();
    final m = await _findBest(title);
    if (m == null) return ToolOutcome({'error': 'Em chưa tìm thấy phim "$title"'});
    final eps = await EpisodeGrid.fetchEpisodesForMovie(m.id);
    return ToolOutcome({
      'title': m.name,
      'slug': m.slug,
      'total': eps.length,
      'episodes': eps
          .take(30)
          .map((e) => {
                'number': e.episodeNumber,
                'label': e.getEpisodeLabel(),
                'server': e.serverName,
                'duration': e.getDurationLabel(),
              })
          .toList(),
    });
  }

  static Future<ToolOutcome> _random(Map<String, dynamic> args) async {
    final genreF = (args['genre'] ?? '').toString().toLowerCase().trim();
    var movies = await _all();
    if (genreF.isNotEmpty) {
      final gNorm = genreF.replaceAll('-', ' ');
      movies = movies
          .where((m) => m.genres.any((g) =>
              g.slug.toLowerCase() == genreF ||
              TextNormalizer.normalize(g.getName()).contains(gNorm)))
          .toList();
    }
    if (movies.isEmpty) return ToolOutcome({'error': 'Kho phim đang trống.'});
    movies.shuffle();
    final m = movies.first;
    return ToolOutcome({
      'title': m.name,
      'slug': m.slug,
      'year': m.releaseYear,
      'rating': m.avgRating,
      'genres': m.genres.map((g) => g.getName()).take(3).toList(),
    });
  }

  static Future<ToolOutcome> _top(Map<String, dynamic> args) async {
    final sortBy = (args['sortBy'] ?? 'views').toString();
    final genreF = (args['genre'] ?? '').toString().toLowerCase().trim();
    final limit = (int.tryParse('${args['limit'] ?? 5}') ?? 5).clamp(1, 10);
    var movies = await _all();
    if (genreF.isNotEmpty) {
      final gNorm = genreF.replaceAll('-', ' ');
      movies = movies
          .where((m) => m.genres.any((g) =>
              g.slug.toLowerCase() == genreF ||
              TextNormalizer.normalize(g.getName()).contains(gNorm)))
          .toList();
    }
    if (sortBy == 'rating') {
      movies.sort((a, b) => b.avgRating.compareTo(a.avgRating));
    } else if (sortBy == 'newest') {
      movies.sort((a, b) => (b.releaseYear ?? 0).compareTo(a.releaseYear ?? 0));
    } else {
      movies.sort((a, b) => b.viewCount.compareTo(a.viewCount));
    }
    return ToolOutcome({
      'results': movies.take(limit).map((m) => {'title': m.name, 'slug': m.slug, 'year': m.releaseYear, 'rating': m.avgRating}).toList(),
    });
  }

  static Future<ToolOutcome> _genres() async {
    final map = await FirestoreMovieService.fetchGenreMap();
    final list = map.values.map((g) => {'id': g.id, 'name': g.getName(), 'slug': g.slug}).toList();
    list.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    return ToolOutcome({'genres': list});
  }

  // ---------- nhóm hành động ----------

  static ToolOutcome _needContext() =>
      ToolOutcome({'error': 'Thiếu context điều hướng, bạn mở app rồi thử lại.'});

  static Future<ToolOutcome> _openMovie(Map<String, dynamic> args, BuildContext? ctx) async {
    final slug = (args['slug'] ?? '').toString().trim();
    if (slug.isEmpty) return ToolOutcome({'error': 'Thiếu slug phim.'});
    Movie? target;
    final movies = await _all();
    for (final m in movies) {
      if (m.slug.toLowerCase() == slug.toLowerCase()) {
        target = m;
        break;
      }
    }
    target ??= await _findBest(slug);
    if (target == null) return ToolOutcome({'error': 'Em chưa tìm thấy phim "$slug"'});
    final movie = target;
    if (ctx == null) return _needContext();
    if (!ctx.mounted) return ToolOutcome({'error': 'Màn hình đã đóng.'});
    // Mở trực tiếp MovieDetailPage (route /movie/:slug không có trong AppRouter).
    Navigator.push(
    
      ctx,
      MaterialPageRoute(builder: (_) => MovieDetailPage(movie: movie)),
    );
    return ToolOutcome({'opened': movie.slug, 'title': movie.name});
  }

  static Future<ToolOutcome> _playEpisode(Map<String, dynamic> args, BuildContext? ctx) async {
    final slug = (args['slug'] ?? '').toString().trim();
    final epNum = int.tryParse('${args['episode'] ?? 1}') ?? 1;
    if (slug.isEmpty) return ToolOutcome({'error': 'Thiếu slug phim.'});
    final m = await _findBest(slug);
    if (m == null) return ToolOutcome({'error': 'Em chưa tìm thấy phim "$slug"'});
    if (ctx == null) return _needContext();
    if (!ctx.mounted) return ToolOutcome({'error': 'Màn hình đã đóng.'});
    final eps = await EpisodeGrid.fetchEpisodesForMovie(m.id);
    var chosen = eps.isNotEmpty
        ? eps.firstWhere(
            (e) => e.episodeNumber == epNum,
            orElse: () => eps.first,
          )
        : null;
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => PlayerPage(
          movie: m,
          episodes: eps.isNotEmpty ? eps : null,
          selectedEpisode: chosen,
          initialEpisode: chosen?.episodeNumber ?? epNum,
        ),
      ),
    );
    return ToolOutcome({'playing': m.slug, 'episode': chosen?.episodeNumber ?? epNum, 'title': m.name});
  }

  static Future<ToolOutcome> _openCategory(Map<String, dynamic> args, BuildContext? ctx) async {
    final genre = (args['genre'] ?? '').toString().trim();
    if (genre.isEmpty) return ToolOutcome({'error': 'Thiếu thể loại.'});
    if (ctx == null) return _needContext();
    // Map slug/tên -> id thật để mở SearchPage lọc sẵn (CategoryPage không nhận argument).
    try {
      final map = await FirestoreMovieService.fetchGenreMap();
      Genre? found;
      final gNorm = genre.toLowerCase().replaceAll('-', ' ').trim();
      for (final g in map.values) {
        if (g.slug.toLowerCase() == genre.toLowerCase() ||
            TextNormalizer.normalize(g.getName()) == TextNormalizer.normalize(genre) ||
            TextNormalizer.normalize(g.getName()).contains(gNorm)) {
          found = g;
          break;
        }
      }
      if (found != null) {
        Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (_) => SearchPage(
              initialGenreId: found!.id,
              initialGenreName: found.getName(),
              initialQuery: found.getName(),
            ),
          ),
        );
        return ToolOutcome({'opened': 'category', 'genre': found.getName()});
      }
    } catch (_) {}
    Navigator.pushNamed(ctx, AppRoutes.category);
    return ToolOutcome({'opened': 'category', 'genre': genre});
  }

  static Future<ToolOutcome> _openPage(Map<String, dynamic> args, BuildContext? ctx) async {
    final page = (args['page'] ?? 'home').toString().toLowerCase().trim();
    if (ctx == null) return _needContext();
    switch (page) {
      case 'home':
        Navigator.pushNamedAndRemoveUntil(ctx, AppRoutes.home, (r) => false);
        break;
      case 'search':
        Navigator.pushNamed(ctx, AppRoutes.search);
        break;
      case 'category':
        Navigator.pushNamed(ctx, AppRoutes.category);
        break;
      case 'favorite':
        Navigator.pushNamed(ctx, AppRoutes.favorite);
        break;
      case 'history':
        Navigator.pushNamed(ctx, AppRoutes.watchHistory);
        break;
      case 'profile':
        Navigator.pushNamed(ctx, AppRoutes.profile);
        break;
      case 'random':
        Navigator.pushNamed(ctx, AppRoutes.random);
        break;
      default:
        Navigator.pushNamed(ctx, AppRoutes.home);
        break;
    }
    return ToolOutcome({'opened': page});
  }

  static Future<ToolOutcome> _toggleFavorite(Map<String, dynamic> args) async {
    final title = (args['title'] ?? '').toString();
    final m = await _findBest(title);
    if (m == null) return ToolOutcome({'error': 'Em chưa tìm thấy phim "$title"'});
    final user = AuthProvider.instance.currentUser;
    if (user == null) return ToolOutcome({'error': 'Bạn đăng nhập để lưu Yêu thích nhé.'});
    await WatchlistProvider.instance.toggleFavorite(m);
    final isFav = WatchlistProvider.instance.isFavorite(m.id);
    return ToolOutcome({'title': m.name, 'favorite': isFav});
  }

  /// Lịch sử xem gần đây cho câu hỏi "phim xem dở".
  static Future<ToolOutcome> watchHistory({int limit = 5}) async {
    final h = WatchHistoryProvider.instance.history.take(limit).toList();
    return ToolOutcome({
      'results': h
          .map((r) => {
                'title': r.movie.name,
                'slug': r.movie.slug,
                'episode': r.episodeLabel,
                'when': r.getTimeAgoLabel(),
              })
          .toList(),
    });
  }

  /// Báo lỗi phim: ghi thẳng Firestore error_reports.
  static Future<ToolOutcome> reportError({
    required String title,
    required String reason,
  }) async {
    final user = AuthProvider.instance.currentUser;
    if (user == null) return ToolOutcome({'error': 'Bạn đăng nhập để báo lỗi nhé.'});
    final m = await _findBest(title);
    await FirebaseFirestore.instance.collection(CollectionNames.errorReports).add({
      'movieId': m?.id ?? 0,
      'movie_id': m?.id ?? 0,
      'movieTitle': m?.name ?? title,
      'movie_title': m?.name ?? title,
      'userId': user.id,
      'user_id': user.id,
      'description': reason,
      'errorType': 'assistant_report',
      'error_type': 'assistant_report',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'created_at': DateTime.now().toIso8601String(),
    });
    return ToolOutcome({'reported': true});
  }

  /// Persona hiện tại của user (để Brain chèn traitBlock).
  static Future<AssistantPersona> currentPersona() async {
    final user = AuthProvider.instance.currentUser;
    if (user == null) return AssistantPersona.lina;
    try {
      final doc = await FirebaseFirestore.instance
          .collection(CollectionNames.users)
          .doc(user.id.toString())
          .get();
      return AssistantPersona.fromId(doc.data()?['assistantPersona']?.toString());
    } catch (_) {
      return AssistantPersona.lina;
    }
  }
}
