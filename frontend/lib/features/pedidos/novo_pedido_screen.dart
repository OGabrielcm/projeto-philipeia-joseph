import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/dio_client.dart' show dioMessage;
import '../../core/theme/app_colors.dart';
import '../catalogo/catalogo_models.dart';
import '../catalogo/catalogo_provider.dart';
import '../clientes/cliente_model.dart';
import '../clientes/cliente_search_field.dart';
import 'pedido_service.dart';

// ── Item de linha do formulário ────────────────────────────────────────────────

enum TipoLinha { item, combo, consignado }

class _LinhaItem {
  TipoLinha tipo;
  int? styleVolumeId;
  int? comboId;
  int quantidade;
  double precoUnitario;

  _LinhaItem()
      : tipo = TipoLinha.item,
        styleVolumeId = null,
        comboId = null,
        quantidade = 1,
        precoUnitario = 0;

  double get subtotal => quantidade * precoUnitario;
}

// ── Screen ─────────────────────────────────────────────────────────────────────

class NovoPedidoScreen extends ConsumerStatefulWidget {
  const NovoPedidoScreen({super.key});

  @override
  ConsumerState<NovoPedidoScreen> createState() => _NovoPedidoScreenState();
}

class _NovoPedidoScreenState extends ConsumerState<NovoPedidoScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading  = false;

  // A — Cliente
  Cliente? _cliente;

  // B — Evento
  DateTime? _dataEvento;
  TimeOfDay? _horaInicio;
  DateTime? _dataRecolhimento;
  TimeOfDay? _horaRecolhimento;
  final _logradouro  = TextEditingController();
  final _numero      = TextEditingController();
  final _complemento = TextEditingController();
  final _bairro      = TextEditingController();
  final _cidade      = TextEditingController();
  final _estado      = TextEditingController();
  final _cep         = TextEditingController();
  final _obs         = TextEditingController();

  // C — Itens
  final List<_LinhaItem> _itens = [_LinhaItem()];

  // D — Valores
  final _taxaCtrl    = TextEditingController(text: '0,00');
  final _descontoCtrl = TextEditingController(text: '0,00');
  final _totalCtrl   = TextEditingController();
  bool _totalManual  = false;

  // E — Status
  String _status = 'pendente';

  @override
  void dispose() {
    for (final c in [_logradouro, _numero, _complemento, _bairro,
                     _cidade, _estado, _cep, _obs, _taxaCtrl, _descontoCtrl, _totalCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  double get _subtotal => _itens.fold(0, (s, i) => s + i.subtotal);
  double get _taxa     => double.tryParse(_taxaCtrl.text.replaceAll(',', '.')) ?? 0;
  double get _desconto => double.tryParse(_descontoCtrl.text.replaceAll(',', '.')) ?? 0;
  double get _totalCalc => _subtotal + _taxa - _desconto;

  void _recalcTotal() {
    if (!_totalManual) {
      _totalCtrl.text = _totalCalc.toStringAsFixed(2).replaceAll('.', ',');
    }
  }

  void _usarEnderecoCliente() {
    if (_cliente == null) return;
    setState(() {
      _logradouro.text  = _cliente!.enderecoLogradouro;
      _numero.text      = _cliente!.enderecoNumero;
      _complemento.text = _cliente!.enderecoComplemento ?? '';
      _bairro.text      = _cliente!.enderecoBairro;
      _cidade.text      = _cliente!.enderecoCidade;
      _estado.text      = _cliente!.enderecoEstado;
      _cep.text         = _cliente!.enderecoCep;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dataEvento == null || _horaInicio == null ||
        _dataRecolhimento == null || _horaRecolhimento == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Preencha todas as datas e horários'),
        backgroundColor: AppColors.danger,
      ));
      return;
    }

    setState(() => _loading = true);
    try {
      final total = double.tryParse(_totalCtrl.text.replaceAll(',', '.'));
      final payload = {
        'customer_id':        _cliente!.id,
        'data_evento':        _fmtDate(_dataEvento!),
        'hora_inicio':        _fmtTime(_horaInicio!),
        'data_recolhimento':  _fmtDate(_dataRecolhimento!),
        'hora_recolhimento':  _fmtTime(_horaRecolhimento!),
        'endereco': {
          'logradouro':  _logradouro.text.trim(),
          'numero':      _numero.text.trim(),
          'complemento': _complemento.text.trim().isEmpty ? null : _complemento.text.trim(),
          'bairro':      _bairro.text.trim(),
          'cidade':      _cidade.text.trim(),
          'estado':      _estado.text.trim().toUpperCase(),
          'cep':         _cep.text.replaceAll(RegExp(r'\D'), ''),
        },
        'observacoes': _obs.text.trim().isEmpty ? null : _obs.text.trim(),
        'itens': _itens.map((i) => {
          'tipo':            i.tipo == TipoLinha.combo ? 'combo' : 'item',
          'style_volume_id': i.tipo != TipoLinha.combo ? i.styleVolumeId : null,
          'combo_id':        i.tipo == TipoLinha.combo ? i.comboId : null,
          'quantidade':      i.quantidade,
          'preco_unitario':  i.precoUnitario,
          'consignado':      i.tipo == TipoLinha.consignado,
        }).toList(),
        'taxa_instalacao': _taxa,
        'desconto':        _desconto,
        'total_manual':    _totalManual ? total : null,
        'status':          _status,
      };

      await ref.read(pedidoServiceProvider).criar(payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pedido criado! E-mail enviado ao cliente.'),
          backgroundColor: AppColors.success,
        ));
        context.pop();
      }
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
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Pedido')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _secao('A — Cliente', _secaoCliente()),
            _secao('B — Evento', _secaoEvento()),
            _secao('C — Itens', _secaoItens()),
            _secao('D — Valores', _secaoValores()),
            _secao('E — Status', _secaoStatus()),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentText))
                    : const Text('Salvar pedido'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _secao(String titulo, Widget conteudo) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 8),
        child: Text(titulo, style: const TextStyle(
          color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 13,
        )),
      ),
      conteudo,
      const Divider(height: 32),
    ],
  );

  // ── Seção A ────────────────────────────────────────────────────────────────

  Widget _secaoCliente() => ClienteSearchField(
    onClienteSelected: (c) => setState(() => _cliente = c),
    initialCliente: _cliente,
  );

  // ── Seção B ────────────────────────────────────────────────────────────────

  Widget _secaoEvento() => Column(
    children: [
      Row(children: [
        Expanded(child: _dateTile('Data do evento', _dataEvento,
            (d) => setState(() => _dataEvento = d))),
        const SizedBox(width: 12),
        Expanded(child: _timeTile('Hora início', _horaInicio,
            (t) => setState(() => _horaInicio = t))),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _dateTile('Data recolhimento', _dataRecolhimento,
            (d) => setState(() => _dataRecolhimento = d))),
        const SizedBox(width: 12),
        Expanded(child: _timeTile('Hora recolh.', _horaRecolhimento,
            (t) => setState(() => _horaRecolhimento = t))),
      ]),
      const SizedBox(height: 16),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _tf(_logradouro, 'Logradouro', required: true)),
          const SizedBox(width: 12),
          SizedBox(width: 100, child: _tf(_numero, 'Número', required: true)),
        ],
      ),
      Row(children: [
        Expanded(child: _tf(_complemento, 'Complemento')),
        const SizedBox(width: 12),
        Expanded(child: _tf(_bairro, 'Bairro', required: true)),
      ]),
      Row(children: [
        Expanded(flex: 3, child: _tf(_cidade, 'Cidade', required: true)),
        const SizedBox(width: 12),
        SizedBox(width: 64, child: _tf(_estado, 'UF', maxLen: 2, required: true)),
        const SizedBox(width: 12),
        Expanded(child: _tf(_cep, 'CEP', digits: true, maxLen: 8, required: true)),
      ]),
      if (_cliente != null)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.copy_all, color: AppColors.accent, size: 16),
            label: const Text('Usar endereço do cliente',
                style: TextStyle(color: AppColors.accent, fontSize: 12)),
            onPressed: _usarEnderecoCliente,
          ),
        ),
      _tf(_obs, 'Observações', maxLines: 3, maxLen: 2000),
    ],
  );

  Widget _dateTile(String label, DateTime? value, void Function(DateTime) onPick) =>
      InkWell(
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
          );
          if (d != null) onPick(d);
        },
        child: InputDecorator(
          decoration: InputDecoration(labelText: label),
          child: Text(
            value != null ? '${value.day.toString().padLeft(2,'0')}/${value.month.toString().padLeft(2,'0')}/${value.year}' : '—',
            style: TextStyle(color: value != null ? AppColors.textPrimary : AppColors.textMuted),
          ),
        ),
      );

  Widget _timeTile(String label, TimeOfDay? value, void Function(TimeOfDay) onPick) =>
      InkWell(
        onTap: () async {
          final t = await showTimePicker(
            context: context, initialTime: value ?? TimeOfDay.now());
          if (t != null) onPick(t);
        },
        child: InputDecorator(
          decoration: InputDecoration(labelText: label),
          child: Text(
            value != null ? '${value.hour.toString().padLeft(2,'0')}:${value.minute.toString().padLeft(2,'0')}' : '—',
            style: TextStyle(color: value != null ? AppColors.textPrimary : AppColors.textMuted),
          ),
        ),
      );

  // ── Seção C ────────────────────────────────────────────────────────────────

  Widget _secaoItens() {
    final catalogoAsync = ref.watch(catalogoProvider);
    return catalogoAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Erro ao carregar catálogo: $e',
          style: const TextStyle(color: AppColors.danger)),
      data: (catalogo) => Column(
        children: [
          ..._itens.asMap().entries.map((e) =>
              _LinhaItemWidget(
                key: ValueKey(e.key),
                linha: e.value,
                catalogo: catalogo,
                onRemove: _itens.length > 1 ? () => setState(() => _itens.removeAt(e.key)) : null,
                onChanged: () => setState(_recalcTotal),
              )),
          TextButton.icon(
            icon: const Icon(Icons.add, color: AppColors.accent),
            label: const Text('Adicionar item', style: TextStyle(color: AppColors.accent)),
            onPressed: () => setState(() { _itens.add(_LinhaItem()); _recalcTotal(); }),
          ),
        ],
      ),
    );
  }

  // ── Seção D ────────────────────────────────────────────────────────────────

  Widget _secaoValores() => Column(
    children: [
      _valorRow('Subtotal', 'R\$ ${_subtotal.toStringAsFixed(2).replaceAll('.', ',')}',
          readonly: true),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _tf(_taxaCtrl, 'Taxa instalação',
            digits: false, onChanged: (_) => setState(_recalcTotal))),
        const SizedBox(width: 12),
        Expanded(child: _tf(_descontoCtrl, 'Desconto',
            digits: false, onChanged: (_) => setState(_recalcTotal))),
      ]),
      const SizedBox(height: 12),
      TextFormField(
        controller: _totalCtrl,
        decoration: InputDecoration(
          labelText: 'Total',
          suffixIcon: _totalManual
              ? Tooltip(
                  message: 'Total alterado manualmente',
                  child: const Icon(Icons.warning_amber, color: AppColors.warning),
                )
              : null,
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (v) => setState(() => _totalManual = v.isNotEmpty),
        onTap: () => setState(() => _totalManual = true),
      ),
      if (_totalManual)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => setState(() {
              _totalManual = false;
              _recalcTotal();
            }),
            child: const Text('Recalcular automaticamente',
                style: TextStyle(color: AppColors.accent, fontSize: 12)),
          ),
        ),
    ],
  );

  Widget _valorRow(String label, String valor, {bool readonly = false}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: AppColors.textSecondary)),
      Text(valor, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
    ],
  );

  // ── Seção E ────────────────────────────────────────────────────────────────

  Widget _secaoStatus() => RadioGroup<String>(
    groupValue: _status,
    onChanged: (v) => setState(() => _status = v!),
    child: Row(
      children: [
        for (final s in ['pendente', 'confirmado'])
          Expanded(
            child: RadioListTile<String>(
              value: s,
              title: Text(s[0].toUpperCase() + s.substring(1),
                  style: const TextStyle(color: AppColors.textPrimary)),
              activeColor: AppColors.accent,
            ),
          ),
      ],
    ),
  );

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _tf(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    bool digits = false,
    int? maxLen,
    int maxLines = 1,
    void Function(String)? onChanged,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          maxLength: maxLen,
          decoration: InputDecoration(labelText: label, counterText: ''),
          inputFormatters: digits ? [FilteringTextInputFormatter.digitsOnly] : null,
          onChanged: onChanged,
          validator: required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null
              : null,
        ),
      );

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}:00';
}

// ── Widget de linha de item ────────────────────────────────────────────────────

class _LinhaItemWidget extends ConsumerStatefulWidget {
  const _LinhaItemWidget({
    super.key,
    required this.linha,
    required this.catalogo,
    required this.onChanged,
    this.onRemove,
  });

  final _LinhaItem linha;
  final CatalogoData catalogo;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  ConsumerState<_LinhaItemWidget> createState() => _LinhaItemWidgetState();
}

class _LinhaItemWidgetState extends ConsumerState<_LinhaItemWidget> {
  final _precoCtrl = TextEditingController();
  final _qtdCtrl   = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _precoCtrl.text = widget.linha.precoUnitario.toStringAsFixed(2).replaceAll('.', ',');
    _qtdCtrl.text   = widget.linha.quantidade.toString();
  }

  @override
  void dispose() {
    _precoCtrl.dispose();
    _qtdCtrl.dispose();
    super.dispose();
  }

  List<StyleVolume> get _volumesDisponiveis {
    final estilos = widget.catalogo.estilos;
    return [for (final e in estilos) ...e.volumes];
  }

  @override
  Widget build(BuildContext context) {
    final linha = widget.linha;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SegmentedButton<TipoLinha>(
                  segments: const [
                    ButtonSegment(value: TipoLinha.item,       label: Text('Item')),
                    ButtonSegment(value: TipoLinha.combo,      label: Text('Combo')),
                    ButtonSegment(value: TipoLinha.consignado, label: Text('Consig.')),
                  ],
                  selected: {linha.tipo},
                  onSelectionChanged: (s) {
                    setState(() {
                      linha.tipo           = s.first;
                      linha.styleVolumeId  = null;
                      linha.comboId        = null;
                    });
                    widget.onChanged();
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) =>
                        states.contains(WidgetState.selected)
                            ? AppColors.accent
                            : AppColors.bgSecondary),
                    foregroundColor: WidgetStateProperty.resolveWith((states) =>
                        states.contains(WidgetState.selected)
                            ? AppColors.accentText
                            : AppColors.textSecondary),
                  ),
                ),
              ),
              if (widget.onRemove != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                  onPressed: widget.onRemove,
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (linha.tipo == TipoLinha.combo)
            DropdownButtonFormField<int>(
              initialValue: linha.comboId,
              decoration: const InputDecoration(labelText: 'Combo'),
              dropdownColor: AppColors.bgSecondary,
              items: widget.catalogo.combos.map((c) => DropdownMenuItem(
                value: c.id,
                child: Text(c.nome, style: const TextStyle(color: AppColors.textPrimary)),
              )).toList(),
              onChanged: (v) {
                setState(() => linha.comboId = v);
                widget.onChanged();
              },
            )
          else
            DropdownButtonFormField<int>(
              initialValue: linha.styleVolumeId,
              decoration: const InputDecoration(labelText: 'Estilo / Volume'),
              dropdownColor: AppColors.bgSecondary,
              items: _volumesDisponiveis.map((sv) {
                final estilo = widget.catalogo.estilos
                    .firstWhere((e) => e.volumes.any((v) => v.id == sv.id));
                return DropdownMenuItem(
                  value: sv.id,
                  child: Text('${estilo.nome} ${sv.volumeLitros}L',
                      style: const TextStyle(color: AppColors.textPrimary)),
                );
              }).toList(),
              onChanged: (v) {
                setState(() => linha.styleVolumeId = v);
                widget.onChanged();
              },
            ),
          const SizedBox(height: 8),
          Row(children: [
            SizedBox(
              width: 80,
              child: TextFormField(
                controller: _qtdCtrl,
                decoration: const InputDecoration(labelText: 'Qtd', counterText: ''),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 3,
                onChanged: (v) {
                  linha.quantidade = int.tryParse(v) ?? 1;
                  widget.onChanged();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _precoCtrl,
                decoration: const InputDecoration(labelText: 'Preço unit.'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) {
                  linha.precoUnitario = double.tryParse(v.replaceAll(',', '.')) ?? 0;
                  widget.onChanged();
                },
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'R\$ ${linha.subtotal.toStringAsFixed(2).replaceAll('.', ',')}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ]),
        ],
      ),
    );
  }
}
