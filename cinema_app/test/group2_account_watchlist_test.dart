import 'dart:convert';

import 'package:cinema_app/core/utils/validators.dart';
import 'package:cinema_app/models/movie_model.dart';
import 'package:cinema_app/models/user_model.dart';
import 'package:cinema_app/models/watchlist_item_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Movie _buildMovie({
  required int id,
  required String name,
  required String slug,
}) {
  return Movie(
    id: id,
    name: name,
    description: 'Mô tả phim $name',
    slug: slug,
    posterUrl: 'https://example.com/$slug.jpg',
    bannerUrl: 'https://example.com/${slug}_banner.jpg',
    type: 'phim_le',
    status: 'completed',
    releaseYear: 2024,
    totalEpisodes: 1,
    viewCount: 1000,
    avgRating: 8.5,
    ratingCount: 10,
    isFeatured: false,
    isVisible: true,
    scheduleDate: null,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    genres: const [],
    countries: const [],
  );
}

/// Mô phỏng kho dữ liệu Tài khoản & Yêu thích (In-Memory) phục vụ kiểm thử đơn vị
/// cho Nhóm 2 (US08 - US15) mà không phụ thuộc mạng hay Firebase trực tiếp.
class FakeAccountWatchlistStore {
  static const String tokenStorageKey = 'access_token';
  static const String userCacheStorageKey = 'user_cache';

  final Map<String, String> _passwordsByEmail = {};
  final Map<String, User> _usersByEmail = {};
  final List<WatchlistItem> _watchlist = [];
  User? currentUser;

  /// US08: Đăng ký tài khoản bằng email và mật khẩu
  ({User? user, String? error}) register({
    required String username,
    required String email,
    required String password,
    String? fullName,
  }) {
    final normalizedEmail = email.trim().toLowerCase();
    final emailErr = Validators.email(normalizedEmail);
    if (emailErr != null) {
      return (user: null, error: emailErr);
    }

    final passErr = Validators.password(password);
    if (passErr != null) {
      return (user: null, error: passErr);
    }

    if (username.trim().length < 3) {
      return (user: null, error: 'Username phải có ít nhất 3 ký tự');
    }

    if (_usersByEmail.containsKey(normalizedEmail)) {
      return (user: null, error: 'Email đã được sử dụng bởi tài khoản khác');
    }

    final newUser = User(
      id: _usersByEmail.length + 1,
      username: username.trim(),
      email: normalizedEmail,
      avatarUrl: null,
      fullName: fullName?.trim(),
      role: 'user',
      isBanned: false,
      lastLogin: DateTime(2026, 1, 1),
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    _usersByEmail[normalizedEmail] = newUser;
    _passwordsByEmail[normalizedEmail] = password;
    currentUser = newUser;
    return (user: newUser, error: null);
  }

  /// US09: Đăng nhập tài khoản
  ({User? user, String? error}) login({
    required String email,
    required String password,
  }) {
    final normalizedEmail = email.trim().toLowerCase();
    final emailErr = Validators.email(normalizedEmail);
    if (emailErr != null) {
      return (user: null, error: emailErr);
    }

    final storedUser = _usersByEmail[normalizedEmail];
    final storedPassword = _passwordsByEmail[normalizedEmail];

    if (storedUser == null || storedPassword != password) {
      return (user: null, error: 'Email hoặc mật khẩu không chính xác');
    }

    if (storedUser.isBanned) {
      return (
        user: null,
        error: 'Tài khoản của bạn đã bị khóa bởi quản trị viên',
      );
    }

    currentUser = storedUser;
    return (user: storedUser, error: null);
  }

  /// US10: Yêu cầu đặt lại mật khẩu
  ({bool sent, String message}) requestPasswordReset(String email) {
    final normalizedEmail = email.trim().toLowerCase();
    final emailErr = Validators.email(normalizedEmail);
    if (emailErr != null) {
      return (sent: false, message: emailErr);
    }

    if (!_usersByEmail.containsKey(normalizedEmail)) {
      return (
        sent: false,
        message: 'Không tìm thấy tài khoản với địa chỉ email này',
      );
    }

    return (
      sent: true,
      message: 'Đã gửi liên kết đặt lại mật khẩu tới $normalizedEmail',
    );
  }

  /// US11: Đăng xuất tài khoản
  Future<void> logout() async {
    currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenStorageKey);
    await prefs.remove(userCacheStorageKey);
  }

  /// US12: Chỉnh sửa tên hiển thị
  ({User? user, String? error}) updateDisplayName(String newFullName) {
    if (currentUser == null) {
      return (user: null, error: 'Vui lòng đăng nhập');
    }
    final nameErr = Validators.required(
      newFullName,
      fieldName: 'Tên hiển thị',
    );
    if (nameErr != null) {
      return (user: null, error: nameErr);
    }

    final updated = currentUser!.copyWith(
      fullName: newFullName.trim(),
      updatedAt: DateTime.now(),
    );
    _usersByEmail[updated.email] = updated;
    currentUser = updated;
    return (user: updated, error: null);
  }

  /// US13: Thêm phim vào danh sách yêu thích (không trùng lặp cho cùng tài khoản)
  bool addToWatchlist(int userId, Movie movie) {
    if (userId <= 0 || movie.id <= 0) return false;

    final alreadyExists = _watchlist.any(
      (item) => item.userId == userId && item.movieId == movie.id,
    );
    if (alreadyExists) {
      return false;
    }

    _watchlist.add(
      WatchlistItem(
        id: _watchlist.length + 1,
        userId: userId,
        movieId: movie.id,
        movie: movie,
        createdAt: DateTime.now(),
      ),
    );
    return true;
  }

  /// US14: Xóa phim khỏi danh sách yêu thích
  bool removeFromWatchlist(int userId, int movieId) {
    final beforeCount = _watchlist.length;
    _watchlist.removeWhere(
      (item) => item.userId == userId && item.movieId == movieId,
    );
    return _watchlist.length < beforeCount;
  }

  /// US15: Xem danh sách phim yêu thích của tài khoản hiện tại
  List<WatchlistItem> getWatchlistForUser(int userId) {
    return _watchlist.where((item) => item.userId == userId).toList();
  }
}

void main() {
  late FakeAccountWatchlistStore store;

  final sampleMovieA = _buildMovie(
    id: 101,
    name: 'Mai',
    slug: 'mai',
  );

  final sampleMovieB = _buildMovie(
    id: 102,
    name: 'Lật Mặt 7: Một Điều Ước',
    slug: 'lat-mat-7',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = FakeAccountWatchlistStore();
  });

  group('Nhóm 2 – Tài khoản và danh sách yêu thích (US08 - US15)', () {
    // =========================================================================
    // US08: Là khách, tôi muốn đăng ký tài khoản bằng email và mật khẩu
    // Tiêu chí: Chấp nhận dữ liệu hợp lệ; thông báo khi dữ liệu không hợp lệ
    //           hoặc email đã được sử dụng.
    // =========================================================================
    group('US08 - Đăng ký tài khoản bằng email và mật khẩu', () {
      test('Chấp nhận dữ liệu hợp lệ và khởi tạo User thành công', () {
        final result = store.register(
          username: 'nguyenvana',
          email: 'NguyenVanA@gmail.com',
          password: 'password123',
          fullName: 'Nguyễn Văn A',
        );

        expect(result.error, isNull);
        expect(result.user, isNotNull);
        expect(result.user!.email, 'nguyenvana@gmail.com');
        expect(result.user!.username, 'nguyenvana');
        expect(result.user!.getDisplayName(), 'Nguyễn Văn A');
        expect(result.user!.isBanned, isFalse);
      });

      test('Thông báo lỗi khi email không đúng định dạng hoặc mật khẩu quá ngắn', () {
        final invalidEmailRes = store.register(
          username: 'user1',
          email: 'email_khong_hop_le',
          password: 'password123',
        );
        expect(invalidEmailRes.user, isNull);
        expect(invalidEmailRes.error, 'Email không đúng định dạng');

        final shortPassRes = store.register(
          username: 'user1',
          email: 'user1@gmail.com',
          password: '123',
        );
        expect(shortPassRes.user, isNull);
        expect(shortPassRes.error, 'Mật khẩu phải có ít nhất 6 ký tự');
      });

      test('Từ chối đăng ký và thông báo khi email đã được sử dụng', () {
        store.register(
          username: 'first_user',
          email: 'duplicate@gmail.com',
          password: 'password123',
        );

        final duplicateRes = store.register(
          username: 'second_user',
          email: 'DUPLICATE@gmail.com',
          password: 'anotherPassword',
        );

        expect(duplicateRes.user, isNull);
        expect(
          duplicateRes.error,
          'Email đã được sử dụng bởi tài khoản khác',
        );
      });
    });

    // =========================================================================
    // US09: Là người dùng, tôi muốn đăng nhập để truy cập tài khoản của mình
    // Tiêu chí: Đăng nhập thành công với thông tin hợp lệ; từ chối thông tin sai
    //           hoặc tài khoản không được phép truy cập.
    // =========================================================================
    group('US09 - Đăng nhập tài khoản', () {
      test('Đăng nhập thành công với email và mật khẩu hợp lệ', () {
        store.register(
          username: 'member01',
          email: 'member01@cinema.vn',
          password: 'secretPassword',
        );
        store.currentUser = null;

        final loginRes = store.login(
          email: 'member01@cinema.vn',
          password: 'secretPassword',
        );

        expect(loginRes.error, isNull);
        expect(loginRes.user, isNotNull);
        expect(store.currentUser?.email, 'member01@cinema.vn');
      });

      test('Từ chối đăng nhập khi sai mật khẩu hoặc tài khoản không tồn tại', () {
        store.register(
          username: 'member01',
          email: 'member01@cinema.vn',
          password: 'secretPassword',
        );

        final wrongPassRes = store.login(
          email: 'member01@cinema.vn',
          password: 'wrongPassword',
        );
        expect(wrongPassRes.user, isNull);
        expect(wrongPassRes.error, 'Email hoặc mật khẩu không chính xác');

        final unknownEmailRes = store.login(
          email: 'nobody@cinema.vn',
          password: 'secretPassword',
        );
        expect(unknownEmailRes.user, isNull);
        expect(unknownEmailRes.error, 'Email hoặc mật khẩu không chính xác');
      });

      test('Từ chối đăng nhập khi tài khoản bị khóa (isBanned == true)', () {
        final reg = store.register(
          username: 'banned_user',
          email: 'banned@cinema.vn',
          password: 'password123',
        );
        final bannedUser = reg.user!.copyWith(isBanned: true);
        store._usersByEmail['banned@cinema.vn'] = bannedUser;
        store.currentUser = null;

        final loginRes = store.login(
          email: 'banned@cinema.vn',
          password: 'password123',
        );

        expect(loginRes.user, isNull);
        expect(
          loginRes.error,
          'Tài khoản của bạn đã bị khóa bởi quản trị viên',
        );
      });
    });

    // =========================================================================
    // US10: Là người dùng, tôi muốn yêu cầu đặt lại mật khẩu để khôi phục quyền truy cập
    // Tiêu chí: Gửi yêu cầu đặt lại mật khẩu và phản hồi trạng thái xử lý.
    // =========================================================================
    group('US10 - Yêu cầu đặt lại mật khẩu', () {
      test('Gửi yêu cầu đặt lại mật khẩu thành công cho email hợp lệ đã đăng ký', () {
        store.register(
          username: 'forgot_user',
          email: 'forgot@cinema.vn',
          password: 'oldPassword',
        );

        final response = store.requestPasswordReset('forgot@cinema.vn');

        expect(response.sent, isTrue);
        expect(
          response.message,
          contains('Đã gửi liên kết đặt lại mật khẩu'),
        );
      });

      test('Phản hồi lỗi khi email không hợp lệ hoặc chưa đăng ký', () {
        final invalidFormat = store.requestPasswordReset('not-an-email');
        expect(invalidFormat.sent, isFalse);
        expect(invalidFormat.message, 'Email không đúng định dạng');

        final notFound = store.requestPasswordReset('unregistered@cinema.vn');
        expect(notFound.sent, isFalse);
        expect(
          notFound.message,
          'Không tìm thấy tài khoản với địa chỉ email này',
        );
      });
    });

    // =========================================================================
    // US11: Là người dùng, tôi muốn đăng xuất để kết thúc phiên sử dụng
    // Tiêu chí: Phiên đăng nhập kết thúc và giao diện cập nhật trạng thái chưa đăng nhập.
    // =========================================================================
    group('US11 - Đăng xuất kết thúc phiên sử dụng', () {
      test('Xóa thông tin phiên đăng nhập và cache trong SharedPreferences', () async {
        final reg = store.register(
          username: 'active_user',
          email: 'active@cinema.vn',
          password: 'password123',
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          FakeAccountWatchlistStore.tokenStorageKey,
          reg.user!.id.toString(),
        );
        await prefs.setString(
          FakeAccountWatchlistStore.userCacheStorageKey,
          jsonEncode(reg.user!.toJson()),
        );

        expect(store.currentUser, isNotNull);
        expect(
          prefs.getString(FakeAccountWatchlistStore.tokenStorageKey),
          isNotNull,
        );

        await store.logout();

        expect(store.currentUser, isNull);
        expect(
          prefs.getString(FakeAccountWatchlistStore.tokenStorageKey),
          isNull,
        );
        expect(
          prefs.getString(FakeAccountWatchlistStore.userCacheStorageKey),
          isNull,
        );
      });
    });

    // =========================================================================
    // US12: Là người dùng, tôi muốn chỉnh sửa tên hiển thị để cập nhật thông tin cá nhân
    // Tiêu chí: Tên hợp lệ được cập nhật và hiển thị chính xác.
    // =========================================================================
    group('US12 - Chỉnh sửa tên hiển thị', () {
      test('Cập nhật tên hiển thị hợp lệ và phản ánh qua getDisplayName & getInitials', () {
        store.register(
          username: 'tranb',
          email: 'tranb@cinema.vn',
          password: 'password123',
          fullName: 'Trần B',
        );

        final updateRes = store.updateDisplayName('Nguyễn Bảo Ngọc');

        expect(updateRes.error, isNull);
        expect(updateRes.user, isNotNull);
        expect(updateRes.user!.getDisplayName(), 'Nguyễn Bảo Ngọc');
        expect(updateRes.user!.getInitials(), 'N');
      });

      test('Từ chối cập nhật khi tên hiển thị để trống', () {
        store.register(
          username: 'tranb',
          email: 'tranb@cinema.vn',
          password: 'password123',
          fullName: 'Trần B',
        );

        final emptyRes = store.updateDisplayName('   ');

        expect(emptyRes.user, isNull);
        expect(emptyRes.error, 'Tên hiển thị không được để trống');
        expect(store.currentUser!.getDisplayName(), 'Trần B');
      });
    });

    // =========================================================================
    // US13: Là người dùng, tôi muốn thêm phim vào danh sách yêu thích
    // Tiêu chí: Phim được lưu cho đúng tài khoản và không bị trùng lặp.
    // =========================================================================
    group('US13 - Thêm phim vào danh sách yêu thích', () {
      test('Lưu phim cho đúng tài khoản và ngăn chặn thêm trùng lặp', () {
        final addedFirstTime = store.addToWatchlist(1, sampleMovieA);
        final addedDuplicate = store.addToWatchlist(1, sampleMovieA);

        expect(addedFirstTime, isTrue);
        expect(addedDuplicate, isFalse);

        final user1List = store.getWatchlistForUser(1);
        expect(user1List.length, 1);
        expect(user1List.first.movieId, 101);
        expect(user1List.first.userId, 1);
      });
    });

    // =========================================================================
    // US14: Là người dùng, tôi muốn xóa phim khỏi danh sách yêu thích
    // Tiêu chí: Phim được chọn được loại khỏi danh sách yêu thích.
    // =========================================================================
    group('US14 - Xóa phim khỏi danh sách yêu thích', () {
      test('Loại bỏ đúng phim được chọn mà không ảnh hưởng phim khác', () {
        store.addToWatchlist(1, sampleMovieA);
        store.addToWatchlist(1, sampleMovieB);

        final removed = store.removeFromWatchlist(1, sampleMovieA.id);

        expect(removed, isTrue);
        final remaining = store.getWatchlistForUser(1);
        expect(remaining.length, 1);
        expect(remaining.first.movieId, sampleMovieB.id);
      });
    });

    // =========================================================================
    // US15: Là người dùng, tôi muốn xem danh sách phim yêu thích
    // Tiêu chí: Chỉ hiển thị phim thuộc danh sách yêu thích của tài khoản hiện tại.
    // =========================================================================
    group('US15 - Xem danh sách phim yêu thích theo tài khoản', () {
      test('Chỉ trả về danh sách phim yêu thích thuộc tài khoản đang truy vấn', () {
        store.addToWatchlist(10, sampleMovieA);
        store.addToWatchlist(20, sampleMovieB);

        final currentList = store.getWatchlistForUser(10);

        expect(currentList.length, 1);
        expect(currentList.first.userId, 10);
        expect(currentList.first.movie?.name, 'Mai');
        expect(currentList.any((item) => item.userId == 20), isFalse);
      });
    });
  });
}
