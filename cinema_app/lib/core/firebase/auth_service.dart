import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_service.dart';


class AuthService {
  AuthService._();

  static AuthService? _instance;

  static AuthService get instance {
    if (_instance == null) {
      _instance = AuthService._();
    }
    return _instance!;
  }

  FirebaseAuth get _auth => FirebaseAuth.instance;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw FirestoreException(e.code, _messageOf(e));
    } catch (e) {
      throw FirestoreException('unknown', 'Đăng nhập thất bại: $e');
    }
  }

  /// Tạo tài khoản mới.
  Future<UserCredential> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Ghi tên hiển thị vào profile (Auth tự quản lý email/mật khẩu)
      if (displayName != null && displayName.isNotEmpty) {
        await credential.user?.updateDisplayName(displayName);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw FirestoreException(e.code, _messageOf(e));
    } catch (e) {
      throw FirestoreException('unknown', 'Đăng ký thất bại: $e');
    }
  }

  /// Đăng nhập bằng Google — chỉ lấy email và tên, KHÔNG lấy danh bạ.
  ///
  /// Đây là ví dụ "privacy by design" nêu trong báo cáo Câu 9:
  /// app chỉ xin những quyền tối thiểu cần thiết.
  Future<UserCredential> signInWithGoogle() async {
    // TODO: thêm package google_sign_in, cần cấu hình SHA-1 trên Firebase Console.
    // Hiện tại chưa cài nên tạm báo lỗi rõ ràng thay vì crash.
    throw FirestoreException(
      'google-sign-in-not-installed',
      'Chưa cài package google_sign_in. Cần thêm dependency và cấu hình SHA-1.',
    );
  }

  /// Đăng xuất.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw FirestoreException('unknown', 'Đăng xuất thất bại: $e');
    }
  }

  /// Gửi email đặt lại mật khẩu.
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw FirestoreException(e.code, _messageOf(e));
    } catch (e) {
      throw FirestoreException('unknown', 'Gửi email thất bại: $e');
    }
  }

  /// Đổi mật khẩu (yêu cầu đã đăng nhập).
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw FirestoreException('not-authenticated', 'Chưa đăng nhập');
      }
      final email = user.email;
      if (email == null) {
        throw FirestoreException('no-email', 'Tài khoản không có email');
      }
      // Bắt buộc xác thực lại bằng mật khẩu cũ — không thể chỉ dựa vào
      // token đang có, tránh kẻ trộm token đổi mật khẩu người dùng.
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw FirestoreException(e.code, _messageOf(e));
    } catch (e) {
      throw FirestoreException('unknown', 'Đổi mật khẩu thất bại: $e');
    }
  }

  /// Xoá tài khoản (không khôi phục được).
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw FirestoreException('not-authenticated', 'Chưa đăng nhập');
      }
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw FirestoreException(e.code, _messageOf(e));
    } catch (e) {
      throw FirestoreException('unknown', 'Xoá tài khoản thất bại: $e');
    }
  }

  /// Người dùng hiện tại, null nếu chưa đăng nhập.
  User? get currentUser => _auth.currentUser;

  /// Đã đăng nhập chưa?
  bool get isLoggedIn => _auth.currentUser != null;

  /// Theo dõi trạng thái đăng nhập — tự cập nhật UI khi logout từ nơi khác.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Gửi lại email xác thực.
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirestoreException('not-authenticated', 'Chưa đăng nhập');
    }
    if (user.emailVerified) return;
    await user.sendEmailVerification();
  }

  /// Dịch mã lỗi của Firebase sang tiếng Việt.
  ///
  /// Firebase trả về mã như `wrong-password`, `invalid-email`... vô nghĩa
  /// với người dùng cuối. Chuyển sang thông báo tiếng Việt ở đây, không
  /// phải rải mã lỗi ra trong từng màn hình.
  String _messageOf(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hoá';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        // Cố tình gộp 3 mã thành 1 thông báo: nếu báo riêng "sai mật khẩu"
        // thì kẻ xấu dò được email nào đã có tài khoản.
        return 'Email hoặc mật khẩu không đúng';
      case 'email-already-in-use':
        return 'Email này đã được đăng ký';
      case 'weak-password':
        return 'Mật khẩu quá yếu (cần ít nhất 6 ký tự)';
      case 'too-many-requests':
        return 'Thử quá nhiều lần, vui lòng đợi vài phút';
      case 'network-request-failed':
        return 'Không có kết nối mạng';
      case 'requires-recent-login':
        return 'Phiên đăng nhập đã cũ, hãy đăng nhập lại';
      default:
        return e.message ?? 'Lỗi không xác định';
    }
  }
}