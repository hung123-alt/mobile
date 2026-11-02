import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}


class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Token JWT hiện tại, được set bởi AuthProvider
  String? _accessToken;

  /// Đặt token (gọi từ AuthProvider sau khi đăng nhập)
  void setAccessToken(String? token) {
    _accessToken = token;
  }

  /// Lấy token hiện tại
  String? getAccessToken() => _accessToken;

  /// Base URL đầy đủ từ path
  /// LOP 4 - BAT BUOC HTTPS O PRODUCTION.
  /// VÌ SAO? HTTP truyen plaintext, wifi cong cong doc trom duoc token.
  /// Chi cho phep http voi host dev local (localhost/10.0.2.2/127.0.0.1);
  /// production (host that) bat buoc https, neu khong nem [ApiException].
  Uri _buildUri(String path, [Map<String, dynamic>? query]) {
    final base = '${AppConstants.apiBaseUrl}$path';
    final uri = Uri.parse(base);
    const devHosts = <String>{'localhost', '10.0.2.2', '127.0.0.1'};
    if (uri.scheme == 'http' && !devHosts.contains(uri.host)) {
      throw ApiException(
        0,
        'LOP 4: production bat buoc https (hien tai: $base). '
        'Truyen --dart-define=API_BASE_URL=https://... khi build release.',
      );
    }
    if (query == null || query.isEmpty) {
      return uri;
    }
    return uri.replace(
      queryParameters: query.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      ),
    );
  }

  /// Header kèm token
  Map<String, String> _headers({bool json = true}) {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (json) {
      headers['Content-Type'] = 'application/json';
    }
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  /// GET - trả về kiểu T, dùng hàm `parser` để chuyển JSON -> T
  ///
  ///   final movie = await api.get<Movie>('/movies/1', (e) => Movie.fromJson(e));
  Future<T> get<T>(
    String path,
    T Function(dynamic raw) parser, {
    Map<String, dynamic>? query,
  }) async {
    final response = await _client
        .get(_buildUri(path, query), headers: _headers(json: false))
        .timeout(const Duration(seconds: 15));

    return _handle<T>(response, parser);
  }

  /// GET - trả về List<T>
  Future<List<T>> getList<T>(
    String path,
    T Function(dynamic raw) parser, {
    Map<String, dynamic>? query,
  }) async {
    final response = await _client
        .get(_buildUri(path, query), headers: _headers(json: false))
        .timeout(const Duration(seconds: 15));

    _checkStatus(response);
    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded.map((e) => parser(e)).toList();
    }
    return <T>[];
  }

  /// POST - trả về kiểu T
  Future<T> post<T>(
    String path,
    Map<String, dynamic> body,
    T Function(dynamic raw) parser, {
    Map<String, dynamic>? query,
  }) async {
    final response = await _client
        .post(
          _buildUri(path, query),
          headers: _headers(),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    return _handle<T>(response, parser);
  }

  /// POST - không cần dữ liệu trả về
  Future<void> postVoid(
    String path,
    Map<String, dynamic> body, {
    Map<String, dynamic>? query,
  }) async {
    final response = await _client
        .post(
          _buildUri(path, query),
          headers: _headers(),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    _checkStatus(response);
  }

  /// PATCH - trả về kiểu T
  Future<T> patch<T>(
    String path,
    Map<String, dynamic> body,
    T Function(dynamic raw) parser,
  ) async {
    final response = await _client
        .patch(
          _buildUri(path),
          headers: _headers(),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    return _handle<T>(response, parser);
  }
  
  /// PATCH - không cần dữ liệu trả về
  Future<void> patchVoid(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _client
        .patch(
          _buildUri(path),
          headers: _headers(),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    _checkStatus(response);
  }

  /// DELETE - không cần dữ liệu trả về
  Future<void> delete(String path) async {
    final response = await _client
        .delete(_buildUri(path), headers: _headers(json: false))
        .timeout(const Duration(seconds: 15));

    _checkStatus(response);
  }

  /// Xử lý response chung
  T _handle<T>(http.Response response, T Function(dynamic raw) parser) {
    _checkStatus(response);
    final decoded = jsonDecode(response.body);
    return parser(decoded);
  }

  /// Kiểm tra mã lỗi HTTP
  void _checkStatus(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    String message = 'Lỗi ${response.statusCode}';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        message = decoded['message']?.toString() ??
            decoded['error']?.toString() ??
            message;
      }
    } catch (_) {
      // Không parse được JSON thì giữ message mặc định
    }

    throw ApiException(response.statusCode, message);
  }

  /// Đóng client khi không dùng nữa
  void dispose() {
    _client.close();
  }
}
