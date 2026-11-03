
import 'package:flutter_test/flutter_test.dart';

import 'package:cinema_app/core/utils/validators.dart';

void main() {
  group('Validators.required (8a/8d: bat rong)', () {
    test('null -> loi', () {
      expect(Validators.required(null), isNotNull);
    });

    test('chuoi rong / toan khoang trang -> loi', () {
      expect(Validators.required(''), isNotNull);
      expect(Validators.required('   '), isNotNull);
    });

    test('chuoi hop le -> null (thanh cong)', () {
      expect(Validators.required('Phim hay'), isNull);
    });

    test('fieldName tuong ung hien trong thong bao', () {
      expect(
        Validators.required('', fieldName: 'Ten phim'),
        contains('Ten phim'),
      );
    });
  });

  group('Validators.email (8a/8d)', () {
    test('null / rong -> loi "trong"', () {
      expect(Validators.email(null), contains('trống'));
      expect(Validators.email('  '), contains('trống'));
    });

    test('sai dinh dang -> loi', () {
      for (final bad in [
        'khong-phai-email',
        'a@',
        '@gmail.com',
        'a@gmail',
        'a@@gmail.com',
        'a gmail@gmail.com',
      ]) {
        expect(Validators.email(bad), isNotNull, reason: bad);
      }
    });

    test('dung dinh dang -> null', () {
      for (final good in [
        'user@gmail.com',
        'ten.ho@cinema-app.vn',
        'a-b_c@sub.domain.com',
      ]) {
        expect(Validators.email(good), isNull, reason: good);
      }
    });
  });

  group('Validators.password (8a/8d)', () {
    test('rong -> loi', () {
      expect(Validators.password(null), isNotNull);
      expect(Validators.password(''), isNotNull);
    });

    test('ngan hon 6 ky tu -> loi', () {
      expect(Validators.password('12345'), isNotNull);
    });

    test('>= 6 ky tu -> null', () {
      expect(Validators.password('123456'), isNull);
      expect(Validators.password('mat-khau-dai'), isNull);
    });
  });

  group('Validators.confirmPassword (8a/8d)', () {
    test('rong -> loi', () {
      expect(Validators.confirmPassword('', '123456'), isNotNull);
      expect(Validators.confirmPassword(null, '123456'), isNotNull);
    });

    test('khac mat khau goc -> loi', () {
      expect(Validators.confirmPassword('1234567', '123456'), isNotNull);
    });

    test('trung mat khau goc -> null', () {
      expect(Validators.confirmPassword('123456', '123456'), isNull);
    });
  });

  group('Validators.number (8a/8d)', () {
    test('rong -> loi', () {
      expect(Validators.number(''), isNotNull);
    });

    test('khong phai so -> loi', () {
      expect(Validators.number('abc'), isNotNull);
    });

    test('so hop le (int / double / am) -> null', () {
      expect(Validators.number('10'), isNull);
      expect(Validators.number('3.5'), isNull);
      expect(Validators.number(' -7 '), isNull);
    });
  });

  group('Validators.rating 1-10 (8a/8d)', () {
    test('rong -> loi', () {
      expect(Validators.rating(''), isNotNull);
    });

    test('khong phai so -> loi', () {
      expect(Validators.rating('hay'), isNotNull);
    });

    test('ngoai 1-10 -> loi', () {
      expect(Validators.rating('0'), isNotNull);
      expect(Validators.rating('11'), isNotNull);
    });

    test('bien 1 va 10 -> null (bien)', () {
      expect(Validators.rating('1'), isNull);
      expect(Validators.rating('10'), isNull);
      expect(Validators.rating('7'), isNull);
    });
  });

  group('Validators.merge (8a)', () {
    test('tat ca null -> null', () {
      expect(Validators.merge([null, null]), isNull);
    });

    test('gom nhieu loi thanh 1 chuoi', () {
      final out = Validators.merge(['Loi A', null, 'Loi B']);
      expect(out, contains('Loi A'));
      expect(out, contains('Loi B'));
    });
  });
}
