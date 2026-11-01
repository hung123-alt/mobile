import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../core/firebase/collection_names.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider._();

  static final AuthProvider instance = AuthProvider._();
  factory AuthProvider() => instance;

  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool _isConfigNotFoundError(Object e) {
    final msg = e.toString().toUpperCase();
    return msg.contains('CONFIGURATION_NOT_FOUND') ||
        msg.contains('OPERATION-NOT-ALLOWED') ||
        msg.contains('OPERATION_NOT_ALLOWED');
  }

  /// Kiểm tra trạng thái đăng nhập khi mở app
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedUserId = prefs.getInt('auth_user_id');
      final cachedEmail = prefs.getString('auth_user_email');

      // 1. Nếu có Firebase Auth currentUser
      final fbUser = _auth.currentUser;
      if (fbUser != null && fbUser.email != null) {
        final user = await _fetchUserFromFirestore(fbUser.email!);
        if (user != null && !user.isBanned) {
          _currentUser = user;
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      // 2. Nếu có cached ID/Email từ SharedPreferences
      if (cachedEmail != null && cachedEmail.isNotEmpty) {
        final user = await _fetchUserFromFirestore(cachedEmail);
        if (user != null && !user.isBanned) {
          _currentUser = user;
          _isLoading = false;
          notifyListeners();
          return;
        }
      } else if (cachedUserId != null) {
        final doc = await _firestore
            .collection(CollectionNames.users)
            .doc(cachedUserId.toString())
            .get();
        if (doc.exists && doc.data() != null) {
          final user = User.fromJson(doc.data()!);
          if (!user.isBanned) {
            _currentUser = user;
            _isLoading = false;
            notifyListeners();
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('checkAuthStatus error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Đăng nhập bằng Email hoặc Username + Mật khẩu
  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final input = identifier.trim();
    if (input.isEmpty || password.isEmpty) {
      _errorMessage = 'Vui lòng nhập đầy đủ thông tin đăng nhập';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      // 1. Tìm user trong Firestore theo email hoặc username
      Map<String, dynamic>? userData;
      String? userDocId;

      var query = await _firestore
          .collection(CollectionNames.users)
          .where('email', isEqualTo: input)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        query = await _firestore
            .collection(CollectionNames.users)
            .where('username', isEqualTo: input)
            .limit(1)
            .get();
      }

      if (query.docs.isNotEmpty) {
        userData = query.docs.first.data();
        userDocId = query.docs.first.id;
      }

      // Kiểm tra tài khoản có bị khoá không
      if (userData != null) {
        final isBanned =
            userData['isBanned'] == true || userData['is_banned'] == 1;
        if (isBanned) {
          _errorMessage =
              'Tài khoản của bạn đã bị khóa. Vui lòng liên hệ quản trị viên.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      final targetEmail =
          userData != null ? (userData['email'] as String? ?? input) : input;

      // 2. Xác thực DUY NHẤT bằng Firebase Authentication (mật khẩu đã hash+salt).
      // KHÔNG đọc/so sánh `password` plaintext trong Firestore — tránh lộ mật khẩu.
      bool verifiedByFirebaseAuth = false;
      try {
        await _auth.signInWithEmailAndPassword(
          email: targetEmail,
          password: password,
        );
        verifiedByFirebaseAuth = true;
      } on fb_auth.FirebaseAuthException catch (authEx) {
        if (authEx.code == 'invalid-email') {
          _errorMessage = 'Địa chỉ email không hợp lệ';
          _isLoading = false;
          notifyListeners();
          return false;
        } else if (authEx.code == 'user-disabled') {
          _errorMessage = 'Tài khoản đã bị vô hiệu hóa';
          _isLoading = false;
          notifyListeners();
          return false;
        } else {
          // Firebase Auth bật Email Enumeration Protection nên user migrate
          // từ MySQL chưa có trên Auth sẽ trả 'invalid-credential'.
          if (userData == null) {
            _errorMessage = 'Tài khoản hoặc mật khẩu không chính xác';
            _isLoading = false;
            notifyListeners();
            return false;
          }

          // User có hồ sơ Firestore nhưng chưa có trên Firebase Auth:
          // tạo tài khoản Auth bằng ĐÚNG mật khẩu user vừa nhập (không đọc
          // plaintext cũ), để từ nay xác thực qua Firebase Auth.
          try {
            await _auth.createUserWithEmailAndPassword(
              email: targetEmail,
              password: password,
            );
            verifiedByFirebaseAuth = true;
          } catch (_) {
            _errorMessage = 'Tài khoản hoặc mật khẩu không chính xác';
            _isLoading = false;
            notifyListeners();
            return false;
          }
        }
      } catch (e) {
        // Trường hợp lỗi khác từ Firebase Auth (như CONFIGURATION_NOT_FOUND trên Web)
        _errorMessage = 'Tài khoản hoặc mật khẩu không chính xác';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 3. Nếu chưa có userData trong Firestore nhưng đăng nhập thành công qua Firebase Auth
      // Bảo mật: KHÔNG lưu plaintext `password` vào Firestore.
      // Mật khẩu chỉ nằm trong Firebase Auth (đã hash + salt bởi Firebase).
      if (userData == null && verifiedByFirebaseAuth) {
        final fbUser = _auth.currentUser;
        if (fbUser != null) {
          final nextId = await _getNextUserId();
          final nowIso = DateTime.now().toIso8601String();
          userData = {
            'id': nextId,
            'username': fbUser.displayName ?? input.split('@').first,
            'email': fbUser.email ?? input,
            'role': 'user',
            'isBanned': false,
            'is_banned': 0,
            'createdAt': nowIso,
            'created_at': nowIso,
            'updatedAt': nowIso,
            'updated_at': nowIso,
            'lastLogin': nowIso,
            'last_login': nowIso,
          };
          userDocId = nextId.toString();
          await _firestore
              .collection(CollectionNames.users)
              .doc(userDocId)
              .set(userData);
        }
      }

      if (userData != null) {
        final nowIso = DateTime.now().toIso8601String();
        if (userDocId != null) {
          // Bảo mật: chỉ cập nhật lastLogin, KHÔNG ghi `password` plaintext.
          _firestore.collection(CollectionNames.users).doc(userDocId).set({
            'lastLogin': nowIso,
            'last_login': nowIso,
          }, SetOptions(merge: true)).catchError((_) {});
        }

        _currentUser = User.fromJson(userData);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('auth_user_id', _currentUser!.id);
        await prefs.setString('auth_user_email', _currentUser!.email);
        await prefs.setString('auth_user_name', _currentUser!.username);
        await prefs.setString('auth_user_role', _currentUser!.role);

        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = 'Không tìm thấy thông tin người dùng';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      _errorMessage = 'Đăng nhập thất bại: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Đăng ký tài khoản mới (lưu vào Firestore `users` và đồng bộ Firebase Auth nếu đã bật)
  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final cleanUsername = username.trim();
    final cleanEmail = email.trim();

    if (cleanUsername.isEmpty || cleanEmail.isEmpty || password.isEmpty) {
      _errorMessage = 'Vui lòng điền đầy đủ các trường thông tin';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (password.length < 6) {
      _errorMessage = 'Mật khẩu phải có ít nhất 6 ký tự';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      // 1. Kiểm tra username đã tồn tại trong Firestore chưa
      final existingUsername = await _firestore
          .collection(CollectionNames.users)
          .where('username', isEqualTo: cleanUsername)
          .limit(1)
          .get();

      if (existingUsername.docs.isNotEmpty) {
        _errorMessage = 'Tên đăng nhập này đã có người sử dụng';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 2. Kiểm tra email đã tồn tại trong Firestore chưa
      final existingEmail = await _firestore
          .collection(CollectionNames.users)
          .where('email', isEqualTo: cleanEmail)
          .limit(1)
          .get();

      if (existingEmail.docs.isNotEmpty) {
        _errorMessage = 'Email này đã được đăng ký tài khoản';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 3. Thử tạo tài khoản trên Firebase Auth (nếu đã bật trên Console)
      try {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
        await credential.user?.updateDisplayName(cleanUsername);
      } on fb_auth.FirebaseAuthException catch (authEx) {
        if (authEx.code == 'email-already-in-use') {
          _errorMessage = 'Email này đã được đăng ký tài khoản';
          _isLoading = false;
          notifyListeners();
          return false;
        } else if (authEx.code == 'invalid-email') {
          _errorMessage = 'Địa chỉ email không đúng định dạng';
          _isLoading = false;
          notifyListeners();
          return false;
        } else if (authEx.code == 'weak-password') {
          _errorMessage = 'Mật khẩu quá yếu, vui lòng chọn mật khẩu mạnh hơn';
          _isLoading = false;
          notifyListeners();
          return false;
        } else if (!_isConfigNotFoundError(authEx)) {
          debugPrint('FirebaseAuth register warning: ${authEx.code} - ${authEx.message}');
        }
      } catch (e) {
        // Nếu Firebase Auth chưa bật (CONFIGURATION_NOT_FOUND), vẫn tiếp tục lưu vào Firestore
        debugPrint('FirebaseAuth register skipped (using Firestore): $e');
      }

      // 4. Lưu hồ sơ mới vào Firestore collection `users`.
      // Bảo mật: KHÔNG lưu plaintext `password`. Mật khẩu chỉ nằm trong
      // Firebase Auth (đã hash + salt bởi Firebase).
      final nextId = await _getNextUserId();
      final now = DateTime.now().toIso8601String();

      final newUserData = <String, dynamic>{
        'id': nextId,
        'username': cleanUsername,
        'email': cleanEmail,
        'avatarUrl': null,
        'avatar_url': null,
        'role': 'user',
        'isBanned': false,
        'is_banned': 0,
        'createdAt': now,
        'created_at': now,
        'updatedAt': now,
        'updated_at': now,
        'lastLogin': now,
        'last_login': now,
      };

      await _firestore
          .collection(CollectionNames.users)
          .doc(nextId.toString())
          .set(newUserData);

      _currentUser = User.fromJson(newUserData);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('auth_user_id', nextId);
      await prefs.setString('auth_user_email', cleanEmail);
      await prefs.setString('auth_user_name', cleanUsername);
      await prefs.setString('auth_user_role', 'user');

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Register error: $e');
      _errorMessage = 'Đăng ký thất bại: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Gửi email đặt lại mật khẩu qua Firebase Auth (Phương án 1: deep link).
  Future<bool> sendPasswordReset(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty) {
      _errorMessage = 'Vui lòng nhập địa chỉ email';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      // 1. Kiểm tra email có trong collection `users` của Firestore không
      final snap = await _firestore
          .collection(CollectionNames.users)
          .where('email', isEqualTo: cleanEmail)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        _errorMessage = 'Email này chưa được đăng ký tài khoản';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 2. Gửi email đặt lại mật khẩu qua Firebase Auth (Phương án 1).
      // Không tự tạo user với mật khẩu đoán trước, không lưu plaintext.
      // Trên web KHÔNG kèm ActionCodeSettings (Firebase bắt url https
      // whitelist; web bấm link reset trên trang mặc định của Firebase).
      // Trên mobile kèm settings với url https đã whitelist, app bắt link
      // bằng DeepLinkService để tách oobCode.
      if (kIsWeb) {
        await _auth.sendPasswordResetEmail(email: cleanEmail);
      } else {
        await _auth.sendPasswordResetEmail(
          email: cleanEmail,
          actionCodeSettings: fb_auth.ActionCodeSettings(
            url: AppConstants.resetContinueUrl,
            handleCodeInApp: true,
            androidPackageName: AppConstants.androidPackageName,
            androidInstallApp: false,
            iOSBundleId: AppConstants.iosBundleId,
          ),
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on fb_auth.FirebaseAuthException catch (e) {
      if (_isConfigNotFoundError(e)) {
        _errorMessage =
            'Chưa bật Email/Password trong mục Authentication trên Firebase Console. Vui lòng bật để gửi email!';
      } else {
        switch (e.code) {
          case 'invalid-email':
            _errorMessage = 'Địa chỉ email không hợp lệ';
            break;
          case 'user-not-found':
            _errorMessage = 'Email này chưa được đăng ký tài khoản';
            break;
          case 'too-many-requests':
            _errorMessage =
                'Thao tác quá nhiều lần, vui lòng thử lại sau ít phút';
            break;
          case 'network-request-failed':
            _errorMessage =
                'Lỗi kết nối mạng, vui lòng kiểm tra lại đường truyền';
            break;
          default:
            _errorMessage =
                'Không thể gửi email đặt lại mật khẩu: ${e.message ?? e.code}';
        }
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('sendPasswordReset error: $e');
      if (_isConfigNotFoundError(e)) {
        _errorMessage =
            'Chưa bật Email/Password trong mục Authentication trên Firebase Console. Vui lòng bật để gửi email!';
      } else {
        _errorMessage = 'Đã xảy ra lỗi khi gửi liên kết đặt lại mật khẩu';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Kiểm tra mã `oobCode` từ deep link còn hiệu lực không (Phương án 1).
  /// Trả về email của tài khoản xin reset để hiển thị lên UI.
  Future<String?> verifyPasswordResetCode(String oobCode) async {
    try {
      final email = await _auth.verifyPasswordResetCode(oobCode);
      return email;
    } on fb_auth.FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-action-code':
        case 'expired-action-code':
          _errorMessage =
              'Liên kết đã hết hạn hoặc đã được sử dụng. Vui lòng yêu cầu gửi lại email.';
          break;
        case 'network-request-failed':
          _errorMessage = 'Không có kết nối mạng, vui lòng thử lại.';
          break;
        default:
          _errorMessage = e.message ?? 'Mã đặt lại mật khẩu không hợp lệ.';
      }
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('verifyPasswordResetCode error: $e');
      _errorMessage = 'Mã đặt lại mật khẩu không hợp lệ.';
      notifyListeners();
      return null;
    }
  }

  /// Đặt mật khẩu mới bằng mã `oobCode` (Phương án 1).
  /// Gọi thẳng Firebase Auth `confirmPasswordReset` — mật khẩu mới chỉ nằm
  /// trong Auth (hash + salt), KHÔNG lưu plaintext vào Firestore.
  Future<bool> confirmPasswordReset({
    required String oobCode,
    required String newPassword,
  }) async {
    if (newPassword.length < 6) {
      _errorMessage = 'Mật khẩu mới phải có ít nhất 6 ký tự';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _auth.confirmPasswordReset(
        code: oobCode,
        newPassword: newPassword,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on fb_auth.FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-action-code':
        case 'expired-action-code':
          _errorMessage =
              'Liên kết đã hết hạn hoặc đã được sử dụng. Vui lòng yêu cầu gửi lại email.';
          break;
        case 'weak-password':
          _errorMessage = 'Mật khẩu quá yếu (cần ít nhất 6 ký tự).';
          break;
        case 'network-request-failed':
          _errorMessage = 'Không có kết nối mạng, vui lòng thử lại.';
          break;
        default:
          _errorMessage =
              'Không thể đặt lại mật khẩu: ${e.message ?? e.code}';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('confirmPasswordReset error: $e');
      _errorMessage = 'Đã xảy ra lỗi khi đặt lại mật khẩu.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Cập nhật thông tin cá nhân của người dùng lên Firestore
  Future<bool> updateProfile({
    required String username,
    String? avatarUrl,
    String? fullName,
    String? phone,
    String? birthDate,
    String? gender,
    String? bio,
  }) async {
    if (_currentUser == null) {
      _errorMessage = 'Vui lòng đăng nhập để cập nhật thông tin';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final cleanUsername = username.trim();
    if (cleanUsername.length < 3) {
      _errorMessage = 'Tên đăng nhập phải có ít nhất 3 ký tự';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      if (cleanUsername != _currentUser!.username) {
        final existingUsername = await _firestore
            .collection(CollectionNames.users)
            .where('username', isEqualTo: cleanUsername)
            .limit(1)
            .get();

        if (existingUsername.docs.isNotEmpty) {
          final foundId = existingUsername.docs.first.data()['id'];
          if (foundId != _currentUser!.id) {
            _errorMessage = 'Tên đăng nhập này đã có người sử dụng';
            _isLoading = false;
            notifyListeners();
            return false;
          }
        }
      }

      String docId = _currentUser!.id.toString();
      final docSnap =
          await _firestore.collection(CollectionNames.users).doc(docId).get();
      if (!docSnap.exists) {
        final byEmail = await _firestore
            .collection(CollectionNames.users)
            .where('email', isEqualTo: _currentUser!.email)
            .limit(1)
            .get();
        if (byEmail.docs.isNotEmpty) {
          docId = byEmail.docs.first.id;
        }
      }

      final now = DateTime.now();
      final nowIso = now.toIso8601String();
      final cleanAvatar = (avatarUrl != null && avatarUrl.trim().isNotEmpty)
          ? avatarUrl.trim()
          : null;
      final cleanFullName = (fullName != null && fullName.trim().isNotEmpty)
          ? fullName.trim()
          : null;
      final cleanPhone =
          (phone != null && phone.trim().isNotEmpty) ? phone.trim() : null;
      final cleanBirthDate = (birthDate != null && birthDate.trim().isNotEmpty)
          ? birthDate.trim()
          : null;
      final cleanGender =
          (gender != null && gender.trim().isNotEmpty) ? gender.trim() : null;
      final cleanBio =
          (bio != null && bio.trim().isNotEmpty) ? bio.trim() : null;

      final updateData = <String, dynamic>{
        'username': cleanUsername,
        'avatarUrl': cleanAvatar,
        'avatar_url': cleanAvatar,
        'fullName': cleanFullName,
        'full_name': cleanFullName,
        'phone': cleanPhone,
        'birthDate': cleanBirthDate,
        'birth_date': cleanBirthDate,
        'gender': cleanGender,
        'bio': cleanBio,
        'updatedAt': nowIso,
        'updated_at': nowIso,
      };

      await _firestore
          .collection(CollectionNames.users)
          .doc(docId)
          .set(updateData, SetOptions(merge: true));

      final fbUser = _auth.currentUser;
      if (fbUser != null) {
        try {
          await fbUser.updateDisplayName(cleanFullName ?? cleanUsername);
          if (cleanAvatar != null) {
            await fbUser.updatePhotoURL(cleanAvatar);
          }
        } catch (_) {}
      }

      _currentUser = _currentUser!.copyWith(
        username: cleanUsername,
        avatarUrl: cleanAvatar,
        clearAvatar: cleanAvatar == null,
        fullName: cleanFullName ?? '',
        phone: cleanPhone ?? '',
        birthDate: cleanBirthDate ?? '',
        gender: cleanGender ?? '',
        bio: cleanBio ?? '',
        updatedAt: now,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_user_name', cleanUsername);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('updateProfile error: $e');
      _errorMessage = 'Cập nhật thông tin thất bại: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Đổi mật khẩu — chỉ dùng Firebase Auth (không lưu plaintext vào Firestore).
  ///
  /// Bắt buộc reauthenticate bằng mật khẩu cũ: tránh kẻ trộm token session
  /// đổi mật khẩu người dùng mà không biết mật khẩu hiện tại.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) {
      _errorMessage = 'Vui lòng đăng nhập để đổi mật khẩu';
      notifyListeners();
      return false;
    }

    if (newPassword.length < 6) {
      _errorMessage = 'Mật khẩu mới phải có ít nhất 6 ký tự';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final email = _currentUser!.email;

      // Thử cập nhật trên Firebase Auth nếu đã bật
      try {
        final fbUser = _auth.currentUser;
        if (fbUser != null) {
          final cred = fb_auth.EmailAuthProvider.credential(
            email: email,
            password: currentPassword,
          );
          await fbUser.reauthenticateWithCredential(cred);
          await fbUser.updatePassword(newPassword);
        } else {
          final userCred = await _auth.signInWithEmailAndPassword(
            email: email,
            password: currentPassword,
          );
          await userCred.user?.updatePassword(newPassword);
        }
      } on fb_auth.FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          _errorMessage = 'Mật khẩu hiện tại không chính xác';
          _isLoading = false;
          notifyListeners();
          return false;
        } else if (!_isConfigNotFoundError(e) && e.code != 'user-not-found') {
          debugPrint('FirebaseAuth changePassword warning: ${e.code}');
        } else {
          _errorMessage = 'Mật khẩu hiện tại không chính xác';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } catch (_) {
        _errorMessage = 'Mật khẩu hiện tại không chính xác';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Chỉ chạm lastLogin/updatedAt — KHÔNG lưu `password` plaintext.
      final nowIso = DateTime.now().toIso8601String();
      try {
        await _firestore
            .collection(CollectionNames.users)
            .doc(_currentUser!.id.toString())
            .set({
          'updatedAt': nowIso,
          'updated_at': nowIso,
        }, SetOptions(merge: true));
      } catch (_) {}

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('changePassword error: $e');
      _errorMessage = 'Đã xảy ra lỗi khi đổi mật khẩu';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Đăng xuất
  Future<void> logout() async {
    try {
      await _auth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_user_id');
      await prefs.remove('auth_user_email');
      await prefs.remove('auth_user_name');
      await prefs.remove('auth_user_role');
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      _currentUser = null;
      notifyListeners();
    }
  }

  /// Helper lấy user từ Firestore theo email
  Future<User?> _fetchUserFromFirestore(String email) async {
    try {
      final snap = await _firestore
          .collection(CollectionNames.users)
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        return User.fromJson(snap.docs.first.data());
      }
    } catch (e) {
      debugPrint('_fetchUserFromFirestore error: $e');
    }
    return null;
  }

  /// Helper tính ID tăng dần tiếp theo cho user mới
  Future<int> _getNextUserId() async {
    try {
      final snap = await _firestore
          .collection(CollectionNames.users)
          .orderBy('id', descending: true)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final maxId = snap.docs.first.data()['id'];
        if (maxId is int) return maxId + 1;
        if (maxId is num) return maxId.toInt() + 1;
      }
    } catch (e) {
      debugPrint('Error getting next user id: $e');
    }
    return 12; // Mặc định sau 11 user hiện tại
  }
}
