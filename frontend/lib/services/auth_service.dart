import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'utils.dart';

class AuthService {
  static const _tokenKey = 'token';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> _salvarToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> removerToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<void> login(String email, String senha) async {
    final response = await http.post(
      Uri.parse('${Utils.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'senha': senha}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      await _salvarToken(data['token'] as String);
      return;
    }
    throw Exception(data['error'] ?? 'Credenciais inválidas');
  }

  static Future<void> logout() async {
    final token = await getToken() ?? '';
    await http.post(
      Uri.parse('${Utils.baseUrl}/auth/logout'),
      headers: {'Authorization': 'Bearer $token'},
    );
    await removerToken();
  }

  static Future<Map<String, dynamic>> me() async {
    final token = await getToken() ?? '';
    final response = await http.get(
      Uri.parse('${Utils.baseUrl}/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Sessão inválida');
  }

  static Future<String> atualizarPerfil({
    required String senhaAtual,
    String? novoEmail,
    String? novaSenha,
  }) async {
    final token = await getToken() ?? '';
    final body = <String, dynamic>{'senha_atual': senhaAtual};
    if (novoEmail != null && novoEmail.isNotEmpty) body['email'] = novoEmail;
    if (novaSenha != null && novaSenha.isNotEmpty) body['nova_senha'] = novaSenha;
    final response = await http.patch(
      Uri.parse('${Utils.baseUrl}/auth/perfil'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return data['email'] as String;
    }
    throw Exception(data['error'] ?? 'Erro ao atualizar perfil');
  }

  static Future<void> recuperarSenha(String email) async {
    final response = await http.post(
      Uri.parse('${Utils.baseUrl}/auth/recuperar-senha'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode != 200) {
      throw Exception('Erro ao enviar e-mail de recuperação');
    }
  }
}
