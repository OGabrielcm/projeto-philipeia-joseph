import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'utils.dart';

class PedidoService {
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken() ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> listar({
    String? status,
    int page = 1,
    int perPage = 25,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'per_page': '$perPage',
    };
    if (status != null) params['status'] = status;

    final uri = Uri.parse('${Utils.baseUrl}/pedidos/').replace(queryParameters: params);
    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Erro ao carregar pedidos');
  }

  static Future<Map<String, dynamic>> buscarPorId(int id) async {
    final response = await http.get(
      Uri.parse('${Utils.baseUrl}/pedidos/$id'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Pedido não encontrado');
  }

  static Future<Map<String, dynamic>> criar(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('${Utils.baseUrl}/pedidos/'),
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final err = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(err['error'] ?? 'Erro ao criar pedido');
  }

  static Future<Map<String, dynamic>> atualizar(int id, Map<String, dynamic> payload) async {
    final response = await http.put(
      Uri.parse('${Utils.baseUrl}/pedidos/$id'),
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Erro ao atualizar pedido');
  }

  static Future<Map<String, dynamic>> cancelar(int id, String motivo) async {
    final response = await http.post(
      Uri.parse('${Utils.baseUrl}/pedidos/$id/cancelar'),
      headers: await _headers(),
      body: jsonEncode({'motivo': motivo}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Erro ao cancelar pedido');
  }

  static Future<void> excluir(int id) async {
    final response = await http.delete(
      Uri.parse('${Utils.baseUrl}/pedidos/$id'),
      headers: await _headers(),
    );
    if (response.statusCode != 204) {
      throw Exception('Erro ao excluir pedido');
    }
  }
}
