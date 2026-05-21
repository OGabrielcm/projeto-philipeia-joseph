import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/dio_client.dart' show dioMessage;
import '../../core/theme/app_colors.dart';
import 'auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  final _senhaCtrl  = TextEditingController();
  bool _loading     = false;
  bool _senhaVisible = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authServiceProvider).login(
        _emailCtrl.text.trim(),
        _senhaCtrl.text,
      );
      if (mounted) context.go('/pedidos');
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(dioMessage(e)), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Logo(),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'E-mail'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Informe o e-mail' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _senhaCtrl,
                    obscureText: !_senhaVisible,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _senhaVisible ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () =>
                            setState(() => _senhaVisible = !_senhaVisible),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Informe a senha' : null,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.accentText,
                              ),
                            )
                          : const Text('Entrar'),
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

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.sports_bar, size: 40, color: AppColors.accentText),
        ),
        const SizedBox(height: 16),
        Text(
          'Philipeia',
          style: Theme.of(context)
              .textTheme
              .titleLarge!
              .copyWith(fontSize: 24, letterSpacing: 1.2),
        ),
        const SizedBox(height: 4),
        Text(
          'Gestão de Pedidos',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
