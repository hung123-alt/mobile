/// 8b — Unit test cho PageResult + ApiResponse (phan trang Cau 1).
import 'package:flutter_test/flutter_test.dart';

import 'package:cinema_app/models/api_response.dart';
import 'package:cinema_app/models/page_result.dart';

void main() {
  group('PageResult (Category/Search/Favorite dung phan trang)', () {
    test('getTotalPages / hasNext / hasPrevious', () {
      final p = PageResult<int>(items: [1, 2], total: 90, page: 1, limit: 20);
      expect(p.getTotalPages(), 5);
      expect(p.getHasNext(), isTrue);
      expect(p.getHasPrevious(), isFalse);
      expect(p.getNextPage(), 2);
      expect(p.getPreviousPage(), 1);
    });

    test('bien: trang cuoi khong co next', () {
      final p = PageResult<int>(items: [1], total: 20, page: 2, limit: 20);
      expect(p.getHasNext(), isFalse);
      expect(p.getNextPage(), 2);
    });

    test('that bai an toan: limit = 0 -> 0 trang', () {
      final p = PageResult<int>(items: [], total: 50, page: 1, limit: 0);
      expect(p.getTotalPages(), 0);
      expect(p.getHasNext(), isFalse);
    });

    test('empty()', () {
      final p = PageResult<String>.empty();
      expect(p.items, isEmpty);
      expect(p.total, 0);
    });

    test('fromJson thieu field -> default', () {
      final p = PageResult<int>.fromJson({}, (e) => (e as num).toInt());
      expect(p.items, isEmpty);
      expect(p.page, 1);
      expect(p.limit, 10);
    });

    test('fromJson parse items', () {
      final p = PageResult<int>.fromJson(
        {'items': [1, 2, 3], 'total': 3, 'page': 1, 'limit': 10},
        (e) => (e as num).toInt(),
      );
      expect(p.items, [1, 2, 3]);
    });
  });

  group('ApiResponse (8a/8d)', () {
    test('thanh cong: lay data', () {
      final r = ApiResponse<List<int>, String>.fromJson(
        {'success': true, 'data': [1, 2], 'message': 'ok'},
        (raw) => (raw as List).map((e) => (e as num).toInt()).toList(),
      );
      expect(r.success, isTrue);
      expect(r.getDataOr([]), [1, 2]);
      expect(r.getHasError, isFalse);
    });

    test('that bai: success=false -> fallback', () {
      final r = ApiResponse<List<int>, String>.fromJson(
        {'success': false, 'error': 'het han', 'message': 'loi'},
        (raw) => <int>[],
      );
      expect(r.getDataOr([9]), [9]);
      expect(r.getHasError, isTrue);
    });

    test('data null -> getDataOr tra fallback', () {
      final r = ApiResponse<String, String>(
          success: true, message: 'ok');
      expect(r.getDataOr('mac-dinh'), 'mac-dinh');
    });
  });
}
