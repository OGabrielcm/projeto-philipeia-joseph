import 'package:flutter/material.dart';
import '../../services/pedido_service.dart';

class PedidosListView extends StatefulWidget {
  const PedidosListView({super.key, this.refreshKey = 0});
  final int refreshKey;

  @override
  State<PedidosListView> createState() => _PedidosListViewState();
}

class _PedidosListViewState extends State<PedidosListView> {
  List<dynamic> _pedidos = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarPedidos();
  }

  @override
  void didUpdateWidget(PedidosListView old) {
    super.didUpdateWidget(old);
    if (old.refreshKey != widget.refreshKey) {
      _carregarPedidos();
    }
  }

  Future<void> _carregarPedidos() async {
    setState(() { _carregando = true; _erro = null; });
    try {
      final pendentes   = await PedidoService.listar(status: 'pendente',   perPage: 100);
      final confirmados = await PedidoService.listar(status: 'confirmado', perPage: 100);
      final lista = [
        ...(pendentes['data']   as List),
        ...(confirmados['data'] as List),
      ];
      lista.sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
      setState(() { _pedidos = lista; _carregando = false; });
    } catch (e) {
      setState(() { _erro = e.toString(); _carregando = false; });
    }
  }

  Future<void> _confirmarPedido(Map<String, dynamic> pedido) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar Pedido'),
        content: Text('Deseja marcar o pedido ${pedido['numero']} como confirmado?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await PedidoService.atualizar(pedido['id'] as int, {'status': 'confirmado'});
        _carregarPedidos();
      } catch (e) {
        if (mounted) _mostrarMensagem(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> _cancelarPedido(Map<String, dynamic> pedido) async {
    final motivoCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar Pedido'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pedido: ${pedido['numero']}'),
            const SizedBox(height: 16),
            TextField(
              controller: motivoCtrl,
              decoration: const InputDecoration(labelText: 'Motivo do cancelamento *'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Voltar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF85149)),
            child: const Text('Cancelar Pedido'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final motivo = motivoCtrl.text.trim();
      if (motivo.length < 5) {
        _mostrarMensagem('Informe o motivo do cancelamento (mínimo 5 caracteres)');
        return;
      }
      try {
        await PedidoService.cancelar(pedido['id'] as int, motivo);
        _carregarPedidos();
      } catch (e) {
        if (mounted) _mostrarMensagem(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> _excluirPedido(Map<String, dynamic> pedido) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir Pedido'),
        content: Text('Deseja excluir o pedido ${pedido['numero']}? Esta ação não pode ser desfeita.'),
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
        await PedidoService.excluir(pedido['id'] as int);
        _carregarPedidos();
      } catch (e) {
        if (mounted) _mostrarMensagem(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  void _mostrarMensagem(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _verDetalhesPedido(Map<String, dynamic> resumo) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF2A2D31),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _DetalhePedidoSheet(id: resumo['id'] as int),
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
          ElevatedButton(onPressed: _carregarPedidos, child: const Text('Tentar novamente')),
        ]),
      );
    }
    if (_pedidos.isEmpty) {
      return const Center(
        child: Text('Nenhum pedido ativo', style: TextStyle(color: Color(0xFF7A7E85))),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarPedidos,
      color: const Color(0xFFFFD300),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: _pedidos.length,
        itemBuilder: (_, i) {
          final p = _pedidos[i] as Map<String, dynamic>;
          final status      = p['status'] as String;
          final isPendente  = status == 'pendente';
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _verDetalhesPedido(p),
              child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          color: isPendente
                              ? const Color(0xFFD29922).withOpacity(0.15)
                              : const Color(0xFF3FB950).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isPendente ? const Color(0xFFD29922) : const Color(0xFF3FB950),
                          ),
                        ),
                        child: Text(
                          isPendente ? 'Pendente' : 'Confirmado',
                          style: TextStyle(
                            color: isPendente ? const Color(0xFFD29922) : const Color(0xFF3FB950),
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
                      const Icon(Icons.event, size: 14, color: Color(0xFF7A7E85)),
                      const SizedBox(width: 6),
                      Text(
                        'Evento: ${_formatarData(p['data_evento'] as String)}',
                        style: const TextStyle(color: Color(0xFFB5B9C0), fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF3FB950)),
                          label: const Text('Confirmar', style: TextStyle(color: Color(0xFF3FB950), fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF3FB950)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          onPressed: isPendente ? () => _confirmarPedido(p) : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.cancel_outlined, size: 16, color: Color(0xFFD29922)),
                          label: const Text('Cancelar', style: TextStyle(color: Color(0xFFD29922), fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFD29922)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          onPressed: () => _cancelarPedido(p),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFF85149)),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        ),
                        onPressed: () => _excluirPedido(p),
                        child: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFF85149)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          );
        },
      ),
    );
  }
}

class _DetalhePedidoSheet extends StatefulWidget {
  const _DetalhePedidoSheet({required this.id});
  final int id;

  @override
  State<_DetalhePedidoSheet> createState() => _DetalhePedidoSheetState();
}

class _DetalhePedidoSheetState extends State<_DetalhePedidoSheet> {
  Map<String, dynamic>? _pedido;
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final p = await PedidoService.buscarPorId(widget.id);
      if (mounted) setState(() { _pedido = p; _carregando = false; });
    } catch (e) {
      if (mounted) setState(() { _erro = e.toString(); _carregando = false; });
    }
  }

  String _fmtData(String iso) {
    try {
      final p = iso.substring(0, 10).split('-');
      return '${p[2]}/${p[1]}/${p[0]}';
    } catch (_) { return iso; }
  }

  String _fmtHora(String t) => t.length >= 5 ? t.substring(0, 5) : t;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (_, ctrl) {
        if (_carregando) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(color: Color(0xFFFFD300)),
          ));
        }
        if (_erro != null || _pedido == null) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(_erro ?? 'Erro ao carregar', style: const TextStyle(color: Color(0xFFF85149))),
          ));
        }
        final p = _pedido!;
        final itens = p['itens'] as List<dynamic>? ?? [];
        final endereco = [
          p['endereco_logradouro'], p['endereco_numero'],
          if ((p['endereco_complemento'] as String?) != null && p['endereco_complemento'].isNotEmpty)
            p['endereco_complemento'],
          p['endereco_bairro'], p['endereco_cidade'],
          p['endereco_estado'],
        ].join(', ');

        return ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFF3A3D42), borderRadius: BorderRadius.circular(2)),
            )),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(p['numero'] as String,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              _badge(p['status'] as String),
            ]),
            const SizedBox(height: 4),
            Text(p['customer_nome'] as String,
                style: const TextStyle(color: Color(0xFFB5B9C0), fontSize: 14)),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFF3A3D42)),
            _linha('Evento', '${_fmtData(p['data_evento'] as String)}  ${_fmtHora(p['hora_inicio'] as String)}'),
            _linha('Recolhimento', '${_fmtData(p['data_recolhimento'] as String)}  ${_fmtHora(p['hora_recolhimento'] as String)}'),
            _linha('Endereço', endereco),
            if ((p['observacoes'] as String?) != null && (p['observacoes'] as String).isNotEmpty)
              _linha('Observações', p['observacoes'] as String),
            const Divider(color: Color(0xFF3A3D42)),
            const Text('Itens', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFD300))),
            const SizedBox(height: 8),
            ...itens.map((item) {
              final it = item as Map<String, dynamic>;
              final subtotal = (it['quantidade'] as int) * (it['preco_unitario'] as num).toDouble();
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  Expanded(child: Text(
                    '${it['quantidade']}x  ${it['descricao']}',
                    style: const TextStyle(color: Color(0xFFB5B9C0), fontSize: 13),
                  )),
                  Text(
                    'R\$ ${subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ]),
              );
            }),
            const Divider(color: Color(0xFF3A3D42)),
            _valorLinha('Subtotal', p['subtotal'] as num),
            _valorLinha('Taxa de instalação', p['taxa_instalacao'] as num),
            if ((p['desconto'] as num) > 0) _valorLinha('Desconto', p['desconto'] as num),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
              Text(
                'R\$ ${(p['total'] as num).toStringAsFixed(2)}',
                style: const TextStyle(color: Color(0xFFFFD300), fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ]),
          ],
        );
      },
    );
  }

  Widget _badge(String status) {
    final isPendente = status == 'pendente';
    final cor = isPendente ? const Color(0xFFD29922) : const Color(0xFF3FB950);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cor),
      ),
      child: Text(isPendente ? 'Pendente' : 'Confirmado',
          style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _linha(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Color(0xFF7A7E85), fontSize: 13))),
        Expanded(child: Text(valor, style: const TextStyle(color: Color(0xFFB5B9C0), fontSize: 13))),
      ]),
    );
  }

  Widget _valorLinha(String label, num valor) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Color(0xFF7A7E85), fontSize: 13)),
      Text('R\$ ${valor.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFB5B9C0), fontSize: 13)),
    ]);
  }
}
