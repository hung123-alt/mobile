/// 8b — Unit test cho InputSanitizer (8a: bat loi dau vao phia client).
import 'package:flutter_test/flutter_test.dart';

import 'package:cinema_app/core/security/input_sanitizer.dart';

void main() {
  group('InputSanitizer.cleanText (8a)', () {
    test('go the HTML', () {
      expect(InputSanitizer.cleanText('<b>Phim</b> hay'), 'Phim hay');
      expect(
        InputSanitizer.cleanText('<script>alert(1)</script>Hi'),
        'alert(1)Hi',
      );
    });

    test('gon khoang trang', () {
      expect(InputSanitizer.cleanText('  a   b\n c  '), 'a b c');
    });

    test('cat do dai toi da', () {
      final out = InputSanitizer.cleanText('abcdefghij', maxLength: 5);
      expect(out.length, lessThanOrEqualTo(5));
    });

    test('chuoi rong -> rong', () {
      expect(InputSanitizer.cleanText('   '), '');
    });
  });

  group('InputSanitizer.validateComment (8a/8d)', () {
    test('that bai: rong / chi tag HTML -> loi', () {
      expect(InputSanitizer.validateComment(''), isNotNull);
      expect(InputSanitizer.validateComment('   '), isNotNull);
      expect(InputSanitizer.validateComment('<b></b>'), isNotNull);
    });

    test('thanh cong: noi dung hop le -> null', () {
      expect(InputSanitizer.validateComment('Phim rat hay'), isNull);
    });
  });

  group('InputSanitizer.isSafeImageUrl (8a)', () {
    test('that bai: chan scheme nguy hiem', () {
      expect(InputSanitizer.isSafeImageUrl('javascript:alert(1)'), isFalse);
      expect(InputSanitizer.isSafeImageUrl('data:image/png;base64,xx'), isFalse);
      expect(InputSanitizer.isSafeImageUrl('file:///etc/passwd'), isFalse);
      expect(InputSanitizer.isSafeImageUrl('http://example.com/a.png'), isFalse);
    });

    test('thanh cong: https va asset noi bo', () {
      expect(
        InputSanitizer.isSafeImageUrl('https://example.com/a.png'),
        isTrue,
      );
      expect(InputSanitizer.isSafeImageUrl('assets/poster.png'), isTrue);
    });
  });
}
