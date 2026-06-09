import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'utils.dart';

class CatalogoService {
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken() ?? '';
    return {'Authorization': 'Bearer $token'};
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
