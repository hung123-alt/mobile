import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';
import 'collection_names.dart';


class UserAuthMapService {
  UserAuthMapService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Đồng bộ 1 lần khi user đăng nhập: ghi doc `user_auth_map/{profileId}`.
  static Future<void> sync({
    required String uid,
    required String email,
    required int profileId,
    required String role,
  }) async {
    try {
      await _firestore
          .collection(CollectionNames.userAuthMap)
          .doc(profileId.toString())
          .set({
        'uid': uid,
        'email': email,
        'profileId': profileId,
        'profile_id': profileId,
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Không đồng bộ được thì các chức năng cần quyền sẽ bị chặn,
      // nhưng không nên làm hỏng luồng đăng nhập chính.
    }
  }

  /// Đọc map của 1 hồ sơ theo profileId (null nếu chưa có doc).
  static Future<Map<String, dynamic>?> getByProfileId(int profileId) async {
    try {
      final snap = await _firestore
          .collection(CollectionNames.userAuthMap)
          .doc(profileId.toString())
          .get();
      return snap.data();
    } catch (_) {
      return null;
    }
  }

  /// Đọc role của 1 hồ sơ theo profileId (null nếu chưa có doc).
  static Future<String?> getRoleByProfileId(int profileId) async {
    try {
      final data = await getByProfileId(profileId);
      final role = data?['role']?.toString().trim();
      return (role == null || role.isEmpty) ? null : role;
    } catch (_) {
      return null;
    }
  }

  /// Xoá doc ánh xạ khi xoá hồ sơ (hồ sơ `users` vẫn do admin xoá riêng).
  static Future<void> removeByProfileId(int profileId) async {
    try {
      await _firestore
          .collection(CollectionNames.userAuthMap)
          .doc(profileId.toString())
          .delete();
    } catch (_) {}
  }
}

/// Firebase Auth "phụ" — dùng cho thao tác quản trị tài khoản.
///
/// VÌ SAO CẦN INSTANCE RIÊNG?
///   `FirebaseAuth.instance.createUserWithEmailAndPassword()` sẽ GHI ĐÈ
///   session hiện tại — tức là admin đang đăng nhập sẽ bị đăng xuất khỏi
///   app mỗi khi tạo tài khoản mới. Điều này rất khó chịu và dễ gây bug.
///
///   Cách khắc phục: tạo 1 FirebaseApp thứ hai với cùng project nhưng
///   khác `name`. Instance này có session riêng, không ảnh hưởng app chính.
///
///   LƯU Ý: instance phụ này KHÔNG tự đăng nhập, nên các lệnh ghi cần
///   quyền admin vẫn phải dùng app chính (đã đăng nhập).
class AdminAuthService {
  AdminAuthService._();

  static const String _secondaryAppName = 'admin-tool';

  static FirebaseAuth? _auth;
  static FirebaseApp? _app;

  /// Lấy (hoặc tạo) instance Auth phụ.
  static Future<FirebaseAuth> get instance async {
    if (_auth != null) return _auth!;

    final apps = Firebase.apps.where(
      (app) => app.name == _secondaryAppName,
    );

    if (apps.isNotEmpty) {
      _app = apps.first;
    } else {
      _app = await Firebase.initializeApp(
        name: _secondaryAppName,
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    _auth = FirebaseAuth.instanceFor(app: _app!);
    return _auth!;
  }

  /// Tạo tài khoản Auth mới mà KHÔNG ảnh hưởng session đang đăng nhập.
  ///
  /// Trả về `uid` của tài khoản vừa tạo.
  static Future<String> createUser({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final auth = await instance;

    final credential = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    if (displayName != null && displayName.isNotEmpty) {
      await credential.user?.updateDisplayName(displayName);
    }

    // Đăng xuất khỏi instance phụ để không giữ session của tài khoản mới.
    await auth.signOut();

    return credential.user?.uid ?? '';
  }

  /// Đổi mật khẩu hộ tài khoản khác KHÔNG thực hiện được từ client.
  ///
  /// Lý do: Firebase Client SDK chỉ đổi được mật khẩu của user đang đăng
  /// nhập trên chính instance đó. Muốn đổi mật khẩu hộ user khác phải dùng
  /// Firebase Admin SDK (server-side, có service account).
  ///
  /// Vì vậy app dùng cách an toàn: gửi email reset mật khẩu cho user đó
  /// bằng [requestPasswordReset]. Người dùng tự đặt mật khẩu mới qua
  /// link deep link.
  static Future<void> requestPasswordReset({
    required String email,
  }) async {
    final auth = await instance;
    await auth.sendPasswordResetEmail(email: email.trim());
  }
}
