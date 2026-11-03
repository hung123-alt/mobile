
import 'package:flutter_test/flutter_test.dart';

import 'package:cinema_app/models/country_model.dart';
import 'package:cinema_app/models/genre_model.dart';
import 'package:cinema_app/models/movie_model.dart';

Movie _movie(Map<String, dynamic> json) => Movie.fromJson(json);

void main() {
  group('Movie.fromJson parse mem (8a: khong rot phim)', () {
    test('thanh cong: json chuan camelCase', () {
      final m = _movie({
        'id': 1,
        'title': 'Phim A',
        'description': 'Mo ta',
        'slug': 'phim-a',
        'type': 'phim_bo',
        'status': 'ongoing',
        'release_year': 2024,
        'view_count': 1500,
        'avg_rating': 8.5,
      });
      expect(m.id, 1);
      expect(m.name, 'Phim A');
      expect(m.releaseYear, 2024);
      expect(m.viewCount, 1500);
    });

    test('parse mem: id dang String, bool dang int/String', () {
      final m = _movie({
        'id': '42',
        'title': 'Phim B',
        'is_visible': 0,
        'is_featured': 'true',
        'view_count': '99',
        'avg_rating': '7.5',
      });
      expect(m.id, 42);
      expect(m.isVisible, isFalse);
      expect(m.isFeatured, isTrue);
      expect(m.viewCount, 99);
      expect(m.avgRating, 7.5);
    });

    test('that bai an toan: thieu field -> default, khong throw', () {
      final m = _movie({});
      expect(m.id, 0);
      expect(m.name, '');
      expect(m.type, 'phim_le');
      expect(m.genres, isEmpty);
      expect(m.countries, isEmpty);
    });

    test('docId fallback khi id = 0', () {
      final m = Movie.fromJson({'title': 'X'}, docId: '7');
      expect(m.id, 7);
    });

    test('genres loi 1 item -> bo qua item do, giu item tot', () {
      final m = _movie({
        'id': 1,
        'title': 'X',
        'genres': [
          {'id': 1, 'name': 'Hanh dong', 'slug': 'hanh-dong'},
          'chuoi-loi-khong-phai-map',
        ],
      });
      expect(m.genres.length, 1);
      expect(m.genres.first.name, 'Hanh dong');
    });
  });

  group('Movie labels (Cau 1: hien thi Home/Search/Category)', () {
    Movie base() => _movie({'id': 1, 'title': 'X', 'view_count': 0});

    test('getTypeLabel', () {
      expect(_movie({'id': 1, 'title': 'x', 'type': 'phim_le'}).getTypeLabel(),
          'Phim Lẻ');
      expect(_movie({'id': 1, 'title': 'x', 'type': 'phim_bo'}).getTypeLabel(),
          'Phim Bộ');
      expect(_movie({'id': 1, 'title': 'x', 'type': 'hoat_hinh'}).getTypeLabel(),
          'Hoạt Hình');
      expect(_movie({'id': 1, 'title': 'x', 'type': 'la'}).getTypeLabel(), 'Khác');
    });

    test('getStatusLabel', () {
      expect(
          _movie({'id': 1, 'title': 'x', 'status': 'ongoing'}).getStatusLabel(),
          'Đang phát');
      expect(
          _movie({'id': 1, 'title': 'x', 'status': 'completed'})
              .getStatusLabel(),
          'Hoàn thành');
      expect(
          _movie({'id': 1, 'title': 'x', 'status': 'upcoming'}).getStatusLabel(),
          'Sắp chiếu');
    });

    test('getViewCountLabel bien', () {
      expect(base().copyWith().getViewCountLabel(), '0');
      expect(_movie({'id': 1, 'title': 'x', 'view_count': 999})
          .getViewCountLabel(), '999');
      expect(_movie({'id': 1, 'title': 'x', 'view_count': 1500})
          .getViewCountLabel(), '1.5K');
      expect(_movie({'id': 1, 'title': 'x', 'view_count': 2500000})
          .getViewCountLabel(), '2.5M');
    });

    test('getFirstGenreName khi rong', () {
      expect(base().getFirstGenreName(), 'Chưa phân loại');
    });

    test('displayImageUrl: banner "{}" -> fallback poster', () {
      final m = _movie({
        'id': 1,
        'title': 'x',
        'banner_url': '{}',
        'poster_url': 'https://example.com/p.png',
      });
      // tren test (khong phai web) giu nguyen url
      expect(m.displayImageUrl, 'https://example.com/p.png');
    });
  });

  group('Genre / Country parse mem (8a)', () {
    test('Genre id String + is_visible String', () {
      final g = Genre.fromJson({'id': '3', 'name': 'Hai', 'is_visible': '0'});
      expect(g.id, 3);
      expect(g.isVisible, isFalse);
    });

    test('Genre thieu -> default, docId fallback', () {
      final g = Genre.fromJson({}, docId: '9');
      expect(g.id, 9);
      expect(g.name, '');
      expect(g.isVisible, isTrue);
    });

    test('Country snake_case', () {
      final c = Country.fromJson({
        'country_id': 5,
        'name': 'Han Quoc',
        'slug': 'han-quoc',
        'is_visible': 1,
      });
      expect(c.id, 5);
      expect(c.isVisible, isTrue);
    });
  });
}
