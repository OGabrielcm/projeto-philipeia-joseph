import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import 'cliente_model.dart';
import 'cliente_service.dart';
import 'cliente_form_sheet.dart';

class ClienteSearchField extends ConsumerStatefulWidget {
  const ClienteSearchField({
    super.key,
    required this.onClienteSelected,
    this.initialCliente,
  });

  final void Function(Cliente?) onClienteSelected;
  final Cliente? initialCliente;

  @override
  ConsumerState<ClienteSearchField> createState() => _ClienteSearchFieldState();
}

class _ClienteSearchFieldState extends ConsumerState<ClienteSearchField> {
  final _ctrl        = TextEditingController();
  Cliente? _selected;
  List<Cliente> _suggestions = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialCliente != null) {
      _selected = widget.initialCliente;
      _ctrl.text = widget.initialCliente!.nome;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.length < 2) {
      setState(() => _suggestions = []);
      return;
    }
    setState(() => _loading = true);
    try {
      final results = await ref.read(clienteServiceProvider).buscar(q);
      setState(() => _suggestions = results);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _select(Cliente c) {
    setState(() {
      _selected    = c;
      _suggestions = [];
      _ctrl.text   = c.nome;
    });
    widget.onClienteSelected(c);
  }

  void _clear() {
    setState(() {
      _selected    = null;
      _suggestions = [];
      _ctrl.clear();
    });
    widget.onClienteSelected(null);
  }

  Future<void> _openCreateSheet() async {
    final novo = await showClienteFormSheet(context);
    if (novo != null) _select(novo);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _ctrl,
          readOnly: _selected != null,
          decoration: InputDecoration(
            labelText: 'Cliente',
            hintText: 'Buscar por nome ou CPF...',
            suffixIcon: _selected != null
                ? IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    onPressed: _clear,
                  )
                : _loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.search, color: AppColors.textMuted),
          ),
          onChanged: _search,
          validator: (_) => _selected == null ? 'Selecione ou crie um cliente' : null,
        ),
        if (_selected != null) ...[
          const SizedBox(height: 6),
          Text(
            _selected!.enderecoFormatado,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: AppColors.bgTertiary,
              border: Border.all(color: AppColors.borderColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                ..._suggestions.map((c) => ListTile(
                      title: Text(c.nome, style: const TextStyle(color: AppColors.textPrimary)),
                      subtitle: Text(
                        'CPF: ${c.cpf} — ${c.enderecoCidade}/${c.enderecoEstado}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      onTap: () => _select(c),
                    )),
                ListTile(
                  leading: const Icon(Icons.add, color: AppColors.accent),
                  title: const Text('Criar novo cliente',
                      style: TextStyle(color: AppColors.accent)),
                  onTap: _openCreateSheet,
                ),
              ],
            ),
          ),
        if (_suggestions.isEmpty && _selected == null && _ctrl.text.length >= 2 && !_loading)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              icon: const Icon(Icons.add, color: AppColors.accent),
              label: const Text('Criar novo cliente',
                  style: TextStyle(color: AppColors.accent)),
              onPressed: _openCreateSheet,
            ),
          ),
      ],
    );
  }
}
