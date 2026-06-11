import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'utils.dart';

class CatalogoService {
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken() ?? '';
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  static Future<List<dynamic>> listarEstilos() async {
    final response = await http.get(
      Uri.parse('${Utils.baseUrl}/catalogo/estilos'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Erro ao carregar catálogo');
  }

  static Future<Map<String, dynamic>> criarEstilo(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('${Utils.baseUrl}/catalogo/estilos'),
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final err = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(err['error'] ?? 'Erro ao criar estilo');
  }

  static Future<Map<String, dynamic>> atualizarEstilo(int id, Map<String, dynamic> payload) async {
    final response = await http.put(
      Uri.parse('${Utils.baseUrl}/catalogo/estilos/$id'),
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final err = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(err['error'] ?? 'Erro ao atualizar estilo');
  }

  static Future<void> excluirEstilo(int id) async {
    final response = await http.delete(
      Uri.parse('${Utils.baseUrl}/catalogo/estilos/$id'),
      headers: await _headers(),
    );
    if (response.statusCode != 204) {
      final err = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(err['error'] ?? 'Erro ao excluir estilo');
    }
  }

  static Future<Map<String, dynamic>> criarCombo(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('${Utils.baseUrl}/catalogo/combos'),
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final err = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(err['error'] ?? 'Erro ao criar combo');
  }

  static Future<Map<String, dynamic>> atualizarCombo(int id, Map<String, dynamic> payload) async {
    final response = await http.put(
      Uri.parse('${Utils.baseUrl}/catalogo/combos/$id'),
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final err = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(err['error'] ?? 'Erro ao atualizar combo');
  }

  static Future<void> excluirCombo(int id) async {
    final response = await http.delete(
      Uri.parse('${Utils.baseUrl}/catalogo/combos/$id'),
      headers: await _headers(),
    );
    if (response.statusCode != 204) {
      final err = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(err['error'] ?? 'Erro ao excluir combo');
    }
  }

  static Future<List<dynamic>> listarCombos() async {
    final response = await http.get(
      Uri.parse('${Utils.baseUrl}/catalogo/combos'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Erro ao carregar combos');
  }
}
