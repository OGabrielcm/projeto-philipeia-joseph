import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kTokenKey = 'jwt_token';

class AuthNotifier extends Notifier<String?> {
  final _storage = const FlutterSecureStorage();

  @override
  String? build() => null;

  Future<void> init() async {
    state = await _storage.read(key: _kTokenKey);
  }

  Future<void> setToken(String token) async {
    await _storage.write(key: _kTokenKey, value: token);
    state = token;
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _kTokenKey);
    state = null;
  }

  bool get isAuthenticated => state != null;
}

final authProvider = NotifierProvider<AuthNotifier, String?>(AuthNotifier.new);
