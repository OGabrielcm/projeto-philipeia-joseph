import 'package:flutter/material.dart';
import '../../services/cliente_service.dart';

class ClientesView extends StatefulWidget {
  const ClientesView({super.key, this.refreshKey = 0});
  final int refreshKey;

  @override
  State<ClientesView> createState() => _ClientesViewState();
}

class _ClientesViewState extends State<ClientesView> {
  List<dynamic> _clientes = [];
  bool _carregando = true;
  String? _erro;
  final _buscaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarClientes();
  }

  @override
  void didUpdateWidget(ClientesView old) {
    super.didUpdateWidget(old);
    if (old.refreshKey != widget.refreshKey) _carregarClientes();
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarClientes() async {
    setState(() { _carregando = true; _erro = null; });
    try {
      final lista = await ClienteService.buscar(_buscaCtrl.text.trim(), perPage: 100);
      setState(() { _clientes = lista; _carregando = false; });
    } catch (e) {
      setState(() { _erro = e.toString(); _carregando = false; });
    }
  }

  void _msg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _abrirForm({Map<String, dynamic>? cliente}) async {
    final nomeCtrl   = TextEditingController(text: cliente?['nome']                as String? ?? '');
    final cpfCtrl    = TextEditingController(text: cliente?['cpf']                 as String? ?? '');
    final telCtrl    = TextEditingController(text: cliente?['telefone']            as String? ?? '');
    final emailCtrl  = TextEditingController(text: cliente?['email']               as String? ?? '');
    final logCtrl    = TextEditingController(text: cliente?['endereco_logradouro'] as String? ?? '');
    final numCtrl    = TextEditingController(text: cliente?['endereco_numero']     as String? ?? '');
    final compCtrl   = TextEditingController(text: cliente?['endereco_complemento'] as String? ?? '');
    final bairroCtrl = TextEditingController(text: cliente?['endereco_bairro']    as String? ?? '');
    final cidadeCtrl = TextEditingController(text: cliente?['endereco_cidade']    as String? ?? '');
    final estCtrl    = TextEditingController(text: cliente?['endereco_estado']    as String? ?? '');
    final cepCtrl    = TextEditingController(text: cliente?['endereco_cep']       as String? ?? '');

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(cliente == null ? 'Novo Cliente' : 'Editar Cliente'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _tf(nomeCtrl,   'Nome *'),
                const SizedBox(height: 10),
                _tf(cpfCtrl,    'CPF * (somente números)', tipo: TextInputType.number),
                const SizedBox(height: 10),
                _tf(telCtrl,    'Telefone * (somente números)', tipo: TextInputType.phone),
                const SizedBox(height: 10),
                _tf(emailCtrl,  'E-mail', tipo: TextInputType.emailAddress),
                const Divider(height: 24),
                _tf(logCtrl,    'Logradouro *'),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(flex: 2, child: _tf(numCtrl,    'Número *')),
                  const SizedBox(width: 8),
                  Expanded(flex: 3, child: _tf(compCtrl,   'Complemento')),
                ]),
                const SizedBox(height: 10),
                _tf(bairroCtrl, 'Bairro *'),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(flex: 5, child: _tf(cidadeCtrl, 'Cidade *')),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: _tf(estCtrl,    'UF *', maxLen: 2)),
                ]),
                const SizedBox(height: 10),
                _tf(cepCtrl, 'CEP * (8 dígitos)', tipo: TextInputType.number, maxLen: 8),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final payload = {
                'nome':                  nomeCtrl.text.trim(),
                'cpf':                   cpfCtrl.text.trim(),
                'telefone':              telCtrl.text.trim(),
                'email':                 emailCtrl.text.trim().isNotEmpty
                    ? emailCtrl.text.trim()
                    : null,
                'endereco_logradouro':   logCtrl.text.trim(),
                'endereco_numero':       numCtrl.text.trim(),
                'endereco_complemento':  compCtrl.text.trim().isNotEmpty
                    ? compCtrl.text.trim()
                    : null,
                'endereco_bairro':       bairroCtrl.text.trim(),
                'endereco_cidade':       cidadeCtrl.text.trim(),
                'endereco_estado':       estCtrl.text.trim().toUpperCase(),
                'endereco_cep':          cepCtrl.text.trim(),
              };
              try {
                if (cliente == null) {
                  await ClienteService.criar(payload);
                } else {
                  await ClienteService.atualizar(cliente['id'] as int, payload);
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _carregarClientes();
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceFirst('Exception: ', '')),
                    ),
                  );
                }
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    for (final c in [nomeCtrl, cpfCtrl, telCtrl, emailCtrl, logCtrl, numCtrl,
                     compCtrl, bairroCtrl, cidadeCtrl, estCtrl, cepCtrl]) {
      c.dispose();
    }
  }

  Future<void> _confirmarExclusao(Map<String, dynamic> cliente) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir Cliente'),
        content: Text('Excluir "${cliente['nome']}"? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF85149)),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ClienteService.excluir(cliente['id'] as int);
        _carregarClientes();
      } catch (e) {
        if (mounted) _msg(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  TextField _tf(TextEditingController ctrl, String label, {
    TextInputType tipo = TextInputType.text,
    int? maxLen,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: tipo,
      maxLength: maxLen,
      decoration: InputDecoration(labelText: label, counterText: ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _buscaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Buscar por nome ou CPF',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _carregarClientes(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _carregarClientes,
                  ),
                ],
              ),
            ),
            Expanded(child: _buildLista()),
          ],
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            heroTag: 'fab_clientes',
            onPressed: () => _abrirForm(),
            backgroundColor: const Color(0xFFFFD300),
            foregroundColor: const Color(0xFF16181B),
            tooltip: 'Novo Cliente',
            child: const Icon(Icons.person_add),
          ),
        ),
      ],
    );
  }

  Widget _buildLista() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD300)));
    }
    if (_erro != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_erro!, style: const TextStyle(color: Color(0xFFF85149))),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _carregarClientes, child: const Text('Tentar novamente')),
        ]),
      );
    }
    if (_clientes.isEmpty) {
      return const Center(
        child: Text('Nenhum cliente encontrado',
            style: TextStyle(color: Color(0xFF7A7E85))),
      );
    }
    return RefreshIndicator(
      onRefresh: _carregarClientes,
      color: const Color(0xFFFFD300),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
        itemCount: _clientes.length,
        itemBuilder: (_, i) {
          final c = _clientes[i] as Map<String, dynamic>;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Color(0xFFFFD300), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c['nome'] as String,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'CPF: ${c['cpf']}  •  Tel: ${c['telefone']}',
                          style: const TextStyle(
                              color: Color(0xFF7A7E85), fontSize: 12),
                        ),
                        Text(
                          '${c['endereco_bairro']}, ${c['endereco_cidade']} - ${c['endereco_estado']}',
                          style: const TextStyle(
                              color: Color(0xFF7A7E85), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        size: 18, color: Color(0xFF7A7E85)),
                    tooltip: 'Editar',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: () => _abrirForm(cliente: c),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: Color(0xFFF85149)),
                    tooltip: 'Excluir',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: () => _confirmarExclusao(c),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
