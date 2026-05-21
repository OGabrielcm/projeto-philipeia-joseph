import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/dio_client.dart' show dioMessage;
import '../../core/theme/app_colors.dart';
import 'cliente_model.dart';
import 'cliente_service.dart';

Future<Cliente?> showClienteFormSheet(BuildContext context) {
  return showModalBottomSheet<Cliente>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bgSecondary,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const _ClienteFormSheet(),
  );
}

class _ClienteFormSheet extends ConsumerStatefulWidget {
  const _ClienteFormSheet();

  @override
  ConsumerState<_ClienteFormSheet> createState() => _ClienteFormSheetState();
}

class _ClienteFormSheetState extends ConsumerState<_ClienteFormSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _loading  = false;

  final _nome           = TextEditingController();
  final _cpf            = TextEditingController();
  final _telefone       = TextEditingController();
  final _email          = TextEditingController();
  final _logradouro     = TextEditingController();
  final _numero         = TextEditingController();
  final _complemento    = TextEditingController();
  final _bairro         = TextEditingController();
  final _cidade         = TextEditingController();
  final _estado         = TextEditingController();
  final _cep            = TextEditingController();

  @override
  void dispose() {
    for (final c in [_nome, _cpf, _telefone, _email, _logradouro,
                     _numero, _complemento, _bairro, _cidade, _estado, _cep]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final cliente = await ref.read(clienteServiceProvider).criar({
        'nome':                 _nome.text.trim(),
        'cpf':                  _cpf.text.replaceAll(RegExp(r'\D'), ''),
        'telefone':             _telefone.text.replaceAll(RegExp(r'\D'), ''),
        'email':                _email.text.trim().isEmpty ? null : _email.text.trim(),
        'endereco_logradouro':  _logradouro.text.trim(),
        'endereco_numero':      _numero.text.trim(),
        'endereco_complemento': _complemento.text.trim().isEmpty ? null : _complemento.text.trim(),
        'endereco_bairro':      _bairro.text.trim(),
        'endereco_cidade':      _cidade.text.trim(),
        'endereco_estado':      _estado.text.trim().toUpperCase(),
        'endereco_cep':         _cep.text.replaceAll(RegExp(r'\D'), ''),
      });
      if (mounted) Navigator.of(context).pop(cliente);
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(dioMessage(e)), backgroundColor: AppColors.danger),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('Novo cliente',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ]),
              const SizedBox(height: 16),
              _field(_nome, 'Nome completo', required: true),
              _field(_cpf, 'CPF', hint: '000.000.000-00',
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 11,
                  validator: (v) {
                    final d = v?.replaceAll(RegExp(r'\D'), '') ?? '';
                    return d.length == 11 ? null : 'CPF deve ter 11 dígitos';
                  }),
              _field(_telefone, 'Telefone', hint: '(83) 99999-9999',
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 11, required: true),
              _field(_email, 'E-mail (opcional)',
                  keyboardType: TextInputType.emailAddress),
              const Divider(height: 32),
              Text('Endereço', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
              _field(_logradouro, 'Logradouro', required: true),
              Row(children: [
                Expanded(child: _field(_numero, 'Número', required: true)),
                const SizedBox(width: 12),
                Expanded(child: _field(_complemento, 'Complemento')),
              ]),
              _field(_bairro, 'Bairro', required: true),
              Row(children: [
                Expanded(flex: 3, child: _field(_cidade, 'Cidade', required: true)),
                const SizedBox(width: 12),
                Expanded(child: _field(_estado, 'UF', maxLength: 2, required: true)),
              ]),
              _field(_cep, 'CEP',
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 8, required: true),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentText))
                      : const Text('Salvar cliente'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    String? hint,
    bool required = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(labelText: label, hintText: hint, counterText: ''),
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        validator: validator ??
            (required
                ? (v) => (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null
                : null),
      ),
    );
  }
}
