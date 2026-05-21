import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/dio_client.dart';
import '../../core/auth/auth_notifier.dart';

class AuthService {
  AuthService(this._dio, this._ref);

  final Dio _dio;
  final Ref _ref;

  Future<void> login(String email, String senha) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'senha': senha,
    });
    final token = response.data['token'] as String;
    await _ref.read(authProvider.notifier).setToken(token);
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } finally {
      await _ref.read(authProvider.notifier).clearToken();
    }
  }
}

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(dioProvider), ref),
);
