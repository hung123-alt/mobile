import 'package:cinema_app/core/utils/validators.dart';
import 'package:cinema_app/models/movie_model.dart';
import 'package:cinema_app/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dịch vụ Quản trị hệ thống (In-Memory) phục vụ kiểm thử đơn vị
/// cho Nhóm 5 – Quản trị hệ thống (US26 - US29).
class AdminSystemManagementService {
  final Map<int, Movie> _moviesById = {};
  final Map<int, User> _usersById = {};

  List<Movie> get movies => _moviesById.values.toList();

  void seedUsers(List<User> users) {
    for (final u in users) {
      _usersById[u.id] = u;
    }
  }

  /// US26: Quản trị viên thêm phim mới để cập nhật nội dung hệ thống
  ({Movie? movie, String? error}) addMovie({
    required User actor,
    required String title,
    required String slug,
    String? description,
    int? releaseYear,
  }) {
    if (!actor.getIsAdmin()) {
      return (
        movie: null,
        error: 'Truy cập bị từ chối: Chỉ quản trị viên mới được thêm phim',
      );
    }

    final titleErr = Validators.required(title, fieldName: 'Tên phim');
    if (titleErr != null) {
      return (movie: null, error: titleErr);
    }

    final slugErr = Validators.required(slug, fieldName: 'Slug phim');
    if (slugErr != null) {
      return (movie: null, error: slugErr);
    }

    final nextId = _moviesById.length + 1;
    final now = DateTime.now();
    final newMovie = Movie(
      id: nextId,
      name: title.trim(),
      description: description?.trim() ?? '',
      slug: slug.trim(),
      posterUrl: 'https://example.com/${slug.trim()}.jpg',
      bannerUrl: 'https://example.com/${slug.trim()}_banner.jpg',
      type: 'phim_le',
      status: 'ongoing',
      releaseYear: releaseYear ?? 2025,
      totalEpisodes: 1,
      viewCount: 0,
      avgRating: 0.0,
      ratingCount: 0,
      isFeatured: false,
      isVisible: true,
      scheduleDate: null,
      createdAt: now,
      updatedAt: now,
      genres: const [],
      countries: const [],
    );

    _moviesById[newMovie.id] = newMovie;
    return (movie: newMovie, error: null);
  }

  /// US27: Quản trị viên chỉnh sửa thông tin phim
  ({Movie? movie, String? error}) updateMovie({
    required User actor,
    required int movieId,
    required String newTitle,
    String? newDescription,
    String? newStatus,
  }) {
    if (!actor.getIsAdmin()) {
      return (
        movie: null,
        error: 'Truy cập bị từ chối: Chỉ quản trị viên mới được sửa phim',
      );
    }

    final existing = _moviesById[movieId];
    if (existing == null) {
      return (movie: null, error: 'Không tìm thấy bộ phim cần chỉnh sửa');
    }

    final titleErr = Validators.required(newTitle, fieldName: 'Tên phim');
    if (titleErr != null) {
      return (movie: null, error: titleErr);
    }

    final updated = Movie(
      id: existing.id,
      name: newTitle.trim(),
      description: newDescription?.trim() ?? existing.description,
      slug: existing.slug,
      posterUrl: existing.posterUrl,
      bannerUrl: existing.bannerUrl,
      type: existing.type,
      status: newStatus ?? existing.status,
      releaseYear: existing.releaseYear,
      totalEpisodes: existing.totalEpisodes,
      viewCount: existing.viewCount,
      avgRating: existing.avgRating,
      ratingCount: existing.ratingCount,
      isFeatured: existing.isFeatured,
      isVisible: existing.isVisible,
      scheduleDate: existing.scheduleDate,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
      genres: existing.genres,
      countries: existing.countries,
    );
    _moviesById[movieId] = updated;
    return (movie: updated, error: null);
  }

  /// US28: Quản trị viên xóa phim (có bước xác nhận & kiểm tra quyền Admin)
  ({bool deleted, String? error}) deleteMovie({
    required User actor,
    required int movieId,
    required bool isConfirmed,
  }) {
    if (!actor.getIsAdmin()) {
      return (
        deleted: false,
        error: 'Truy cập bị từ chối: Chỉ quản trị viên được phép xóa phim',
      );
    }

    if (!isConfirmed) {
      return (deleted: false, error: 'Đã hủy xóa phim do chưa xác nhận');
    }

    if (!_moviesById.containsKey(movieId)) {
      return (deleted: false, error: 'Phim không tồn tại trong hệ thống');
    }

    _moviesById.remove(movieId);
    return (deleted: true, error: null);
  }

  /// US29: Quản trị viên vô hiệu hóa hoặc kích hoạt lại tài khoản người dùng
  ({User? targetUser, String? error}) setAccountBanStatus({
    required User actor,
    required int targetUserId,
    required bool isBanned,
  }) {
    if (!actor.getIsAdmin()) {
      return (
        targetUser: null,
        error: 'Chỉ quản trị viên được thay đổi trạng thái tài khoản',
      );
    }

    if (actor.id == targetUserId) {
      return (
        targetUser: null,
        error: 'Quản trị viên không thể tự khóa tài khoản của chính mình',
      );
    }

    final target = _usersById[targetUserId];
    if (target == null) {
      return (targetUser: null, error: 'Không tìm thấy tài khoản người dùng');
    }

    final updated = target.copyWith(
      isBanned: isBanned,
      updatedAt: DateTime.now(),
    );
    _usersById[targetUserId] = updated;
    return (targetUser: updated, error: null);
  }

  /// Kiểm tra quyền thực hiện chức năng yêu cầu đăng nhập (chặn tài khoản bị khóa)
  ({bool allowed, String? error}) performAuthenticatedAction(User? user) {
    if (user == null) {
      return (allowed: false, error: 'Vui lòng đăng nhập để sử dụng chức năng');
    }
    if (user.isBanned) {
      return (
        allowed: false,
        error: 'Tài khoản đã bị vô hiệu hóa, không thể tiếp tục sử dụng',
      );
    }
    return (allowed: true, error: null);
  }
}

void main() {
  late AdminSystemManagementService adminService;

  final adminUser = User(
    id: 1,
    username: 'root_admin',
    email: 'admin@cinema.vn',
    avatarUrl: null,
    fullName: 'Quản Trị Hệ Thống',
    role: 'admin',
    isBanned: false,
    lastLogin: null,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  final normalUser = User(
    id: 2,
    username: 'khach_hang',
    email: 'user@cinema.vn',
    avatarUrl: null,
    fullName: 'Người Dùng Thường',
    role: 'user',
    isBanned: false,
    lastLogin: null,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    adminService = AdminSystemManagementService();
    adminService.seedUsers([adminUser, normalUser]);
  });

  group('Nhóm 5 – Quản trị hệ thống (US26 - US29)', () {
    // =========================================================================
    // US26: Là quản trị viên, tôi muốn thêm phim để cập nhật nội dung hệ thống
    // Tiêu chí: Dữ liệu hợp lệ được thêm; tài khoản không có quyền bị từ chối.
    // =========================================================================
    group('US26 - Quản trị viên thêm phim mới', () {
      test('Thêm phim thành công khi tài khoản có quyền Admin và dữ liệu hợp lệ', () {
        final res = adminService.addMovie(
          actor: adminUser,
          title: 'Mưa Đỏ',
          slug: 'mua-do',
          description: 'Phim lịch sử chiến tranh cách mạng',
          releaseYear: 2025,
        );

        expect(res.error, isNull);
        expect(res.movie, isNotNull);
        expect(res.movie!.getName(), 'Mưa Đỏ');
        expect(adminService.movies.length, 1);
      });

      test('Từ chối thêm phim khi tài khoản không phải là quản trị viên', () {
        final res = adminService.addMovie(
          actor: normalUser,
          title: 'Phim Trái Phép',
          slug: 'phim-trai-phep',
        );

        expect(res.movie, isNull);
        expect(
          res.error,
          'Truy cập bị từ chối: Chỉ quản trị viên mới được thêm phim',
        );
        expect(adminService.movies, isEmpty);
      });

      test('Từ chối thêm phim khi thiếu tên phim hoặc slug', () {
        final res = adminService.addMovie(
          actor: adminUser,
          title: '   ',
          slug: 'slug-hop-le',
        );

        expect(res.movie, isNull);
        expect(res.error, 'Tên phim không được để trống');
      });
    });

    // =========================================================================
    // US27: Là quản trị viên, tôi muốn chỉnh sửa thông tin phim để cập nhật nội dung
    // Tiêu chí: Thay đổi hợp lệ được lưu và hiển thị chính xác.
    // =========================================================================
    group('US27 - Quản trị viên chỉnh sửa thông tin phim', () {
      test('Lưu và hiển thị chính xác thông tin phim sau khi chỉnh sửa hợp lệ', () {
        final created = adminService.addMovie(
          actor: adminUser,
          title: 'Tên Phim Cũ',
          slug: 'ten-phim-cu',
          description: 'Mô tả ban đầu',
        );

        final updatedRes = adminService.updateMovie(
          actor: adminUser,
          movieId: created.movie!.id,
          newTitle: 'Tên Phim Đã Cập Nhật',
          newDescription: 'Mô tả mới chi tiết hơn',
          newStatus: 'completed',
        );

        expect(updatedRes.error, isNull);
        expect(updatedRes.movie, isNotNull);
        expect(updatedRes.movie!.getName(), 'Tên Phim Đã Cập Nhật');
        expect(updatedRes.movie!.getDescription(), 'Mô tả mới chi tiết hơn');
        expect(updatedRes.movie!.getStatusLabel(), 'Hoàn thành');
      });

      test('Từ chối chỉnh sửa khi người thực hiện không có quyền Admin hoặc tên rỗng', () {
        final created = adminService.addMovie(
          actor: adminUser,
          title: 'Phim Gốc',
          slug: 'phim-goc',
        );

        final unauthorized = adminService.updateMovie(
          actor: normalUser,
          movieId: created.movie!.id,
          newTitle: 'Bị Sửa Bởi User',
        );
        expect(unauthorized.movie, isNull);
        expect(unauthorized.error, contains('Chỉ quản trị viên'));

        final invalidTitle = adminService.updateMovie(
          actor: adminUser,
          movieId: created.movie!.id,
          newTitle: '',
        );
        expect(invalidTitle.movie, isNull);
        expect(invalidTitle.error, 'Tên phim không được để trống');
      });
    });

    // =========================================================================
    // US28: Là quản trị viên, tôi muốn xóa phim để quản lý kho nội dung
    // Tiêu chí: Có bước xác nhận; chỉ quản trị viên được phép thực hiện thao tác xóa.
    // =========================================================================
    group('US28 - Quản trị viên xóa phim', () {
      test('Yêu cầu xác nhận trước khi xóa và chỉ cho phép Admin thực hiện', () {
        final created = adminService.addMovie(
          actor: adminUser,
          title: 'Phim Cần Xóa',
          slug: 'phim-can-xoa',
        );
        final movieId = created.movie!.id;

        // Người dùng thường cố xóa -> bị từ chối
        final normalAttempt = adminService.deleteMovie(
          actor: normalUser,
          movieId: movieId,
          isConfirmed: true,
        );
        expect(normalAttempt.deleted, isFalse);
        expect(adminService.movies.length, 1);

        // Admin chưa xác nhận hộp thoại -> hủy xóa
        final unconfirmedAttempt = adminService.deleteMovie(
          actor: adminUser,
          movieId: movieId,
          isConfirmed: false,
        );
        expect(unconfirmedAttempt.deleted, isFalse);
        expect(adminService.movies.length, 1);

        // Admin đã xác nhận -> xóa thành công
        final confirmedDelete = adminService.deleteMovie(
          actor: adminUser,
          movieId: movieId,
          isConfirmed: true,
        );
        expect(confirmedDelete.deleted, isTrue);
        expect(adminService.movies, isEmpty);
      });
    });

    // =========================================================================
    // US29: Là quản trị viên, tôi muốn vô hiệu hóa hoặc kích hoạt lại tài khoản người dùng
    // Tiêu chí: Chỉ quản trị viên được thay đổi trạng thái tài khoản; tài khoản bị
    //           vô hiệu hóa không được tiếp tục sử dụng các chức năng yêu cầu đăng nhập.
    // =========================================================================
    group('US29 - Vô hiệu hóa và kích hoạt lại tài khoản người dùng', () {
      test('Chỉ Admin được khóa/mở khóa tài khoản và tài khoản bị khóa bị chặn truy cập', () {
        // 1. Người dùng thường không được phép thay đổi trạng thái tài khoản
        final unauthorizedBan = adminService.setAccountBanStatus(
          actor: normalUser,
          targetUserId: adminUser.id,
          isBanned: true,
        );
        expect(unauthorizedBan.targetUser, isNull);
        expect(
          unauthorizedBan.error,
          'Chỉ quản trị viên được thay đổi trạng thái tài khoản',
        );

        // 2. Admin vô hiệu hóa tài khoản người dùng thường
        final banRes = adminService.setAccountBanStatus(
          actor: adminUser,
          targetUserId: normalUser.id,
          isBanned: true,
        );
        expect(banRes.error, isNull);
        expect(banRes.targetUser!.isBanned, isTrue);

        // 3. Tài khoản bị vô hiệu hóa không được tiếp tục sử dụng chức năng yêu cầu đăng nhập
        final accessWhileBanned = adminService.performAuthenticatedAction(
          banRes.targetUser,
        );
        expect(accessWhileBanned.allowed, isFalse);
        expect(
          accessWhileBanned.error,
          'Tài khoản đã bị vô hiệu hóa, không thể tiếp tục sử dụng',
        );

        // 4. Admin kích hoạt lại tài khoản -> người dùng truy cập lại bình thường
        final unbanRes = adminService.setAccountBanStatus(
          actor: adminUser,
          targetUserId: normalUser.id,
          isBanned: false,
        );
        expect(unbanRes.error, isNull);
        expect(unbanRes.targetUser!.isBanned, isFalse);

        final accessAfterUnban = adminService.performAuthenticatedAction(
          unbanRes.targetUser,
        );
        expect(accessAfterUnban.allowed, isTrue);
      });
    });
  });
}
