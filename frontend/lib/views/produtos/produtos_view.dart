import 'package:flutter/material.dart';
import '../../services/catalogo_service.dart';

class ProdutosView extends StatefulWidget {
  const ProdutosView({super.key, this.refreshKey = 0});
  final int refreshKey;

  @override
  State<ProdutosView> createState() => _ProdutosViewState();
}

class _ProdutosViewState extends State<ProdutosView> {
  List<dynamic> _estilos = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarEstilos();
  }

  Future<void> _carregarEstilos() async {
    setState(() { _carregando = true; _erro = null; });
    try {
      final estilos = await CatalogoService.listarEstilos();
      setState(() { _estilos = estilos; _carregando = false; });
    } catch (e) {
      setState(() { _erro = e.toString(); _carregando = false; });
    }
  }

  void _msg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _abrirFormEstilo({Map<String, dynamic>? estilo}) async {
    final nomeCtrl = TextEditingController(text: estilo?['nome'] as String? ?? '');
    String categoria = estilo?['categoria'] as String? ?? 'chopp';

    // Volumes editáveis: lista de {volume_litros, preco, ctrl_litros, ctrl_preco}
    final volumes = ((estilo?['volumes'] as List<dynamic>?) ?? []).map((v) {
      return {
        'litros': v['volume_litros'].toString(),
        'preco': (v['preco'] as num).toStringAsFixed(2),
        'ctrl_l': TextEditingController(text: v['volume_litros'].toString()),
        'ctrl_p': TextEditingController(text: (v['preco'] as num).toStringAsFixed(2)),
      };
    }).toList();

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setLocal) {
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
                            icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFF85149), size: 20),
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
                    _carregarEstilos();
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
        });
      },
    );
    nomeCtrl.dispose();
  }

  Future<void> _confirmarExclusao(Map<String, dynamic> estilo) async {
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
        _carregarEstilos();
      } catch (e) {
        if (mounted) _msg(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

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
          ElevatedButton(onPressed: _carregarEstilos, child: const Text('Tentar novamente')),
        ]),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _carregarEstilos,
          color: const Color(0xFFFFD300),
          child: _estilos.isEmpty
              ? ListView(
                  children: const [
                    Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: Text('Nenhum estilo cadastrado',
                            style: TextStyle(color: Color(0xFF7A7E85))),
                      ),
                    ),
                  ],
                )
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
                            Row(
                              children: [
                                const Icon(Icons.local_drink,
                                    color: Color(0xFFFFD300), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    estilo['nome'] as String,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFD300).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    estilo['categoria'] as String,
                                    style: const TextStyle(
                                        color: Color(0xFFFFD300), fontSize: 11),
                                  ),
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
                                  onPressed: () => _confirmarExclusao(estilo),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...volumes.map((v) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${v['volume_litros']}L',
                                      style: const TextStyle(color: Color(0xFFB5B9C0))),
                                  Text(
                                    'R\$ ${(v['preco'] as num).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        color: Color(0xFFFFD300),
                                        fontWeight: FontWeight.bold),
                                  ),
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
            onPressed: () => _abrirFormEstilo(),
            backgroundColor: const Color(0xFFFFD300),
            foregroundColor: const Color(0xFF16181B),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
