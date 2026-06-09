import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'utils.dart';

class ClienteService {
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken() ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<List<dynamic>> buscar(String q) async {
    final uri = Uri.parse('${Utils.baseUrl}/clientes/').replace(
      queryParameters: {'q': q, 'per_page': '20'},
    );
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['data'] as List<dynamic>;
    }
    throw Exception('Erro ao buscar clientes');
  }

  static Future<Map<String, dynamic>> criar(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('${Utils.baseUrl}/clientes/'),
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final err = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(err['error'] ?? 'Erro ao criar cliente');
  }

  static Future<Map<String, dynamic>> atualizar(int id, Map<String, dynamic> payload) async {
    final response = await http.put(
      Uri.parse('${Utils.baseUrl}/clientes/$id'),
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Erro ao atualizar cliente');
  }

  static Future<void> excluir(int id) async {
    final response = await http.delete(
      Uri.parse('${Utils.baseUrl}/clientes/$id'),
      headers: await _headers(),
    );
    if (response.statusCode != 204) {
      throw Exception('Erro ao excluir cliente');
    }
  }
}
