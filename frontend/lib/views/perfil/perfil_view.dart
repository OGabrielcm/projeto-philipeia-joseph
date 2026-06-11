import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class PerfilView extends StatefulWidget {
  const PerfilView({super.key});

  @override
  State<PerfilView> createState() => _PerfilViewState();
}

class _PerfilViewState extends State<PerfilView> {
  final _formKey = GlobalKey<FormState>();
  final _senhaAtualCtrl  = TextEditingController();
  final _novoEmailCtrl   = TextEditingController();
  final _novaSenhaCtrl   = TextEditingController();
  final _confirmarCtrl   = TextEditingController();

  String _emailAtual = '';
  bool _carregando = true;
  bool _salvando   = false;
  bool _ocultarSenhaAtual  = true;
  bool _ocultarNovaSenha   = true;
  bool _ocultarConfirmar   = true;

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  @override
  void dispose() {
    _senhaAtualCtrl.dispose();
    _novoEmailCtrl.dispose();
    _novaSenhaCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarPerfil() async {
    try {
      final me = await AuthService.me();
      setState(() {
        _emailAtual = me['email'] as String? ?? '';
        _carregando = false;
      });
    } catch (_) {
      setState(() => _carregando = false);
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final novoEmail  = _novoEmailCtrl.text.trim();
    final novaSenha  = _novaSenhaCtrl.text.trim();

    if (novoEmail.isEmpty && novaSenha.isEmpty) {
      _msg('Preencha o novo e-mail ou a nova senha para salvar');
      return;
    }

    setState(() => _salvando = true);
    try {
      final emailAtualizado = await AuthService.atualizarPerfil(
        senhaAtual: _senhaAtualCtrl.text,
        novoEmail:  novoEmail.isEmpty  ? null : novoEmail,
        novaSenha:  novaSenha.isEmpty  ? null : novaSenha,
      );
      setState(() {
        _emailAtual = emailAtualizado;
        _salvando   = false;
      });
      _senhaAtualCtrl.clear();
      _novoEmailCtrl.clear();
      _novaSenhaCtrl.clear();
      _confirmarCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso'),
            backgroundColor: Color(0xFF238636),
          ),
        );
      }
    } catch (e) {
      setState(() => _salvando = false);
      _msg(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _msg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meu Cadastro')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD300)))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cadastro do Administrador',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'E-mail atual: $_emailAtual',
                          style: const TextStyle(color: Color(0xFF7A7E85)),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'Alterar dados',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFD300),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _senhaAtualCtrl,
                          obscureText: _ocultarSenhaAtual,
                          decoration: InputDecoration(
                            labelText: 'Senha atual *',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _ocultarSenhaAtual
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () => setState(
                                  () => _ocultarSenhaAtual = !_ocultarSenhaAtual),
                            ),
                          ),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Informe a senha atual' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _novoEmailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Novo e-mail (opcional)',
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return null;
                            if (!v.contains('@') || !v.contains('.')) {
                              return 'E-mail inválido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _novaSenhaCtrl,
                          obscureText: _ocultarNovaSenha,
                          decoration: InputDecoration(
                            labelText: 'Nova senha (opcional, mín. 6 caracteres)',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _ocultarNovaSenha
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () => setState(
                                  () => _ocultarNovaSenha = !_ocultarNovaSenha),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return null;
                            if (v.length < 6) return 'Mínimo 6 caracteres';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmarCtrl,
                          obscureText: _ocultarConfirmar,
                          decoration: InputDecoration(
                            labelText: 'Confirmar nova senha',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _ocultarConfirmar
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () => setState(
                                  () => _ocultarConfirmar = !_ocultarConfirmar),
                            ),
                          ),
                          validator: (v) {
                            final nova = _novaSenhaCtrl.text;
                            if (nova.isEmpty) return null;
                            if (v != nova) return 'As senhas não coincidem';
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _salvando ? null : _salvar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFD300),
                              foregroundColor: const Color(0xFF16181B),
                            ),
                            child: _salvando
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF16181B)),
                                  )
                                : const Text(
                                    'Salvar Alterações',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
