/// 8b — Unit test cho generic_utils (tim kiem / loc / sap xep / gom nhom).
/// Cac ham nay la logic dung cho Cau 1: Home / Search / Category / Favorite.
import 'package:flutter_test/flutter_test.dart';

import 'package:cinema_app/core/utils/generic_utils.dart';

class _MiniMovie {
  _MiniMovie(this.name, this.rating, this.type);
  final String name;
  final double rating;
  final String type;
}

void main() {
  final movies = [
    _MiniMovie('Tan Binh San Co', 8.5, 'phim_bo'),
    _MiniMovie('Mot cuoc dinh hon', 7.0, 'phim_le'),
    _MiniMovie('Ngoi Nha Cua Cuoc Doi', 9.0, 'phim_le'),
  ];

  group('firstWhereOrNull / firstWhereOrElse (8d)', () {
    test('thanh cong: tim thay', () {
      final found = firstWhereOrNull(movies, (m) => m.rating >= 9);
      expect(found?.name, 'Ngoi Nha Cua Cuoc Doi');
    });

    test('that bai: khong thay -> null / fallback', () {
      expect(firstWhereOrNull(movies, (m) => m.rating > 10), isNull);
      final fb = _MiniMovie('Fallback', 0, 'x');
      expect(firstWhereOrElse(movies, (m) => m.rating > 10, fb), fb);
    });
  });

  group('countItem / countWhere (8d)', () {
    test('dem dung', () {
      expect(countItem([1, 2, 2, 3], 2), 2);
      expect(countWhere(movies, (m) => m.rating >= 8), 2);
    });

    test('danh sach rong -> 0 (that bai an toan)', () {
      expect(countItem<int>([], 1), 0);
      expect(countWhere<_MiniMovie>([], (m) => true), 0);
    });
  });

  group('whereList / searchBy — logic SearchPage + CategoryPage (Cau 1)', () {
    test('whereList loc theo type', () {
      final le = whereList(movies, (m) => m.type == 'phim_le');
      expect(le.length, 2);
    });

    test('searchBy khong phan biet hoa thuong', () {
      final out = searchBy(movies, 'NGOI NHA', (m) => m.name);
      expect(out.length, 1);
    });

    test('searchBy keyword rong -> tra ve tat ca (that bai an toan)', () {
      expect(searchBy(movies, '   ', (m) => m.name).length, movies.length);
    });

    test('searchBy khong khop -> rong', () {
      expect(searchBy(movies, 'zzz-khong-co', (m) => m.name), isEmpty);
    });
  });

  group('sortedBy / sortedByDesc (8d)', () {
    test('tang dan khong doi danh sach goc', () {
      final sorted = sortedBy(movies, (m) => m.rating);
      expect(sorted.first.rating, 7.0);
      expect(movies.first.rating, 8.5); // goc giu nguyen
    });

    test('giam dan', () {
      final sorted = sortedByDesc(movies, (m) => m.rating);
      expect(sorted.first.rating, 9.0);
    });
  });

  group('groupBy / toMap (8d)', () {
    test('gom theo type', () {
      final g = groupBy(movies, (m) => m.type);
      expect(g['phim_le']!.length, 2);
      expect(g['phim_bo']!.length, 1);
    });

    test('toMap giu phan tu cuoi khi trung key', () {
      final m = toMap(movies, (e) => e.type);
      expect(m['phim_le']!.name, 'Ngoi Nha Cua Cuoc Doi');
    });
  });

  group('takeFirst / chunk (8d bien)', () {
    test('takeFirst cat dung', () {
      expect(takeFirst(movies, 2).length, 2);
      expect(takeFirst(movies, 99).length, movies.length);
    });

    test('chunk size <= 0 -> rong (bat loi)', () {
      expect(chunk(movies, 0), isEmpty);
      expect(chunk(movies, -1), isEmpty);
    });

    test('chunk chia nhom', () {
      final c = chunk(movies, 2);
      expect(c.length, 2);
      expect(c.first.length, 2);
    });
  });
}
