import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/dio_client.dart';
import 'cliente_model.dart';

class ClienteService {
  ClienteService(this._dio);
  final Dio _dio;

  Future<List<Cliente>> buscar(String q) async {
    final response = await _dio.get('/clientes/', queryParameters: {'q': q, 'per_page': 20});
    return (response.data['data'] as List)
        .map((e) => Cliente.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Cliente?> buscarPorCpf(String cpf) async {
    final response = await _dio.get('/clientes/', queryParameters: {'q': cpf, 'per_page': 1});
    final data = response.data['data'] as List;
    if (data.isEmpty) return null;
    final c = Cliente.fromJson(data.first as Map<String, dynamic>);
    // Verifica CPF exato (a busca é LIKE)
    return c.cpf == cpf.replaceAll(RegExp(r'\D'), '') ? c : null;
  }

  Future<Cliente> criar(Map<String, dynamic> data) async {
    final response = await _dio.post('/clientes/', data: data);
    return Cliente.fromJson(response.data as Map<String, dynamic>);
  }
}

final clienteServiceProvider = Provider<ClienteService>(
  (ref) => ClienteService(ref.watch(dioProvider)),
);
