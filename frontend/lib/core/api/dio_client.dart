import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_notifier.dart';

const _baseUrl = 'http://localhost:5001/api/v1';

Dio buildDio(Ref ref) {
  final dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      final token = ref.read(authProvider);
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) {
      handler.next(_mapError(error));
    },
  ));

  return dio;
}

DioException _mapError(DioException e) {
  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout) {
    return e.copyWith(
      message: 'Tempo de conexão esgotado. Verifique a rede e tente novamente.',
    );
  }
  if (e.type == DioExceptionType.connectionError) {
    return e.copyWith(
      message: 'Sem conexão com o servidor. Verifique se o sistema está ativo.',
    );
  }
  return e;
}

/// Extrai a mensagem de erro legível de uma DioException.
String dioMessage(DioException e) {
  final data = e.response?.data;
  if (data is Map) {
    final single = data['error'];
    if (single is String) return single;

    final errors = data['errors'];
    if (errors is Map) {
      final parts = <String>[];
      errors.forEach((campo, msgs) {
        final lista = msgs is List ? msgs.join(', ') : msgs.toString();
        parts.add('$campo: $lista');
      });
      if (parts.isNotEmpty) return parts.join('\n');
    }
  }
  return e.message ?? 'Erro desconhecido';
}

final dioProvider = Provider<Dio>((ref) => buildDio(ref));
