import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../home/home_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailCtrl         = TextEditingController();
  final _senhaCtrl         = TextEditingController();
  final _recuperaEmailCtrl = TextEditingController();

  bool _carregando      = false;
  bool _modoRecuperacao = false;
  bool _senhaVisivel    = false;

  @override
  void initState() {
    super.initState();
    _verificarSessao();
  }

  Future<void> _verificarSessao() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('token') != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeView()),
      );
    }
  }

  Future<void> _autenticarUsuario() async {
    final email = _emailCtrl.text.trim();
    final senha = _senhaCtrl.text;
    if (email.isEmpty || senha.isEmpty) {
      _mostrarMensagem('Preencha e-mail e senha');
      return;
    }
    setState(() => _carregando = true);
    try {
      await AuthService.login(email, senha);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeView()),
        );
      }
    } catch (e) {
      _mostrarMensagem(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _enviarRecuperacao() async {
    final email = _recuperaEmailCtrl.text.trim();
    if (email.isEmpty) {
      _mostrarMensagem('Informe o e-mail');
      return;
    }
    setState(() => _carregando = true);
    try {
      await AuthService.recuperarSenha(email);
      _mostrarMensagem('Se o e-mail estiver cadastrado, você receberá as instruções em breve.');
      setState(() {
        _modoRecuperacao = false;
        _recuperaEmailCtrl.clear();
      });
    } catch (_) {
      _mostrarMensagem('Erro ao enviar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _mostrarMensagem(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _recuperaEmailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD300),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.sports_bar, size: 48, color: Color(0xFF16181B)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Philipeia',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  _modoRecuperacao ? 'Recuperar Senha' : 'Sistema de Gestão',
                  style: const TextStyle(color: Color(0xFF7A7E85), fontSize: 14),
                ),
                const SizedBox(height: 40),

                if (!_modoRecuperacao) ...[
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                    onSubmitted: (_) => _autenticarUsuario(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _senhaCtrl,
                    obscureText: !_senhaVisivel,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_senhaVisivel ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
                      ),
                    ),
                    onSubmitted: (_) => _autenticarUsuario(),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => setState(() => _modoRecuperacao = true),
                      child: const Text('Esqueci minha senha'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _carregando ? null : _autenticarUsuario,
                      child: _carregando
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF16181B)),
                            )
                          : const Text('Entrar', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ] else ...[
                  TextField(
                    controller: _recuperaEmailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-mail para recuperação',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() {
                            _modoRecuperacao = false;
                            _recuperaEmailCtrl.clear();
                          }),
                          child: const Text('Voltar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _carregando ? null : _enviarRecuperacao,
                          child: _carregando
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF16181B)),
                                )
                              : const Text('Enviar Link'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
