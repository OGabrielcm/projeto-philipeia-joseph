import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/catalogo_service.dart';
import '../../services/cliente_service.dart';
import '../../services/pedido_service.dart';

class NovoPedidoView extends StatefulWidget {
  const NovoPedidoView({super.key});

  @override
  State<NovoPedidoView> createState() => _NovoPedidoViewState();
}

class _NovoPedidoViewState extends State<NovoPedidoView> {
  // ---------- cliente ----------
  Map<String, dynamic>? _clienteSelecionado;
  List<dynamic> _resultadosBusca = [];
  final _buscaCtrl = TextEditingController();
  bool _buscando = false;

  // ---------- evento ----------
  final _nomeEventoCtrl = TextEditingController();

  // ---------- datas ----------
  DateTime? _dataEvento;
  TimeOfDay? _horaInicio;
  DateTime? _dataRecolhimento;
  TimeOfDay? _horaRecolhimento;

  // ---------- endereço ----------
  final _logradouroCtrl   = TextEditingController();
  final _numeroCtrl       = TextEditingController();
  final _complementoCtrl  = TextEditingController();
  final _bairroCtrl       = TextEditingController();
  final _cidadeCtrl       = TextEditingController();
  final _estadoCtrl       = TextEditingController();
  final _cepCtrl          = TextEditingController();
  final _outrasInfoCtrl   = TextEditingController();

  // ---------- produtos ----------
  List<dynamic> _estilos = [];
  // style_volume_id → quantidade selecionada
  final Map<int, int> _itensSelecionados = {};
  bool _carregandoCatalogo = true;

  // ---------- valores ----------
  double _taxaInstalacao = 100.0;
  final _taxaCtrl = TextEditingController(text: '100.00');

  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _carregarCatalogo();
    _taxaCtrl.addListener(_onTaxaChanged);
  }

  void _onTaxaChanged() {
    final v = double.tryParse(_taxaCtrl.text) ?? 0;
    if (_taxaInstalacao != v) setState(() => _taxaInstalacao = v);
  }

  Future<void> _carregarCatalogo() async {
    try {
      final estilos = await CatalogoService.listarEstilos();
      setState(() { _estilos = estilos; _carregandoCatalogo = false; });
    } catch (_) {
      setState(() => _carregandoCatalogo = false);
    }
  }

  // ---- Busca de clientes ----
  Future<void> _buscarClientes() async {
    final q = _buscaCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() => _buscando = true);
    try {
      final lista = await ClienteService.buscar(q);
      setState(() { _resultadosBusca = lista; });
    } catch (_) {
      _msg('Erro ao buscar clientes');
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  void _selecionarCliente(Map<String, dynamic> cliente) {
    setState(() {
      _clienteSelecionado = cliente;
      _resultadosBusca   = [];
      _buscaCtrl.clear();
      // Auto-preencher endereço
      _logradouroCtrl.text  = cliente['endereco_logradouro']  ?? '';
      _numeroCtrl.text      = cliente['endereco_numero']       ?? '';
      _complementoCtrl.text = cliente['endereco_complemento'] ?? '';
      _bairroCtrl.text      = cliente['endereco_bairro']      ?? '';
      _cidadeCtrl.text      = cliente['endereco_cidade']      ?? '';
      _estadoCtrl.text      = cliente['endereco_estado']      ?? '';
      _cepCtrl.text         = cliente['endereco_cep']         ?? '';
    });
  }

  // ---- Novo cliente via dialog ----
  Future<void> _abrirCriarCliente() async {
    final nomeCtrl    = TextEditingController();
    final cpfCtrl     = TextEditingController();
    final telefCtrl   = TextEditingController();
    final emailCtrl   = TextEditingController();
    final logCtrl     = TextEditingController();
    final numCtrl     = TextEditingController();
    final bairroCtrl2 = TextEditingController();
    final cidadeCtrl2 = TextEditingController();
    final estCtrl     = TextEditingController();
    final cepCtrl2    = TextEditingController();

    final novoCliente = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cadastrar Cliente'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _campo(nomeCtrl,    'Nome *'),
              _campo(cpfCtrl,     'CPF * (somente números)', tipo: TextInputType.number),
              _campo(telefCtrl,   'Telefone * (somente números)', tipo: TextInputType.phone),
              _campo(emailCtrl,   'E-mail', tipo: TextInputType.emailAddress),
              const Divider(),
              _campo(logCtrl,     'Logradouro *'),
              _campo(numCtrl,     'Número *'),
              _campo(bairroCtrl2, 'Bairro *'),
              _campo(cidadeCtrl2, 'Cidade *'),
              _campo(estCtrl,     'UF * (2 letras)', maxLen: 2),
              _campo(cepCtrl2,    'CEP * (8 dígitos)', tipo: TextInputType.number, maxLen: 8),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final c = await ClienteService.criar({
                  'nome':                 nomeCtrl.text.trim(),
                  'cpf':                  cpfCtrl.text.trim(),
                  'telefone':             telefCtrl.text.trim(),
                  'email':                emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : null,
                  'endereco_logradouro':  logCtrl.text.trim(),
                  'endereco_numero':      numCtrl.text.trim(),
                  'endereco_bairro':      bairroCtrl2.text.trim(),
                  'endereco_cidade':      cidadeCtrl2.text.trim(),
                  'endereco_estado':      estCtrl.text.trim().toUpperCase(),
                  'endereco_cep':         cepCtrl2.text.trim(),
                });
                if (ctx.mounted) Navigator.pop(ctx, c);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                  );
                }
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (novoCliente != null) {
      _selecionarCliente(novoCliente);
    }
  }

  TextField _campo(TextEditingController ctrl, String label,
      {TextInputType tipo = TextInputType.text, int? maxLen}) {
    return TextField(
      controller: ctrl,
      keyboardType: tipo,
      maxLength: maxLen,
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  // ---- Cálculos ----
  double _calcSubtotal() {
    double sub = 0;
    for (final estilo in _estilos) {
      for (final vol in estilo['volumes'] as List<dynamic>) {
        final svId = vol['id'] as int;
        final qty  = _itensSelecionados[svId] ?? 0;
        if (qty > 0) sub += qty * (vol['preco'] as num).toDouble();
      }
    }
    return sub;
  }

  // ---- Seletores de data/hora ----
  Future<void> _selecionarData(bool isEvento) async {
    final atual = isEvento ? _dataEvento : _dataRecolhimento;
    final ctrl = TextEditingController(text: atual != null ? _fmtData(atual) : '');
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        String? erroLocal;
        return StatefulBuilder(builder: (ctx, setLocal) {
          return AlertDialog(
            title: Text(isEvento ? 'Data do Evento' : 'Data de Recolhimento'),
            content: TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [_DateInputFormatter()],
              decoration: InputDecoration(
                labelText: 'dd/MM/yyyy',
                errorText: erroLocal,
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () {
                  final parsed = _parseData(ctrl.text);
                  if (parsed == null) {
                    setLocal(() => erroLocal = 'Data inválida');
                    return;
                  }
                  if (!isEvento && _dataEvento != null && parsed.isBefore(_dataEvento!)) {
                    setLocal(() => erroLocal = 'Deve ser >= data do evento');
                    return;
                  }
                  setState(() {
                    if (isEvento) {
                      _dataEvento = parsed;
                      if (_dataRecolhimento == null || _dataRecolhimento!.isBefore(parsed)) {
                        _dataRecolhimento = parsed;
                      }
                    } else {
                      _dataRecolhimento = parsed;
                    }
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('OK'),
              ),
            ],
          );
        });
      },
    );
    ctrl.dispose();
  }

  Future<void> _selecionarHora(bool isInicio) async {
    final atual = isInicio ? _horaInicio : _horaRecolhimento;
    final ctrl = TextEditingController(text: atual != null ? _fmtHora(atual) : '');
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        String? erroLocal;
        return StatefulBuilder(builder: (ctx, setLocal) {
          return AlertDialog(
            title: Text(isInicio ? 'Hora de Início' : 'Hora de Recolhimento'),
            content: TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [_TimeInputFormatter()],
              decoration: InputDecoration(
                labelText: 'HH:mm',
                errorText: erroLocal,
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () {
                  final parsed = _parseHora(ctrl.text);
                  if (parsed == null) {
                    setLocal(() => erroLocal = 'Hora inválida (HH:mm)');
                    return;
                  }
                  setState(() {
                    if (isInicio) _horaInicio = parsed;
                    else _horaRecolhimento = parsed;
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('OK'),
              ),
            ],
          );
        });
      },
    );
    ctrl.dispose();
  }

  DateTime? _parseData(String s) {
    try {
      final p = s.split('/');
      if (p.length != 3) return null;
      final d = int.parse(p[0]), m = int.parse(p[1]), y = int.parse(p[2]);
      if (d < 1 || d > 31 || m < 1 || m > 12 || y < 2024) return null;
      return DateTime(y, m, d);
    } catch (_) { return null; }
  }

  TimeOfDay? _parseHora(String s) {
    try {
      final p = s.split(':');
      if (p.length != 2) return null;
      final h = int.parse(p[0]), min = int.parse(p[1]);
      if (h < 0 || h > 23 || min < 0 || min > 59) return null;
      return TimeOfDay(hour: h, minute: min);
    } catch (_) { return null; }
  }

  String _fmtData(DateTime? d) => d == null ? 'Selecionar' : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  String _fmtHora(TimeOfDay? t) => t == null ? 'Selecionar' : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  // ---- Salvar ----
  Future<void> _salvarPedido() async {
    if (_clienteSelecionado == null) { _msg('Selecione um cliente'); return; }
    if (_dataEvento == null)          { _msg('Informe a data do evento'); return; }
    if (_horaInicio == null)          { _msg('Informe a hora de início'); return; }
    if (_dataRecolhimento == null)    { _msg('Informe a data de recolhimento'); return; }
    if (_horaRecolhimento == null)    { _msg('Informe a hora de recolhimento'); return; }
    if (_logradouroCtrl.text.trim().isEmpty) { _msg('Informe o logradouro'); return; }
    if (_numeroCtrl.text.trim().isEmpty)     { _msg('Informe o número'); return; }
    if (_bairroCtrl.text.trim().isEmpty)     { _msg('Informe o bairro'); return; }
    if (_cidadeCtrl.text.trim().isEmpty)     { _msg('Informe a cidade'); return; }
    if (_estadoCtrl.text.trim().length != 2) { _msg('UF deve ter 2 letras'); return; }
    if (_cepCtrl.text.replaceAll(RegExp(r'\D'), '').length != 8) { _msg('CEP inválido'); return; }

    final itens = <Map<String, dynamic>>[];
    for (final estilo in _estilos) {
      for (final vol in estilo['volumes'] as List<dynamic>) {
        final svId = vol['id'] as int;
        final qty  = _itensSelecionados[svId] ?? 0;
        if (qty > 0) {
          itens.add({
            'tipo':            'item',
            'style_volume_id': svId,
            'quantidade':      qty,
            'preco_unitario':  vol['preco'],
          });
        }
      }
    }
    if (itens.isEmpty) { _msg('Selecione pelo menos um produto'); return; }

    final fmtDate = (DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final fmtTime = (TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    final nomeEvento = _nomeEventoCtrl.text.trim();
    final outrasInfo = _outrasInfoCtrl.text.trim();
    final observacoes = [
      if (nomeEvento.isNotEmpty) 'Evento: $nomeEvento',
      if (outrasInfo.isNotEmpty) outrasInfo,
    ].join('\n').trim();

    final payload = {
      'customer_id':       _clienteSelecionado!['id'],
      'status':            'pendente',
      'data_evento':       fmtDate(_dataEvento!),
      'hora_inicio':       fmtTime(_horaInicio!),
      'data_recolhimento': fmtDate(_dataRecolhimento!),
      'hora_recolhimento': fmtTime(_horaRecolhimento!),
      'endereco': {
        'logradouro':  _logradouroCtrl.text.trim(),
        'numero':      _numeroCtrl.text.trim(),
        'complemento': _complementoCtrl.text.trim().isNotEmpty ? _complementoCtrl.text.trim() : null,
        'bairro':      _bairroCtrl.text.trim(),
        'cidade':      _cidadeCtrl.text.trim(),
        'estado':      _estadoCtrl.text.trim().toUpperCase(),
        'cep':         _cepCtrl.text.replaceAll(RegExp(r'\D'), ''),
      },
      if (observacoes.isNotEmpty) 'observacoes': observacoes,
      'taxa_instalacao': _taxaInstalacao,
      'desconto':        0,
      'itens':           itens,
    };

    setState(() => _salvando = true);
    try {
      await PedidoService.criar(payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pedido criado com sucesso!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _msg(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _msg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    final subtotal = _calcSubtotal();
    final total    = subtotal + _taxaInstalacao;

    return Scaffold(
      appBar: AppBar(title: const Text('Novo Pedido')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Seção 1: Cliente ───────────────────────────────────
            _secao('Dados do Cliente', [
              if (_clienteSelecionado != null)
                _clienteCard(_clienteSelecionado!)
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _buscaCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Buscar cliente por nome ou CPF',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onSubmitted: (_) => _buscarClientes(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _buscando ? null : _buscarClientes,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12)),
                      child: _buscando
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF16181B)))
                          : const Icon(Icons.search),
                    ),
                  ],
                ),
                if (_resultadosBusca.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF16181B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF3A3D42)),
                    ),
                    child: Column(
                      children: _resultadosBusca.map((c) {
                        final cliente = c as Map<String, dynamic>;
                        return ListTile(
                          leading: const Icon(Icons.person, color: Color(0xFF7A7E85)),
                          title: Text(cliente['nome'] as String),
                          subtitle: Text('CPF: ${cliente['cpf']}', style: const TextStyle(fontSize: 12)),
                          onTap: () => _selecionarCliente(cliente),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text('Cadastrar Novo Cliente'),
                  onPressed: _abrirCriarCliente,
                ),
              ],
            ]),

            // ─── Nome do Evento ──────────────────────────────────────
            _secao('Nome do Evento', [
              TextField(
                controller: _nomeEventoCtrl,
                decoration: const InputDecoration(labelText: 'Nome do Evento'),
              ),
            ]),

            // ─── Seção 2: Data e Horário ─────────────────────────────
            _secao('Data e Horário', [
              Row(children: [
                Expanded(child: _seletorBotao('Data do Evento *', _fmtData(_dataEvento), () => _selecionarData(true))),
                const SizedBox(width: 12),
                Expanded(child: _seletorBotao('Hora de Início *', _fmtHora(_horaInicio), () => _selecionarHora(true))),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _seletorBotao('Data Recolhimento *', _fmtData(_dataRecolhimento), () => _selecionarData(false))),
                const SizedBox(width: 12),
                Expanded(child: _seletorBotao('Hora Recolhimento *', _fmtHora(_horaRecolhimento), () => _selecionarHora(false))),
              ]),
            ]),

            // ─── Seção 3: Endereço ───────────────────────────────────
            _secao('Endereço', [
              _tf(_logradouroCtrl, 'Logradouro *'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(flex: 3, child: _tf(_numeroCtrl, 'Número *')),
                const SizedBox(width: 12),
                Expanded(flex: 5, child: _tf(_complementoCtrl, 'Complemento')),
              ]),
              const SizedBox(height: 12),
              _tf(_bairroCtrl, 'Bairro *'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(flex: 5, child: _tf(_cidadeCtrl, 'Cidade *')),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: _tf(_estadoCtrl, 'UF *', maxLen: 2)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(flex: 4, child: _tf(_cepCtrl, 'CEP *', tipo: TextInputType.number, maxLen: 8)),
                const SizedBox(width: 12),
                Expanded(flex: 5, child: _tf(_outrasInfoCtrl, 'Outras Informações')),
              ]),
            ]),

            // ─── Seção 4: Produtos ───────────────────────────────────
            _secao('Produtos', [
              if (_carregandoCatalogo)
                const Center(child: CircularProgressIndicator(color: Color(0xFFFFD300)))
              else if (_estilos.isEmpty)
                const Text('Nenhum produto disponível', style: TextStyle(color: Color(0xFF7A7E85)))
              else
                ..._estilos.map((estilo) => _estiloCard(estilo)).toList(),
            ]),

            // ─── Seção 5: Valores ─────────────────────────────────────
            _secao('Valores', [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Subtotal:', style: TextStyle(color: Color(0xFFB5B9C0))),
                Text('R\$ ${subtotal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                const Expanded(child: Text('Taxa de Instalação:', style: TextStyle(color: Color(0xFFB5B9C0)))),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _taxaCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      prefixText: 'R\$ ',
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFF3A3D42)),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('TOTAL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(
                  'R\$ ${total.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFFD300)),
                ),
              ]),
            ]),

            // ─── Botões ───────────────────────────────────────────────
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _salvando ? null : _salvarPedido,
                  child: _salvando
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF16181B)))
                      : const Text('Salvar Pedido', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _secao(String titulo, List<Widget> filhos) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D31),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3A3D42)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFFD300))),
            const SizedBox(height: 16),
            ...filhos,
          ],
        ),
      ),
    );
  }

  Widget _tf(TextEditingController ctrl, String label,
      {TextInputType tipo = TextInputType.text, int? maxLen}) {
    return TextField(
      controller: ctrl,
      keyboardType: tipo,
      maxLength: maxLen,
      decoration: InputDecoration(labelText: label, counterText: ''),
    );
  }

  Widget _seletorBotao(String label, String valor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF16181B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF3A3D42)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF7A7E85), fontSize: 11)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(valor, style: const TextStyle(color: Colors.white, fontSize: 14)),
                const Icon(Icons.arrow_drop_down, color: Color(0xFF7A7E85)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _clienteCard(Map<String, dynamic> c) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF16181B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFD300).withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, color: Color(0xFFFFD300)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c['nome'] as String, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                Text('CPF: ${c['cpf']}  •  Tel: ${c['telefone']}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF7A7E85))),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF7A7E85), size: 20),
            onPressed: () => setState(() {
              _clienteSelecionado = null;
              _logradouroCtrl.clear();
              _numeroCtrl.clear();
              _complementoCtrl.clear();
              _bairroCtrl.clear();
              _cidadeCtrl.clear();
              _estadoCtrl.clear();
              _cepCtrl.clear();
            }),
          ),
        ],
      ),
    );
  }

  Widget _estiloCard(Map<String, dynamic> estilo) {
    final volumes = estilo['volumes'] as List<dynamic>;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16181B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3A3D42)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.local_drink, color: Color(0xFFFFD300), size: 18),
              const SizedBox(width: 8),
              Text(estilo['nome'] as String, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(width: 8),
              Text('(${estilo['categoria']})', style: const TextStyle(color: Color(0xFF7A7E85), fontSize: 12)),
            ]),
            const SizedBox(height: 10),
            ...volumes.map((vol) {
              final svId = vol['id'] as int;
              final qty  = _itensSelecionados[svId] ?? 0;
              final selecionado = qty > 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: selecionado ? const Color(0xFFFFD300).withOpacity(0.08) : const Color(0xFF2A2D31),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: selecionado ? const Color(0xFFFFD300).withOpacity(0.4) : const Color(0xFF3A3D42),
                  ),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: selecionado,
                      activeColor: const Color(0xFFFFD300),
                      checkColor: const Color(0xFF16181B),
                      onChanged: (_) => setState(() {
                        if (selecionado) {
                          _itensSelecionados.remove(svId);
                        } else {
                          _itensSelecionados[svId] = 1;
                        }
                      }),
                    ),
                    Text('${vol['volume_litros']}L', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    Text(
                      '- R\$ ${(vol['preco'] as num).toStringAsFixed(2)}',
                      style: const TextStyle(color: Color(0xFF7A7E85), fontSize: 13),
                    ),
                    const Spacer(),
                    if (selecionado) ...[
                      IconButton(
                        icon: const Icon(Icons.remove, size: 18),
                        color: const Color(0xFFB5B9C0),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: () => setState(() {
                          if (qty > 1) _itensSelecionados[svId] = qty - 1;
                          else _itensSelecionados.remove(svId);
                        }),
                      ),
                      SizedBox(
                        width: 28,
                        child: Text('$qty', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18),
                        color: const Color(0xFFFFD300),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: () => setState(() => _itensSelecionados[svId] = qty + 1),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    _nomeEventoCtrl.dispose();
    _logradouroCtrl.dispose();
    _numeroCtrl.dispose();
    _complementoCtrl.dispose();
    _bairroCtrl.dispose();
    _cidadeCtrl.dispose();
    _estadoCtrl.dispose();
    _cepCtrl.dispose();
    _outrasInfoCtrl.dispose();
    _taxaCtrl.removeListener(_onTaxaChanged);
    _taxaCtrl.dispose();
    super.dispose();
  }
}

class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue _, TextEditingValue next) {
    final digits = next.text.replaceAll(RegExp(r'[^0-9]'), '');
    final buf = StringBuffer();
    for (var i = 0; i < digits.length && i < 8; i++) {
      if (i == 2 || i == 4) buf.write('/');
      buf.write(digits[i]);
    }
    final s = buf.toString();
    return next.copyWith(text: s, selection: TextSelection.collapsed(offset: s.length));
  }
}

class _TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue _, TextEditingValue next) {
    final digits = next.text.replaceAll(RegExp(r'[^0-9]'), '');
    final buf = StringBuffer();
    for (var i = 0; i < digits.length && i < 4; i++) {
      if (i == 2) buf.write(':');
      buf.write(digits[i]);
    }
    final s = buf.toString();
    return next.copyWith(text: s, selection: TextSelection.collapsed(offset: s.length));
  }
}
