import '../models/user_model.dart';
import '../providers/auth_provider.dart';


class AuthRepository {
  AuthRepository({AuthProvider? authProvider})
      : _authProvider = authProvider ?? AuthProvider.instance;

  final AuthProvider _authProvider;

  User? get currentUser => _authProvider.currentUser;
  bool get isAuthenticated => _authProvider.isAuthenticated;

  Future<bool> login(String identifier, String password) {
    return _authProvider.login(identifier: identifier, password: password);
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) {
    return _authProvider.register(
      username: username,
      email: email,
      password: password,
    );
  }

  Future<void> logout() {
    return _authProvider.logout();
  }

  Future<bool> sendPasswordReset(String email) {
    return _authProvider.sendPasswordReset(email);
  }
}
