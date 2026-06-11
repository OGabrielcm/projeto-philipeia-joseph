import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../clientes/clientes_view.dart';
import '../pedidos/pedidos_list_view.dart';
import '../pedidos/novo_pedido_view.dart';
import '../historico/historico_view.dart';
import '../produtos/produtos_view.dart';
import '../login/login_view.dart';
import '../perfil/perfil_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _indiceAtual = 0;
  int _refreshPedidos   = 0;
  int _refreshClientes  = 0;
  int _refreshHistorico = 0;
  int _refreshProdutos  = 0;

  final List<String> _titulos = ['Pedidos', 'Clientes', 'Histórico', 'Produtos'];

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginView()),
        (_) => false,
      );
    }
  }

  Future<void> _abrirNovoPedido() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NovoPedidoView()),
    );
    setState(() => _refreshPedidos++);
  }

  void _onNavTap(int i) {
    setState(() {
      _indiceAtual = i;
      if (i == 0) _refreshPedidos++;
      if (i == 1) _refreshClientes++;
      if (i == 2) _refreshHistorico++;
      if (i == 3) _refreshProdutos++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titulos[_indiceAtual]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: _logout,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF16181B)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.sports_bar, color: Color(0xFFFFD300), size: 40),
                  SizedBox(height: 8),
                  Text(
                    'Philipeia',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Gestão de Pedidos',
                    style: TextStyle(color: Color(0xFF7A7E85), fontSize: 13),
                  ),
                ],
              ),
            ),
            _itemMenu(Icons.list_alt,    'Pedidos',   0),
            _itemMenu(Icons.people,      'Clientes',  1),
            _itemMenu(Icons.history,     'Histórico', 2),
            _itemMenu(Icons.local_drink, 'Produtos',  3),
            const Divider(color: Color(0xFF3A3D42)),
            ListTile(
              leading: const Icon(Icons.manage_accounts, color: Color(0xFFB5B9C0)),
              title: const Text('Meu Cadastro', style: TextStyle(color: Color(0xFFB5B9C0))),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PerfilView()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFF85149)),
              title: const Text('Sair', style: TextStyle(color: Color(0xFFF85149))),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _indiceAtual,
        children: [
          PedidosListView(refreshKey: _refreshPedidos),
          ClientesView(refreshKey:   _refreshClientes),
          HistoricoView(refreshKey:  _refreshHistorico),
          ProdutosView(refreshKey:   _refreshProdutos),
        ],
      ),
      floatingActionButton: _indiceAtual == 0
          ? FloatingActionButton.extended(
              onPressed: _abrirNovoPedido,
              icon: const Icon(Icons.add),
              label: const Text('Novo Pedido'),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceAtual,
        onTap: _onNavTap,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt),    label: 'Pedidos'),
          BottomNavigationBarItem(icon: Icon(Icons.people),      label: 'Clientes'),
          BottomNavigationBarItem(icon: Icon(Icons.history),     label: 'Histórico'),
          BottomNavigationBarItem(icon: Icon(Icons.local_drink), label: 'Produtos'),
        ],
      ),
    );
  }

  Widget _itemMenu(IconData icon, String label, int indice) {
    final selecionado = _indiceAtual == indice;
    return ListTile(
      leading: Icon(icon, color: selecionado ? const Color(0xFFFFD300) : const Color(0xFFB5B9C0)),
      title: Text(
        label,
        style: TextStyle(color: selecionado ? const Color(0xFFFFD300) : const Color(0xFFB5B9C0)),
      ),
      tileColor: selecionado ? const Color(0xFF16181B) : null,
      onTap: () {
        Navigator.pop(context);
        _onNavTap(indice);
      },
    );
  }
}
