import 'package:flutter/material.dart';
import '../../services/catalogo_service.dart';

class ProdutosView extends StatefulWidget {
  const ProdutosView({super.key, this.refreshKey = 0});
  final int refreshKey;

  @override
  State<ProdutosView> createState() => _ProdutosViewState();
}

class _ProdutosViewState extends State<ProdutosView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _estilos = [];
  List<dynamic> _combos  = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _carregarCatalogo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregarCatalogo() async {
    setState(() { _carregando = true; _erro = null; });
    try {
      final estilos = await CatalogoService.listarEstilos();
      final combos  = await CatalogoService.listarCombos();
      setState(() { _estilos = estilos; _combos = combos; _carregando = false; });
    } catch (e) {
      setState(() { _erro = e.toString(); _carregando = false; });
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
          ElevatedButton(onPressed: _carregarCatalogo, child: const Text('Tentar novamente')),
        ]),
      );
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFD300),
          labelColor: const Color(0xFFFFD300),
          unselectedLabelColor: const Color(0xFF7A7E85),
          tabs: const [
            Tab(text: 'Estilos de Chopp'),
            Tab(text: 'Combos'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
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
    if (_estilos.isEmpty) {
      return const Center(child: Text('Nenhum estilo cadastrado', style: TextStyle(color: Color(0xFF7A7E85))));
    }
    return RefreshIndicator(
      onRefresh: _carregarCatalogo,
      color: const Color(0xFFFFD300),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _estilos.length,
        itemBuilder: (_, i) {
          final estilo = _estilos[i];
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
                      const Icon(Icons.local_drink, color: Color(0xFFFFD300), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        estilo['nome'] as String,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD300).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          estilo['categoria'] as String,
                          style: const TextStyle(color: Color(0xFFFFD300), fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...volumes.map((v) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${v['volume_litros']}L',
                          style: const TextStyle(color: Color(0xFFB5B9C0)),
                        ),
                        Text(
                          'R\$ ${(v['preco'] as num).toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFFFFD300),
                            fontWeight: FontWeight.bold,
                          ),
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
    );
  }

  Widget _buildCombos() {
    if (_combos.isEmpty) {
      return const Center(child: Text('Nenhum combo cadastrado', style: TextStyle(color: Color(0xFF7A7E85))));
    }
    return RefreshIndicator(
      onRefresh: _carregarCatalogo,
      color: const Color(0xFFFFD300),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _combos.length,
        itemBuilder: (_, i) {
          final combo = _combos[i];
          final item1 = combo['item_1'] as Map<String, dynamic>;
          final item2 = combo['item_2'] as Map<String, dynamic>;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        combo['nome'] as String,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        'R\$ ${(combo['preco'] as num).toStringAsFixed(2)}',
                        style: const TextStyle(color: Color(0xFFFFD300), fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: Color(0xFF3A3D42), height: 1),
                  const SizedBox(height: 8),
                  Text(
                    '• ${item1['style_nome']} ${item1['volume_litros']}L',
                    style: const TextStyle(color: Color(0xFFB5B9C0), fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• ${item2['style_nome']} ${item2['volume_litros']}L',
                    style: const TextStyle(color: Color(0xFFB5B9C0), fontSize: 13),
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
