import 'package:flutter/material.dart';
import '../../services/catalogo_service.dart';

class ProdutosView extends StatefulWidget {
  const ProdutosView({super.key, this.refreshKey = 0});
  final int refreshKey;

  @override
  State<ProdutosView> createState() => _ProdutosViewState();
}

class _ProdutosViewState extends State<ProdutosView>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  List<dynamic> _estilos = [];
  List<dynamic> _combos  = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void didUpdateWidget(ProdutosView old) {
    super.didUpdateWidget(old);
    if (old.refreshKey != widget.refreshKey) _carregar();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() { _carregando = true; _erro = null; });
    try {
      final results = await Future.wait([
        CatalogoService.listarEstilos(),
        CatalogoService.listarCombos(),
      ]);
      setState(() {
        _estilos   = results[0];
        _combos    = results[1];
        _carregando = false;
      });
    } catch (e) {
      setState(() { _erro = e.toString(); _carregando = false; });
    }
  }

  void _msg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  // ── helpers ─────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _todosVolumes {
    final result = <Map<String, dynamic>>[];
    for (final e in _estilos) {
      final vols = e['volumes'] as List<dynamic>;
      for (final v in vols) {
        result.add({
          'id':    v['id'],
          'label': '${e['nome']} ${v['volume_litros']}L — R\$ ${(v['preco'] as num).toStringAsFixed(2)}',
        });
      }
    }
    return result;
  }

  // ── Estilos CRUD ─────────────────────────────────────────────────────────

  Future<void> _abrirFormEstilo({Map<String, dynamic>? estilo}) async {
    final nomeCtrl = TextEditingController(text: estilo?['nome'] as String? ?? '');
    String categoria = estilo?['categoria'] as String? ?? 'chopp';

    final volumes = ((estilo?['volumes'] as List<dynamic>?) ?? []).map((v) {
      return {
        'ctrl_l': TextEditingController(text: v['volume_litros'].toString()),
        'ctrl_p': TextEditingController(text: (v['preco'] as num).toStringAsFixed(2)),
      };
    }).toList();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) {
        return AlertDialog(
          title: Text(estilo == null ? 'Novo Estilo' : 'Editar Estilo'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nomeCtrl,
                    decoration: const InputDecoration(labelText: 'Nome *'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: categoria,
                    decoration: const InputDecoration(labelText: 'Categoria *'),
                    items: const [
                      DropdownMenuItem(value: 'chopp', child: Text('Chopp')),
                      DropdownMenuItem(value: 'drink', child: Text('Drink')),
                    ],
                    onChanged: (v) => setLocal(() => categoria = v!),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Volumes', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Adicionar'),
                        onPressed: () => setLocal(() {
                          volumes.add({
                            'ctrl_l': TextEditingController(),
                            'ctrl_p': TextEditingController(),
                          });
                        }),
                      ),
                    ],
                  ),
                  ...volumes.asMap().entries.map((entry) {
                    final i = entry.key;
                    final v = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: v['ctrl_l'] as TextEditingController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Litros', suffixText: 'L'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: v['ctrl_p'] as TextEditingController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Preço', prefixText: 'R\$ '),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Color(0xFFF85149), size: 20),
                          onPressed: () => setLocal(() => volumes.removeAt(i)),
                        ),
                      ]),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final nome = nomeCtrl.text.trim();
                if (nome.isEmpty) { _msg('Informe o nome'); return; }
                final vols = volumes.map((v) {
                  final l = int.tryParse((v['ctrl_l'] as TextEditingController).text.trim()) ?? 0;
                  final p = double.tryParse((v['ctrl_p'] as TextEditingController).text.trim()) ?? 0;
                  return {'volume_litros': l, 'preco': p};
                }).where((v) => (v['volume_litros'] as int) > 0).toList();
                try {
                  final payload = {'nome': nome, 'categoria': categoria, 'volumes': vols};
                  if (estilo == null) {
                    await CatalogoService.criarEstilo(payload);
                  } else {
                    await CatalogoService.atualizarEstilo(estilo['id'] as int, payload);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  _carregar();
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
        );
      }),
    );
    nomeCtrl.dispose();
  }

  Future<void> _excluirEstilo(Map<String, dynamic> estilo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir Estilo'),
        content: Text('Excluir "${estilo['nome']}"? Todos os volumes serão desativados.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
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
        await CatalogoService.excluirEstilo(estilo['id'] as int);
        _carregar();
      } catch (e) {
        if (mounted) _msg(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  // ── Combos CRUD ──────────────────────────────────────────────────────────

  Future<void> _abrirFormCombo({Map<String, dynamic>? combo}) async {
    final vols = _todosVolumes;
    if (vols.isEmpty) {
      _msg('Cadastre pelo menos dois volumes de estilos antes de criar um combo');
      return;
    }

    final nomeCtrl  = TextEditingController(text: combo?['nome'] as String? ?? '');
    final precoCtrl = TextEditingController(
      text: combo != null ? (combo['preco'] as num).toStringAsFixed(2) : '',
    );
    int? sv1Id = combo?['item_1']?['style_volume_id'] as int?;
    int? sv2Id = combo?['item_2']?['style_volume_id'] as int?;

    // Guarantee selected IDs exist in current volume list
    final volIds = vols.map((v) => v['id'] as int).toSet();
    if (sv1Id != null && !volIds.contains(sv1Id)) sv1Id = null;
    if (sv2Id != null && !volIds.contains(sv2Id)) sv2Id = null;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) {
        return AlertDialog(
          title: Text(combo == null ? 'Novo Combo' : 'Editar Combo'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nomeCtrl,
                    decoration: const InputDecoration(labelText: 'Nome *'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: precoCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Preço *', prefixText: 'R\$ '),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: sv1Id,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Item 1 *'),
                    items: vols.map((v) => DropdownMenuItem<int>(
                      value: v['id'] as int,
                      child: Text(v['label'] as String,
                          overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (v) => setLocal(() => sv1Id = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: sv2Id,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Item 2 *'),
                    items: vols.map((v) => DropdownMenuItem<int>(
                      value: v['id'] as int,
                      child: Text(v['label'] as String,
                          overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (v) => setLocal(() => sv2Id = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final nome  = nomeCtrl.text.trim();
                final preco = double.tryParse(precoCtrl.text.trim());
                if (nome.isEmpty)    { _msg('Informe o nome');   return; }
                if (preco == null)   { _msg('Preço inválido');   return; }
                if (sv1Id == null)   { _msg('Selecione o Item 1'); return; }
                if (sv2Id == null)   { _msg('Selecione o Item 2'); return; }
                final payload = {
                  'nome':                nome,
                  'preco':               preco,
                  'style_volume_1_id':   sv1Id,
                  'style_volume_2_id':   sv2Id,
                };
                try {
                  if (combo == null) {
                    await CatalogoService.criarCombo(payload);
                  } else {
                    await CatalogoService.atualizarCombo(combo['id'] as int, payload);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  _carregar();
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
        );
      }),
    );
    nomeCtrl.dispose();
    precoCtrl.dispose();
  }

  Future<void> _excluirCombo(Map<String, dynamic> combo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir Combo'),
        content: Text('Excluir "${combo['nome']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
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
        await CatalogoService.excluirCombo(combo['id'] as int);
        _carregar();
      } catch (e) {
        if (mounted) _msg(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  // ── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD300)));
    }
    if (_erro != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_erro!, style: const TextStyle(color: Color(0xFFF85149))),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _carregar, child: const Text('Tentar novamente')),
        ]),
      );
    }

    return Column(
      children: [
        TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Estilos'),
            Tab(text: 'Combos'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _buildEstilos(),
              _buildCombos(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEstilos() {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _carregar,
          color: const Color(0xFFFFD300),
          child: _estilos.isEmpty
              ? ListView(children: const [
                  Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Text('Nenhum estilo cadastrado',
                          style: TextStyle(color: Color(0xFF7A7E85))),
                    ),
                  ),
                ])
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                  itemCount: _estilos.length,
                  itemBuilder: (_, i) {
                    final estilo = _estilos[i] as Map<String, dynamic>;
                    final volumes = estilo['volumes'] as List<dynamic>;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.local_drink,
                                  color: Color(0xFFFFD300), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(estilo['nome'] as String,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD300).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(estilo['categoria'] as String,
                                    style: const TextStyle(
                                        color: Color(0xFFFFD300), fontSize: 11)),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined,
                                    size: 18, color: Color(0xFF7A7E85)),
                                tooltip: 'Editar',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                onPressed: () => _abrirFormEstilo(estilo: estilo),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 18, color: Color(0xFFF85149)),
                                tooltip: 'Excluir',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                onPressed: () => _excluirEstilo(estilo),
                              ),
                            ]),
                            const SizedBox(height: 12),
                            ...volumes.map((v) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${v['volume_litros']}L',
                                      style: const TextStyle(color: Color(0xFFB5B9C0))),
                                  Text('R\$ ${(v['preco'] as num).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          color: Color(0xFFFFD300),
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            )),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            heroTag: 'fab_estilos',
            onPressed: () => _abrirFormEstilo(),
            backgroundColor: const Color(0xFFFFD300),
            foregroundColor: const Color(0xFF16181B),
            tooltip: 'Novo Estilo',
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildCombos() {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _carregar,
          color: const Color(0xFFFFD300),
          child: _combos.isEmpty
              ? ListView(children: const [
                  Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Text('Nenhum combo cadastrado',
                          style: TextStyle(color: Color(0xFF7A7E85))),
                    ),
                  ),
                ])
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                  itemCount: _combos.length,
                  itemBuilder: (_, i) {
                    final c = _combos[i] as Map<String, dynamic>;
                    final i1 = c['item_1'] as Map<String, dynamic>;
                    final i2 = c['item_2'] as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.wine_bar,
                                  color: Color(0xFFFFD300), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(c['nome'] as String,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined,
                                    size: 18, color: Color(0xFF7A7E85)),
                                tooltip: 'Editar',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                onPressed: () => _abrirFormCombo(combo: c),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 18, color: Color(0xFFF85149)),
                                tooltip: 'Excluir',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                onPressed: () => _excluirCombo(c),
                              ),
                            ]),
                            const SizedBox(height: 10),
                            _itemLinha(i1),
                            const SizedBox(height: 4),
                            _itemLinha(i2),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Text('Combo: ',
                                    style: TextStyle(color: Color(0xFF7A7E85))),
                                Text(
                                  'R\$ ${(c['preco'] as num).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      color: Color(0xFFFFD300),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            heroTag: 'fab_combos',
            onPressed: () => _abrirFormCombo(),
            backgroundColor: const Color(0xFFFFD300),
            foregroundColor: const Color(0xFF16181B),
            tooltip: 'Novo Combo',
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _itemLinha(Map<String, dynamic> item) {
    return Row(children: [
      const Icon(Icons.circle, size: 6, color: Color(0xFFB5B9C0)),
      const SizedBox(width: 8),
      Text(
        '${item['style_nome']}  ${item['volume_litros']}L',
        style: const TextStyle(color: Color(0xFFB5B9C0), fontSize: 13),
      ),
    ]);
  }
}
