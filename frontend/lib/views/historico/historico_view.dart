import 'package:flutter/material.dart';
import '../../services/pedido_service.dart';

class HistoricoView extends StatefulWidget {
  const HistoricoView({super.key, this.refreshKey = 0});
  final int refreshKey;

  @override
  State<HistoricoView> createState() => _HistoricoViewState();
}

class _HistoricoViewState extends State<HistoricoView> {
  List<dynamic> _pedidos = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  @override
  void didUpdateWidget(HistoricoView old) {
    super.didUpdateWidget(old);
    if (old.refreshKey != widget.refreshKey) {
      _carregarHistorico();
    }
  }

  Future<void> _carregarHistorico() async {
    setState(() { _carregando = true; _erro = null; });
    try {
      final confirmados = await PedidoService.listar(status: 'confirmado', perPage: 100);
      final cancelados  = await PedidoService.listar(status: 'cancelado',  perPage: 100);
      final lista = [
        ...(confirmados['data'] as List),
        ...(cancelados['data']  as List),
      ];
      lista.sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
      setState(() { _pedidos = lista; _carregando = false; });
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
          ElevatedButton(onPressed: _carregarHistorico, child: const Text('Tentar novamente')),
        ]),
      );
    }
    if (_pedidos.isEmpty) {
      return const Center(
        child: Text('Nenhum pedido no histórico', style: TextStyle(color: Color(0xFF7A7E85))),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarHistorico,
      color: const Color(0xFFFFD300),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pedidos.length,
        itemBuilder: (_, i) {
          final p = _pedidos[i];
          final status = p['status'] as String;
          final isConfirmado = status == 'confirmado';
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p['customer_nome'] as String,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            Text(
                              p['numero'] as String,
                              style: const TextStyle(color: Color(0xFF7A7E85), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isConfirmado
                              ? const Color(0xFF3FB950).withOpacity(0.15)
                              : const Color(0xFFF85149).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isConfirmado ? const Color(0xFF3FB950) : const Color(0xFFF85149),
                          ),
                        ),
                        child: Text(
                          isConfirmado ? 'Confirmado' : 'Cancelado',
                          style: TextStyle(
                            color: isConfirmado ? const Color(0xFF3FB950) : const Color(0xFFF85149),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFF3A3D42), height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: Color(0xFF7A7E85)),
                      const SizedBox(width: 6),
                      Text(
                        'Evento: ${_formatarData(p['data_evento'] as String)}',
                        style: const TextStyle(color: Color(0xFFB5B9C0), fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:', style: TextStyle(color: Color(0xFF7A7E85), fontSize: 13)),
                      Text(
                        'R\$ ${(p['total'] as num).toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFFFFD300),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatarData(String iso) {
    try {
      final partes = iso.substring(0, 10).split('-');
      return '${partes[2]}/${partes[1]}/${partes[0]}';
    } catch (_) {
      return iso;
    }
  }
}
