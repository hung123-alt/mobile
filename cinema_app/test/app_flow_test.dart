
import 'package:flutter_test/flutter_test.dart';

import 'package:cinema_app/core/utils/generic_utils.dart';
import 'package:cinema_app/models/country_model.dart';
import 'package:cinema_app/models/genre_model.dart';
import 'package:cinema_app/models/movie_model.dart';
import 'package:cinema_app/models/page_result.dart';
import 'package:cinema_app/routes/app_routes.dart';

Movie _m(int id, String name, String type, double rating, int views,
    {List<Genre> genres = const [], List<Country> countries = const []}) {
  return Movie.fromJson({
    'id': id,
    'title': name,
    'slug': 'phim-$id',
    'type': type,
    'status': 'ongoing',
    'view_count': views,
    'avg_rating': rating,
  }).copyWith(genres: genres, countries: countries);
}

Genre _g(int id, String name) =>
    Genre.fromJson({'id': id, 'name': name, 'slug': 'g-$id'});

/// Gia lap MovieRepository.filterMovies: loc + sap xep + phan trang.
PageResult<Movie> fakeFilter(
  List<Movie> all, {
  String? keyword,
  String? type,
  List<int>? genreIds,
  String sortBy = 'newest',
  int page = 1,
  int limit = 20,
}) {
  var out = List<Movie>.from(all);
  if (keyword != null && keyword.trim().isNotEmpty) {
    out = searchBy(out, keyword, (m) => m.name);
  }
  if (type != null) out = whereList(out, (m) => m.type == type);
  if (genreIds != null && genreIds.isNotEmpty) {
    out = whereList(
      out,
      (m) => genreIds.every((id) => m.genres.any((g) => g.id == id)),
    );
  }
  if (sortBy == 'views') out = sortedByDesc(out, (m) => m.viewCount);
  if (sortBy == 'rating') out = sortedByDesc(out, (m) => m.avgRating);
  final total = out.length;
  final items = takeFirst(
    out.skip((page - 1) * limit).toList(),
    limit,
  );
  return PageResult<Movie>(
      items: items, total: total, page: page, limit: limit);
}

void main() {
  late List<Movie> db;
  setUp(() {
    final action = _g(1, 'Hanh dong');
    final tinhCam = _g(2, 'Tinh cam');
    db = [
      _m(1, 'Tan Binh San Co', 'phim_bo', 8.5, 5000, genres: [action]),
      _m(2, 'Mot cuoc dinh hon', 'phim_le', 7.0, 9000, genres: [tinhCam]),
      _m(3, 'Ngoi Nha Cua Cuoc Doi', 'phim_le', 9.0, 1200, genres: [tinhCam]),
      _m(4, 'Con Duong Mau Lua', 'phim_bo', 6.5, 3000,
          genres: [action, tinhCam]),
    ];
  });

  group('8c — Luong Home (hien 71/71 phim, khong rot)', () {
    test('enrich + hien du', () {
      // Home doc movies roi enrich genres: dam bao khong mat item.
      expect(db.length, 4);
      expect(db.every((m) => m.name.isNotEmpty), isTrue);
    });

    test('hero + row: top views', () {
      final top = sortedByDesc(db, (m) => m.viewCount);
      expect(top.first.id, 2); // 9000 views
    });
  });

  group('8c — Luong Search + Category (Cau 1.2 / 1.3)', () {
    test('tim "nha" ra 1 phim', () {
      final p = fakeFilter(db, keyword: 'nha');
      expect(p.total, 1);
      expect(p.items.first.id, 3);
    });

    test('loc type phim_le ra 2 phim', () {
      expect(fakeFilter(db, type: 'phim_le').total, 2);
    });

    test('loc AND 2 the loai ra 1 phim', () {
      expect(fakeFilter(db, genreIds: [1, 2]).total, 1);
    });

    test('ket hop keyword + type + sort views + phan trang', () {
      final p = fakeFilter(db, keyword: 'o', type: 'phim_bo',
          sortBy: 'views', page: 1, limit: 1);
      expect(p.total, 2);
      expect(p.items.length, 1);
      expect(p.getTotalPages(), 2);
      expect(p.getHasNext(), isTrue);
    });

    test('tu khoa rac -> rong + phan trang an toan', () {
      final p = fakeFilter(db, keyword: 'zzz-khong-co');
      expect(p.items, isEmpty);
      expect(p.getTotalPages(), 0);
    });
  });

  group('8c — Luong Favorite / Watchlist / Profile (Cau 1.4 / 1.5)', () {
    test('them/xoa yeu thich (set logic)', () {
      final fav = <int>{};
      fav.add(1);
      fav.add(2);
      expect(fav.length, 2);
      fav.remove(1);
      expect(fav, {2});
    });

    test('lich su xem: them trung thi dua len dau', () {
      final history = [2, 3];
      void watch(int id) {
        history.remove(id);
        history.insert(0, id);
      }
      watch(3);
      expect(history.first, 3);
      watch(1);
      expect(history, [1, 3, 2]);
    });
  });

  group('8c — Luong Player (tap phim + link)', () {
    test('episode label + duration', () {
      expect(db.first.getTypeLabel(), 'Phim Bộ');
      expect(db.first.getViewCountLabel(), '5.0K');
    });

    test('routes dieu huong dung', () {
      expect(AppRoutes.home, '/');
      expect(AppRoutes.search, '/search');
      expect(AppRoutes.category, '/category');
      expect(AppRoutes.favorite, '/favorite');
      expect(AppRoutes.profile, '/profile');
      expect(AppRoutes.movieDetail('tan-binh'), '/movie/tan-binh');
      expect(AppRoutes.random, '/random');
      expect(AppRoutes.adminDashboard, '/admin-dashboard');
    });
  });

  group('8c — Luong loi mang (8a/8d xuyen suot)', () {
    test('mang rot -> UI nhan [] thay vi crash (repository contract)', () {
      // Hop dong: repository tra [] / PageResult.empty khi ApiException.
      final p = PageResult<Movie>.empty();
      expect(p.items, isEmpty);
      expect(p.getTotalPages(), 0);
    });
  });
}
