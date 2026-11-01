import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

/// Lỗi Firebase - tương đương [ApiException] trong `services/api_service.dart`.
///
/// Hai lớp lỗi này có VAI TRÒ GIỐNG NHAU trong kiến trúc:
///   ApiException      -> lỗi HTTP 4xx/5xx từ NestJS
///   FirestoreException-> lỗi quyền (rules) hoặc mạng từ Firestore
///
/// Nhờ vậy `repositories/` bắt lỗi được cả 2 trường hợp mà không cần sửa code.
class FirestoreException implements Exception {
  final String code;
  final String message;

  FirestoreException(this.code, this.message);

  /// Lỗi này có phải do thiếu quyền không?
  /// Thường do chưa viết Security Rules hoặc chưa bật billing.
  bool getIsPermissionDenied() => code == 'permission-denied';

  /// Lỗi mạng / không kết nối được Firestore.
  bool getIsNetworkError() => code == 'unavailable';

  /// Document không tồn tại (đọc 1 doc theo ID sai).
  bool getIsNotFound() => code == 'not-found';

  @override
  String toString() => 'FirestoreException($code): $message';
}

/// Lớp bọc Firestore — nơi DUY NHẤT app được phép gọi tới Firestore.
///
/// Đây chính là file thay thế cho `services/api_service.dart`.
///
/// Vì sao cần lớp bọc?
///   1. Chỗ khởi tạo Firebase chỉ được gọi 1 lần duy nhất. Nếu mỗi service
///      tự gọi `Firebase.initializeApp()` sẽ bị lỗi "already exists".
///   2. Gom lỗi Firestore về 1 kiểu lỗi duy nhất để repository bắt cho gọn.
///   3. Có sẵn hàm generic để repository không phải tự viết `QuerySnapshot`
///      cho từng model.
///
/// Tương ứng 1-1 với tầng kiến trúc:
///
///   FirebaseService  <->  ApiService   (gọi dữ liệu từ xa)
///   FirestoreException<-> ApiException (lỗi)
///   CollectionNames   <-> AppConstants (hằng số)
class FirebaseService {
  FirebaseService._();

  // Singleton: biến static, khởi tạo 1 lần duy nhất.
  static FirebaseService? _instance;

  static bool _isInitialized = false;

  /// Lấy instance. Lần đầu tiên gọi sẽ tự khởi tạo Firebase.
  ///
  /// ```dart
  /// final firebase = FirebaseService.instance;
  /// ```
  static FirebaseService get instance {
    _instance ??= FirebaseService._();
    return _instance!;
  }

  /// Đã khởi tạo Firebase chưa?
  static bool get initialized => _isInitialized;

  /// Khởi tạo Firebase. Phải gọi TRƯỚC mọi truy vấn Firestore.
  ///
  /// Gọi trong `main()` và là async vì phải chờ Firebase nạp cấu hình:
  ///
  /// ```dart
  /// Future<void> main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await FirebaseService.instance.initialize();
  ///   runApp(const CinemaApp());
  /// }
  /// ```
  Future<void> initialize() async {
    // Chống gọi 2 lần — thường xảy ra khi hot reload trong lúc code.
    if (_isInitialized) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isInitialized = true;
    } catch (e) {
      throw FirestoreException('init-failed', 'Không khởi tạo được Firebase: $e');
    }
  }

  /// Firestore chính (instance mặc định).
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Firestore cho phép đọc/ghi OFFLINE.
  ///
  /// Quan trọng khi lên máy ảnh Android: emulator truy cập Firestore qua
  /// `10.0.2.2`, không phải `localhost`. Đây là lý do [AppConstants]
  /// có ghi chú về 10.0.2.2 cho REST — Firebase cũng dính vấn đề này.
  bool get isOfflineEnabled => _db.settings.persistenceEnabled ?? false;

  Future<void> enableOfflineCache() async {
    _db.settings = const Settings(persistenceEnabled: true);
  }

  // ============================================================
  // GENERIC CORE - hàm nền cho toàn bộ truy vấn
  // ============================================================

  /// Lấy 1 document theo ID, trả về null nếu không tồn tại.
  ///
  /// ```dart
  /// final movie = await FirebaseService.instance.getById<Movie>(
  ///   CollectionNames.movies,
  ///   'dang-ky-hoc-thuat-siec',
  ///   (raw, docId) => Movie.fromMap(raw, docId),
  /// );
  /// ```
  Future<T?> getById<T>(
    String collection,
    String docId,
    T Function(Map<String, dynamic> map, String docId) fromMap,
  ) async {
    try {
      final snapshot = await _db
          .collection(collection)
          .doc(docId)
          .get();
      final data = snapshot.data();
      if (data == null) return null;
      return fromMap(data, docId);
    } catch (e) {
      throw _wrapError(e, 'getById $collection/$docId');
    }
  }

  /// Lấy danh sách document, có phân trang và sắp xếp.
  ///
  /// [where] giữ nguyên kiểu `Query<T>` của Firestore nên vẫn dùng được
  /// toàn bộ toán tử lọc: `==`, `!=`, `>`, `<`, `>=`, `<=`, `in`, `array-contains`.
  ///
  /// ```dart
  /// final movies = await firebase.getList<Movie>(
  ///   CollectionNames.movies,
  ///   (raw, docId) => Movie.fromMap(raw, docId),
  ///   where: (q) => q.where(FieldNames.isVisible, isEqualTo: true),
  ///   orderBy: FieldNames.viewCount,
  ///   descending: true,
  ///   limit: 12,
  /// );
  /// ```
  Future<List<T>> getList<T>(
    String collection,
    T Function(Map<String, dynamic> map, String docId) fromMap, {
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>>)? where,
    String? orderBy,
    bool descending = false,
    int? limit,
    int? offset,
  }) async {
    try {
      Query<Map<String, dynamic>> query =
          _db.collection(collection);

      if (where != null) {
        query = where(query);
      }
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }
      final snapshot = await query.get();
      final start = offset ?? 0;
      final end = limit == null ? snapshot.docs.length : (start + limit).clamp(start, snapshot.docs.length);
      final docs = snapshot.docs.sublist(start, end);

      return docs.map((doc) => fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      throw _wrapError(e, 'getList $collection');
    }
  }

  /// Lấy 1 document duy nhất theo điều kiện lọc.
  Future<T?> getFirstWhere<T>(
    String collection,
    T Function(Map<String, dynamic> map, String docId) fromMap, {
    required Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>>) where,
    String? orderBy,
    bool descending = false,
  }) async {
    try {
      var query = where(_db.collection(collection));
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      final snapshot = await query.limit(1).get();
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return fromMap(doc.data(), doc.id);
    } catch (e) {
      throw _wrapError(e, 'getFirstWhere $collection');
    }
  }

  /// Tạo mới document với ID ngẫu nhiên do Firestore sinh.
  Future<String> create<T>(
    String collection,
    Map<String, dynamic> data, {
    String? docId,
    String? subCollectionPath,
  }) async {
    try {
      // subCollectionPath cho phép ghi vào users/{uid}/favorites
      final ref = subCollectionPath != null
          ? _db.collection(subCollectionPath)
          : _db.collection(collection);

      final newDoc = docId != null ? ref.doc(docId) : ref.doc();
      await newDoc.set(data);
      return newDoc.id;
    } catch (e) {
      throw _wrapError(e, 'create $collection');
    }
  }

  /// Ghi đè toàn bộ document (thay thế nội dung cũ).
  Future<void> set<T>(
    String collection,
    String docId,
    Map<String, dynamic> data, {
    String? subCollectionPath,
  }) async {
    try {
      final ref = subCollectionPath != null
          ? _db.collection(subCollectionPath)
          : _db.collection(collection);
      await ref.doc(docId).set(data);
    } catch (e) {
      throw _wrapError(e, 'set $collection/$docId');
    }
  }

  /// Cập nhật MỘT SỐ trường, giữ nguyên các trường còn lại.
  ///
  /// Khác với [set]: `set` xóa trường không có trong `data`,
  /// còn `update` chỉ ghi đè trường được nêu tên.
  Future<void> update(
    String collection,
    String docId,
    Map<String, dynamic> data, {
    String? subCollectionPath,
  }) async {
    try {
      final ref = subCollectionPath != null
          ? _db.collection(subCollectionPath)
          : _db.collection(collection);
      await ref.doc(docId).update(data);
    } catch (e) {
      throw _wrapError(e, 'update $collection/$docId');
    }
  }

  /// Xoá document.
  Future<void> delete(
    String collection,
    String docId, {
    String? subCollectionPath,
  }) async {
    try {
      final ref = subCollectionPath != null
          ? _db.collection(subCollectionPath)
          : _db.collection(collection);
      await ref.doc(docId).delete();
    } catch (e) {
      throw _wrapError(e, 'delete $collection/$docId');
    }
  }

  /// Đếm số document thỏa điều kiện.
  Future<int> countWhere(
    String collection,
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>>) where,
  ) async {
    try {
      final snapshot = await where(_db.collection(collection)).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      throw _wrapError(e, 'countWhere $collection');
    }
  }

  /// Tăng 1 giá trị số ngay trên server (atomic).
  ///
  /// KHÔNG được làm kiểu `đọc → +1 → ghi` vì 2 người xem cùng lúc sẽ
  /// đều đọc giá trị cũ và ghi đè lên nhau. Firestore có sẵn
  /// [FieldValue.increment] để giải quyết việc này.
  ///
  /// ```dart
  /// await firebase.increment(CollectionNames.movies, slug, FieldNames.viewCount);
  /// ```
  Future<void> increment(
    String collection,
    String docId,
    String field,
    {int amount = 1, String? subCollectionPath}) async {
    try {
      final ref = subCollectionPath != null
          ? _db.collection(subCollectionPath)
          : _db.collection(collection);
      await ref.doc(docId).update({field: FieldValue.increment(amount)});
    } catch (e) {
      throw _wrapError(e, 'increment $collection/$docId');
    }
  }

  /// Kiểm tra 1 document đã tồn tại chưa.
  Future<bool> exists(String collection, String docId) async {
    try {
      final snapshot = await _db.collection(collection).doc(docId).get();
      return snapshot.exists;
    } catch (e) {
      throw _wrapError(e, 'exists $collection/$docId');
    }
  }

  /// Theo dõi thay đổi của 1 document theo thời gian.
  ///
  /// Dùng cho: đồng bộ trạng thái yêu thích giữa nhiều màn hình,
  /// theo dõi bình luận mới xuất hiện, cập nhật số lượt xem.
  ///
  /// ```dart
  /// StreamSubscription sub = firebase.watchDocument<Movie>(
  ///   CollectionNames.movies,
  ///   slug,
  ///   (raw, docId) => Movie.fromMap(raw, docId),
  ///   onData: (movie) => setState(() => _movie = movie),
  /// );
  /// ```
  Stream<T?> watchDocument<T>(
    String collection,
    String docId,
    T Function(Map<String, dynamic> map, String docId) fromMap, {
    String? subCollectionPath,
  }) {
    final ref = subCollectionPath != null
        ? _db.collection(subCollectionPath)
        : _db.collection(collection);
    return ref.doc(docId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return null;
      return fromMap(data, snapshot.id);
    });
  }

  /// Theo dõi thay đổi của một collection.
  Stream<List<T>> watchList<T>(
    String collection,
    T Function(Map<String, dynamic> map, String docId) fromMap, {
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>>)? where,
    String? orderBy,
    bool descending = false,
    int? limit,
    String? subCollectionPath,
  }) {
    Query<Map<String, dynamic>> query = subCollectionPath != null
        ? _db.collection(subCollectionPath)
        : _db.collection(collection);

    if (where != null) query = where(query);
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }
    if (limit != null && limit > 0) query = query.limit(limit);

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // ============================================================
  // ERROR HANDLING
  // ============================================================

  /// Bọc lỗi Firestore về [FirestoreException] để repository bắt gọn.
  ///
  /// `FirebaseException` có nhiều mã khác nhau, nếu để lọt ra ngoài thì
  /// mỗi repository phải tự biết hết mã. Gom 1 chỗ giúp đổi logic sau này
  /// chỉ sửa 1 file.
  FirestoreException _wrapError(Object e, String context) {
    if (e is FirestoreException) return e;

    if (e is FirebaseException) {
      return FirestoreException(e.code, '$context: ${e.message}');
    }
    return FirestoreException('unknown', '$context: $e');
  }

  /// Xoá toàn bộ collection (chỉ dùng khi dev/làm mới dữ liệu mẫu).
  ///
  /// CẢNH BÁO: đây là thao tác không thể hoàn tác.
  Future<void> deleteAllFrom(String collection) async {
    try {
      final snapshot = await _db.collection(collection).get();
      // Firestore chỉ xoá được tối đa 500 document mỗi lần
      for (final batch in _batches(snapshot.docs)) {
        await batch.commit();
      }
    } catch (e) {
      throw _wrapError(e, 'deleteAllFrom $collection');
    }
  }

  /// Chia thành lô 500 document — giới hạn cứng của Firestore WriteBatch.
  List<WriteBatch> _batches(List<QueryDocumentSnapshot> docs) {
    final batches = <WriteBatch>[];
    for (var i = 0; i < docs.length; i += 500) {
      final batch = _db.batch();
      final end = (i + 500).clamp(0, docs.length);
      for (var j = i; j < end; j++) {
        batch.delete(docs[j].reference);
      }
      batches.add(batch);
    }
    return batches;
  }

  /// Ghi hàng loạt document trong 1 lần gửi (tối đa 500/lô).
  Future<void> setBatch(
    String collection,
    List<Map<String, dynamic>> items, {
    String Function(Map<String, dynamic> data)? docIdFrom,
  }) async {
    try {
      var batch = _db.batch();
      var count = 0;

      for (final item in items) {
        if (count == 500) {
          await batch.commit();
          batch = _db.batch();
          count = 0;
        }
        final docId = docIdFrom?.call(item);
        batch.set(
          docId != null
              ? _db.collection(collection).doc(docId)
              : _db.collection(collection).doc(),
          item,
        );
        count++;
      }

      if (count > 0) await batch.commit();
    } catch (e) {
      throw _wrapError(e, 'setBatch $collection');
    }
  }
}