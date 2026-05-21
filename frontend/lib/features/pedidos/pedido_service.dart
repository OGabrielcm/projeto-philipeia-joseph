import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/dio_client.dart';
import 'pedido_model.dart';

class PedidoService {
  PedidoService(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> listar({
    String? status,
    String? dataInicio,
    String? dataFim,
    String? q,
    int page = 1,
    int perPage = 25,
  }) async {
    final params = <String, dynamic>{
      'page':     page,
      'per_page': perPage,
    };
    if (status != null)                params['status']      = status;
    if (dataInicio != null)            params['data_inicio'] = dataInicio;
    if (dataFim != null)               params['data_fim']    = dataFim;
    if (q != null && q.isNotEmpty)     params['q']           = q;

    final response = await _dio.get('/pedidos/', queryParameters: params);
    final data    = response.data as Map<String, dynamic>;
    final lista   = (data['data'] as List)
        .map((e) => PedidoResumo.fromJson(e as Map<String, dynamic>))
        .toList();
    return {...data, 'data': lista};
  }

  Future<Pedido> buscarPorId(int id) async {
    final response = await _dio.get('/pedidos/$id');
    return Pedido.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Pedido> criar(Map<String, dynamic> payload) async {
    final response = await _dio.post('/pedidos/', data: payload);
    return Pedido.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Pedido> cancelar(int id, String motivo) async {
    final response = await _dio.post('/pedidos/$id/cancelar', data: {'motivo': motivo});
    return Pedido.fromJson(response.data as Map<String, dynamic>);
  }
}

final pedidoServiceProvider = Provider<PedidoService>(
  (ref) => PedidoService(ref.watch(dioProvider)),
);
