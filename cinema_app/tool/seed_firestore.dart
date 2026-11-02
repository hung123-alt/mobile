// seed_firestore.dart — Gọi VSMOV API → Đổ thẳng vào Firestore cho app mobile.
//
// Chạy (KHÔNG cần Node.js, KHÔNG cần Flutter SDK):
//   cd cinema_app/tool
//   dart pub get
//   dart run seed_firestore.dart
//
// Cần service account key của Firebase:
//   Firebase Console → Project settings → Service accounts → Generate key
//   → đặt file vào cinema_app/tool/serviceAccountKey.json
//   (file này đã được .gitignore loại trừ, KHÔNG commit lên git)
//
// Hoặc dùng Application Default Credentials:
//   GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json dart run seed_firestore.dart
//
// ============================================================
// CHÍNH SÁCH SEED (giống server/src/seed.ts — IDEMPOTENT):
//   • KHÔNG xóa dữ liệu nào. Phim cũ + Server 2 thêm tay GIỮ NGUYÊN.
//   • Chỉ INSERT phim MỚI (slug chưa có trong collection `movies`).
//   • Phim đã có → skip toàn bộ (cả Server 1 lẫn Server 2).
//   • Muốn seed lại 1 phim → xóa doc phim đó rồi chạy lại.
// ============================================================

import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

// ============================================================
// CẤU HÌNH
// ============================================================

const String vsmovBase = 'https://vsmov.com/api';

/// Số trang danh sách phim lấy từ VSMOV. Tăng để lấy nhiều phim hơn:
///   SEED_PAGES=8 dart run seed_firestore.dart
final int pages = int.tryParse(Platform.environment['SEED_PAGES'] ?? '') ?? 5;

/// Delay giữa các request (ms) để không bị VSMOV chặn.
const int requestDelayMs = 1200;

/// Firestore database id (mặc định của project là `(default)`).
const String databaseId = '(default)';

late final auth.AuthClient authClient;
late final String projectId;

/// Gốc Firestore REST API.
late final String firestoreRoot;

Future<void> main(List<String> args) async {
  print('═══════════════════════════════════════');
  print('  CINEMA MOBILE — Seed Firestore từ VSMOV');
  print('  (IDEMPOTENT: chỉ thêm phim mới theo slug)');
  print('═══════════════════════════════════════');

  // --- 1. Xác thực bằng service account ---
  final credentials = _loadCredentials();
  projectId = credentials['project_id'] as String? ?? '';
  if (projectId.isEmpty) {
    _fail('Không tìm thấy "project_id" trong file service account key.');
  }

  authClient = await auth.clientViaServiceAccount(
    auth.ServiceAccountCredentials.fromJson(credentials),
    const ['https://www.googleapis.com/auth/cloud-platform'],
  );

  firestoreRoot =
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/$databaseId/documents';

  print('🔌 Firebase project: $projectId ✅');

  // --- 2. Lấy danh sách phim từ VSMOV ---
  final list = await fetchMovieList();
  if (list.isEmpty) {
    _fail('Không lấy được phim nào từ VSMOV.');
  }

  // --- 3. Biến id tiếp theo cho phim ---
  var nextMovieId = (await _maxIntField('movies', 'id')) + 1;
  var maxGenreId = await _maxIntField('genres', 'id');
  var maxCountryId = await _maxIntField('countries', 'id');

  var insertedMovies = 0;
  var insertedEpisodes = 0;
  var skipped = 0;

  print('\n🔄 Lấy chi tiết & đổ dữ liệu...');

  for (var i = 0; i < list.length; i++) {
    final item = list[i];
    final slug = (item['slug'] ?? '').toString();
    if (slug.isEmpty) {
      skipped++;
      continue;
    }

    // Phim đã tồn tại → skip toàn bộ, giữ nguyên data cũ + Server 2 thêm tay.
    if (await _movieExists(slug)) {
      skipped++;
      continue;
    }

    final detailResponse = await fetchMovieDetail(slug);
    final movie = detailResponse?['movie'];
    if (movie is! Map<String, dynamic>) {
      skipped++;
      continue;
    }

    final episodes = detailResponse?['episodes'];
    final categories = _asList(movie['category']);
    final countries = _asList(movie['country']);
    final catSlugs =
        categories.map((c) => (c['slug'] ?? '').toString()).toList();

    final type = mapType((movie['type'] ?? 'movie').toString(), catSlugs);
    final status = mapStatus((movie['status'] ?? 'ongoing').toString());
    final rating = parseRating(
      _asMap(movie['tmdb'])?['vote_average']?.toString() ?? '0',
    );
    final totalEp = parseEpisodes(movie['episode_total']?.toString());
    final views = _asInt(movie['view']);
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final movieId = nextMovieId++;

    // --- Ghi doc phim (docId = id dạng chuỗi, khớp AdminMovieEditPage) ---
    final moviePayload = <String, dynamic>{
      'id': movieId,
      'title': movie['name']?.toString(),
      'name': movie['name']?.toString(),
      'slug': slug,
      'description': movie['content']?.toString() ?? '',
      'posterUrl': item['poster_url']?.toString(),
      'poster_url': item['poster_url']?.toString(),
      'bannerUrl': item['thumb_url']?.toString() ?? item['poster_url']?.toString(),
      'banner_url': item['thumb_url']?.toString() ?? item['poster_url']?.toString(),
      'type': type,
      'status': status,
      'releaseYear': _asInt(movie['year']),
      'release_year': _asInt(movie['year']),
      'totalEpisodes': totalEp,
      'total_episodes': totalEp,
      'isVisible': true,
      'is_visible': 1,
      'isFeatured': rating >= 8.5,
      'is_featured': rating >= 8.5 ? 1 : 0,
      'viewCount': views,
      'view_count': views,
      'avgRating': rating,
      'avg_rating': rating,
      'ratingCount': 0,
      'rating_count': 0,
      'createdAt': nowIso,
      'created_at': nowIso,
      'updatedAt': nowIso,
      'updated_at': nowIso,
    };
    await _setDoc('movies', '$movieId', moviePayload);
    insertedMovies++;

    // --- Gắn thể loại + quốc gia ---
    for (final cat in categories) {
      final catSlug = (cat['slug'] ?? '').toString();
      if (catSlug.isEmpty) continue;
      maxGenreId = await _ensureDimension(
        collection: 'genres',
        docId: catSlug,
        payload: {
          'id': maxGenreId + 1,
          'name': cat['name']?.toString(),
          'slug': catSlug,
          'is_visible': 1,
          'isVisible': true,
        },
      );
      final genreId = await _intFieldOf('genres', catSlug, 'id');
      await _setDoc('movie_genres', '${movieId}_$genreId', {
        'movie_id': movieId,
        'movieId': movieId,
        'genre_id': genreId,
        'genreId': genreId,
      });
    }

    for (final c in countries) {
      final countrySlug = (c['slug'] ?? '').toString();
      if (countrySlug.isEmpty) continue;
      maxCountryId = await _ensureDimension(
        collection: 'countries',
        docId: countrySlug,
        payload: {
          'id': maxCountryId + 1,
          'name': c['name']?.toString(),
          'slug': countrySlug,
        },
      );
      final countryId = await _intFieldOf('countries', countrySlug, 'id');
      await _setDoc('movie_countries', '${movieId}_$countryId', {
        'movie_id': movieId,
        'movieId': movieId,
        'country_id': countryId,
        'countryId': countryId,
      });
    }

    // --- Ghi tập phim (mỗi server 1 dòng riêng) ---
    for (final server in _asList(episodes)) {
      final serverData = _asList(server['server_data']);
      final serverName =
          (server['server_name'] ?? '').toString().trim().isEmpty
              ? 'VSMOV'
              : server['server_name'].toString().trim();

      for (var epIndex = 0; epIndex < serverData.length; epIndex++) {
        final ep = serverData[epIndex];
        // Ưu tiên link_embed, không có thì lấy link_m3u8 (giống seed MySQL).
        final link = (ep['link_embed'] ?? '').toString().isNotEmpty
            ? ep['link_embed'].toString()
            : (ep['link_m3u8'] ?? '').toString();
        if (link.isEmpty) continue;

        // Bóc số tập từ filename/name, không có thì dùng index.
        var epNum = 0;
        final nameMatch =
            RegExp(r'\d+').firstMatch('${ep['filename'] ?? ''} ${ep['name'] ?? ''}');
        if (nameMatch != null) {
          epNum = int.tryParse(nameMatch.group(0)!) ?? 0;
        }
        if (epNum <= 0) epNum = epIndex + 1;
        if (epNum <= 0) continue;

        // docId có server để multi-server cùng 1 tập không đè nhau.
        final epDocId = '${movieId}_${epNum}_${slugify(serverName)}';
        await _setDoc('episodes', epDocId, {
          'id': movieId * 1000 + epNum,
          'movie_id': movieId,
          'movieId': movieId,
          'episode_number': epNum,
          'episodeNumber': epNum,
          'name': (ep['filename'] ?? 'Tập $epNum').toString(),
          'title': (ep['filename'] ?? 'Tập $epNum').toString(),
          'embed_url': link,
          'embedUrl': link,
          'server_name': serverName,
          'serverName': serverName,
          'duration_seconds': 0,
          'durationSeconds': 0,
          'skip_intro_seconds': 0,
          'skipIntroSeconds': 0,
          'updatedAt': nowIso,
          'updated_at': nowIso,
        });
        insertedEpisodes++;
      }
    }

    if ((i + 1) % 10 == 0) {
      print('   📦 Đã xử lý ${i + 1}/${list.length}...');
    }
    await Future<void>.delayed(const Duration(milliseconds: requestDelayMs));
  }

  print('\n═══════════════════════════════════════');
  print('  KẾT QUẢ SEED FIRESTORE');
  print('═══════════════════════════════════════');
  print('   ✅ Phim mới:  $insertedMovies');
  print('   ✅ Tập phim:  $insertedEpisodes');
  print('   ⏭️  Bỏ qua:   $skipped (slug đã có — giữ nguyên data cũ)');
  print('═══════════════════════════════════════');
  print('  💡 Muốn seed lại 1 phim → xóa doc phim đó trong Firestore rồi chạy lại.');
  print('═══════════════════════════════════════\n');

  authClient.close();
}

// ============================================================
// HELPERS — ánh xạ dữ liệu VSMOV
// ============================================================

String mapType(String vsmovType, List<String> catSlugs) {
  if (catSlugs.contains('hoat-hinh')) return 'hoat_hinh';
  if (catSlugs.any((s) => s.contains('anime'))) return 'anime';
  return (vsmovType == 'tv' || vsmovType == 'series') ? 'phim_bo' : 'phim_le';
}

String mapStatus(String s) => s == 'completed' ? 'completed' : 'ongoing';

double parseRating(String v) {
  if (v.isEmpty || v == '0.0') return 0;
  final n = double.tryParse(v) ?? 0;
  return n > 9.9 ? 9.9 : n;
}

int parseEpisodes(String? epStr) {
  if (epStr == null || epStr.isEmpty) return 0;
  final matches = RegExp(r'(\d+)').allMatches(epStr).toList();
  if (matches.isEmpty) return 0;
  return matches.length >= 2
      ? int.tryParse(matches[1].group(0)!) ?? 0
      : int.tryParse(matches[0].group(0)!) ?? 0;
}

String slugify(String input) {
  final s = input
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return s.isEmpty ? 'server-1' : s;
}

List<Map<String, dynamic>> _asList(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
  return <Map<String, dynamic>>[];
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

// ============================================================
// GỌI VSMOV API
// ============================================================

Future<List<Map<String, dynamic>>> fetchMovieList() async {
  print('\n📥 Lấy danh sách phim ($pages trang)...');
  final all = <Map<String, dynamic>>[];

  for (var p = 1; p <= pages; p++) {
    try {
      final res = await http
          .get(Uri.parse('$vsmovBase/danh-sach/phim-moi-cap-nhat?page=$p'))
          .timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        print('   ⚠️  Trang $p: HTTP ${res.statusCode}, dừng.');
        break;
      }

      final data = jsonDecode(res.body);
      final items = _asList(data is Map ? data['items'] : null);
      if (items.isNotEmpty) {
        all.addAll(items);
        print('   ✅ Trang $p: +${items.length} (tổng ${all.length})');
      } else {
        print('   ⚠️  Trang $p: trống, dừng.');
        break;
      }

      if (p < pages) {
        await Future<void>.delayed(const Duration(milliseconds: requestDelayMs));
      }
    } catch (e) {
      print('   ❌ Trang $p: $e');
      break;
    }
  }

  return all;
}

Future<Map<String, dynamic>?> fetchMovieDetail(String slug) async {
  try {
    final res = await http
        .get(Uri.parse('$vsmovBase/phim/$slug'))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body);
    return data is Map ? Map<String, dynamic>.from(data) : null;
  } catch (_) {
    return null;
  }
}

// ============================================================
// FIRESTORE REST API
// ============================================================

Map<String, dynamic> _loadCredentials() {
  final path = Platform.environment['GOOGLE_APPLICATION_CREDENTIALS'] ??
      'serviceAccountKey.json';
  final file = File(path);
  if (!file.existsSync()) {
    _fail(
      'Không thấy file service account key: $path\n'
      '  → Firebase Console → Project settings → Service accounts → Generate key\n'
      '  → đặt file vào cinema_app/tool/serviceAccountKey.json',
    );
  }
  return Map<String, dynamic>.from(jsonDecode(file.readAsStringSync()));
}

/// Chuyển map Dart → trường Firestore REST (stringValue, integerValue...).
Map<String, dynamic> _toFirestoreFields(Map<String, dynamic> data) {
  final fields = <String, dynamic>{};
  data.forEach((key, value) {
    fields[key] = _encodeValue(value);
  });
  return fields;
}

Map<String, dynamic> _encodeValue(dynamic value) {
  if (value == null) return {'nullValue': null};
  if (value is bool) return {'booleanValue': value};
  if (value is int) return {'integerValue': value.toString()};
  if (value is double) return {'doubleValue': value};
  if (value is num) return {'doubleValue': value.toDouble()};
  if (value is DateTime) return {'timestampValue': value.toIso8601String()};
  if (value is Map) {
    return {
      'mapValue': {
        'fields': _toFirestoreFields(Map<String, dynamic>.from(value)),
      },
    };
  }
  if (value is List) {
    return {
      'arrayValue': {
        'values': value.map(_encodeValue).toList(),
      },
    };
  }
  return {'stringValue': value.toString()};
}

/// Ghi (merge) 1 doc. Tạo mới nếu chưa có.
Future<void> _setDoc(
  String collection,
  String docId,
  Map<String, dynamic> data,
) async {
  // updateMask liệt kê đúng field cần ghi → PATCH sẽ MERGE,
  // không xoá các field khác đang có sẵn trong doc.
  final mask = data.keys.map((k) => 'updateMask.fieldPaths=$k').join('&');
  final url = Uri.parse('$firestoreRoot/$collection/$docId?$mask');
  final res = await authClient.patch(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'fields': _toFirestoreFields(data),
    }),
  );
  if (res.statusCode >= 300) {
    throw Exception('Ghi $collection/$docId thất bại (${res.statusCode}): '
        '${res.body}');
  }
}

/// Kiểm tra phim đã tồn tại theo slug chưa.
Future<bool> _movieExists(String slug) async {
  final res = await authClient.post(
    Uri.parse('$firestoreRoot:runQuery'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'structuredQuery': {
        'from': [
          {'collectionId': 'movies'}
        ],
        'where': {
          'fieldFilter': {
            'field': {'fieldPath': 'slug'},
            'op': 'EQUAL',
            'value': {'stringValue': slug},
          },
        },
        'limit': 1,
      },
    }),
  );
  if (res.statusCode >= 300) return false;
  final decoded = jsonDecode(res.body);
  if (decoded is! List) return false;
  // runQuery trả về [] nếu không có doc khớp.
  return decoded.isNotEmpty;
}

/// Lấy giá trị int lớn nhất của 1 field trong collection (dùng làm id kế tiếp).
Future<int> _maxIntField(String collection, String field) async {
  final res = await authClient.post(
    Uri.parse('$firestoreRoot:runQuery'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'structuredQuery': {
        'from': [
          {'collectionId': collection}
        ],
        'orderBy': [
          {
            'field': {'fieldPath': field},
            'direction': 'DESCENDING',
          }
        ],
        'limit': 1,
      },
    }),
  );
  if (res.statusCode >= 300) return 0;
  final decoded = jsonDecode(res.body);
  if (decoded is! List || decoded.isEmpty) return 0;
  final doc = decoded.first;
  final fields = (doc is Map ? doc['document'] : null) is Map
      ? (doc['document']['fields'] as Map)
      : null;
  if (fields == null) return 0;
  final raw = fields[field];
  if (raw is! Map) return 0;
  return int.tryParse('${raw['integerValue'] ?? raw['doubleValue'] ?? 0}') ?? 0;
}

/// Lấy 1 field int của 1 doc cụ thể.
Future<int> _intFieldOf(String collection, String docId, String field) async {
  final res = await authClient.get(Uri.parse('$firestoreRoot/$collection/$docId'));
  if (res.statusCode >= 300) return 0;
  final decoded = jsonDecode(res.body);
  if (decoded is! Map) return 0;
  final fields = decoded['fields'];
  if (fields is! Map) return 0;
  final raw = fields[field];
  if (raw is! Map) return 0;
  return int.tryParse('${raw['integerValue'] ?? raw['doubleValue'] ?? 0}') ?? 0;
}

/// Tạo doc danh mục (genres/countries) nếu chưa có, trả về id lớn nhất hiện tại.
Future<int> _ensureDimension({
  required String collection,
  required String docId,
  required Map<String, dynamic> payload,
}) async {
  final exists = await _docExists(collection, docId);
  if (!exists) {
    await _setDoc(collection, docId, payload);
  }
  return await _intFieldOf(collection, docId, 'id');
}

Future<bool> _docExists(String collection, String docId) async {
  final res = await authClient.get(Uri.parse('$firestoreRoot/$collection/$docId'));
  return res.statusCode < 300;
}

Never _fail(String message) {
  stderr.writeln('❌ $message');
  exit(1);
}
