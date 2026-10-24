import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        if (user != null) {
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
        final doc = await _firestore.collection(CollectionNames.users).doc(cachedUserId.toString()).get();
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

      // Tìm theo email
      var query = await _firestore
          .collection(CollectionNames.users)
          .where('email', isEqualTo: input)
          .limit(1)
          .get();

      // Nếu không thấy, tìm theo username
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
        final isBanned = userData['isBanned'] == true || userData['is_banned'] == 1;
        if (isBanned) {
          _errorMessage = 'Tài khoản của bạn đã bị khóa. Vui lòng liên hệ quản trị viên.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      final targetEmail = userData != null ? (userData['email'] as String? ?? input) : input;

      // 2. Xác thực với Firebase Authentication
      try {
        await _auth.signInWithEmailAndPassword(
          email: targetEmail,
          password: password,
        );
      } on fb_auth.FirebaseAuthException catch (authEx) {
        // Nếu user tồn tại trong Firestore (dữ liệu migrate từ MySQL) nhưng chưa đăng ký trên Firebase Auth
        if (authEx.code == 'user-not-found' && userData != null) {
          try {
            await _auth.createUserWithEmailAndPassword(
              email: targetEmail,
              password: password,
            );
          } catch (_) {
            // Bỏ qua lỗi phụ nếu tạo auth ngầm
          }
        } else if (authEx.code == 'wrong-password' || authEx.code == 'invalid-credential') {
          _errorMessage = 'Mật khẩu không chính xác';
          _isLoading = false;
          notifyListeners();
          return false;
        } else if (authEx.code == 'invalid-email') {
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
          // Nếu không đăng nhập được qua Firebase Auth và không có userData trong Firestore
          if (userData == null) {
            _errorMessage = 'Tài khoản hoặc mật khẩu không chính xác';
            _isLoading = false;
            notifyListeners();
            return false;
          }
        }
      }

      // 3. Nếu chưa có userData trong Firestore, tạo mới từ Firebase Auth
      if (userData == null) {
        final fbUser = _auth.currentUser;
        if (fbUser != null) {
          final nextId = await _getNextUserId();
          userData = {
            'id': nextId,
            'username': fbUser.displayName ?? input.split('@').first,
            'email': fbUser.email ?? input,
            'role': 'user',
            'isBanned': false,
            'is_banned': 0,
            'createdAt': DateTime.now().toIso8601String(),
            'created_at': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            'lastLogin': DateTime.now().toIso8601String(),
            'last_login': DateTime.now().toIso8601String(),
          };
          userDocId = nextId.toString();
          await _firestore.collection(CollectionNames.users).doc(userDocId).set(userData);
        }
      }

      if (userData != null) {
        // Cập nhật lastLogin lên Firestore
        final nowIso = DateTime.now().toIso8601String();
        if (userDocId != null) {
          _firestore.collection(CollectionNames.users).doc(userDocId).update({
            'lastLogin': nowIso,
            'last_login': nowIso,
          }).catchError((_) {});
        }

        _currentUser = User.fromJson(userData);

        // Lưu vào SharedPreferences
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

  /// Đăng ký tài khoản mới
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

      // 3. Tạo tài khoản trong Firebase Authentication
      fb_auth.UserCredential credential;
      try {
        credential = await _auth.createUserWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
      } on fb_auth.FirebaseAuthException catch (authEx) {
        if (authEx.code == 'email-already-in-use') {
          _errorMessage = 'Email này đã được đăng ký tài khoản';
        } else if (authEx.code == 'invalid-email') {
          _errorMessage = 'Địa chỉ email không đúng định dạng';
        } else if (authEx.code == 'weak-password') {
          _errorMessage = 'Mật khẩu quá yếu, vui lòng chọn mật khẩu mạnh hơn';
        } else {
          _errorMessage = 'Đăng ký thất bại: ${authEx.message}';
        }
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await credential.user?.updateDisplayName(cleanUsername);

      // 4. Sinh ID tiếp theo cho Firestore
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

      // Lưu document vào Firestore collection 'users' với docId = nextId
      await _firestore.collection(CollectionNames.users).doc(nextId.toString()).set(newUserData);

      _currentUser = User.fromJson(newUserData);

      // Lưu thông tin vào SharedPreferences
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

  /// Gửi email đặt lại mật khẩu
  Future<bool> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } catch (e) {
      debugPrint('sendPasswordReset error: $e');
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
