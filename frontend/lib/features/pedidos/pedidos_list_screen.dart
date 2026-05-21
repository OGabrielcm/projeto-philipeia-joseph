import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/error_view.dart';
import 'pedido_model.dart';
import 'pedido_service.dart';

final _filtroStatusProvider = StateProvider<String?>((ref) => null);
final _filtroQProvider      = StateProvider<String>((ref) => '');
final _paginaProvider       = StateProvider<int>((ref) => 1);

final pedidosListProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  final status = ref.watch(_filtroStatusProvider);
  final q      = ref.watch(_filtroQProvider);
  final page   = ref.watch(_paginaProvider);
  return ref.watch(pedidoServiceProvider).listar(status: status, q: q, page: page);
});

class PedidosListScreen extends ConsumerWidget {
  const PedidosListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pedidosListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.accent),
            tooltip: 'Novo Pedido',
            onPressed: () => context.push('/pedidos/novo'),
          ),
        ],
      ),
      body: Column(
        children: [
          _FiltrosBar(),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:   (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () => ref.invalidate(pedidosListProvider),
              ),
              data:    (result) {
                final pedidos = result['data'] as List<PedidoResumo>;
                final total   = result['total'] as int;
                final pages   = result['pages'] as int;
                final page    = result['page']  as int;

                if (pedidos.isEmpty) {
                  return const Center(
                    child: Text('Nenhum pedido encontrado.',
                        style: TextStyle(color: AppColors.textMuted)),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: pedidos.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _PedidoCard(pedido: pedidos[i]),
                      ),
                    ),
                    if (pages > 1)
                      _Paginacao(page: page, pages: pages, total: total),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltrosBar extends ConsumerStatefulWidget {
  @override
  ConsumerState<_FiltrosBar> createState() => _FiltrosBarState();
}

class _FiltrosBarState extends ConsumerState<_FiltrosBar> {
  final _searchCtrl = TextEditingController();
  bool _expanded = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(_filtroStatusProvider);

    return Container(
      color: AppColors.bgSecondary,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Buscar por nome ou CPF...',
                      prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
                      isDense: true,
                    ),
                    onChanged: (v) {
                      ref.read(_filtroQProvider.notifier).state = v;
                      ref.read(_paginaProvider.notifier).state  = 1;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _expanded ? Icons.filter_list_off : Icons.filter_list,
                    color: status != null ? AppColors.accent : AppColors.textMuted,
                  ),
                  onPressed: () => setState(() => _expanded = !_expanded),
                ),
              ],
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  const Text('Status:', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(width: 12),
                  for (final s in [null, 'pendente', 'confirmado', 'cancelado'])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(s ?? 'Todos'),
                        selected: status == s,
                        selectedColor: AppColors.accent,
                        labelStyle: TextStyle(
                          color: status == s ? AppColors.accentText : AppColors.textSecondary,
                        ),
                        onSelected: (_) {
                          ref.read(_filtroStatusProvider.notifier).state = s;
                          ref.read(_paginaProvider.notifier).state = 1;
                        },
                      ),
                    ),
                ],
              ),
            ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

class _PedidoCard extends ConsumerWidget {
  const _PedidoCard({required this.pedido});
  final PedidoResumo pedido;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.push('/pedidos/${pedido.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(pedido.numero,
                            style: const TextStyle(
                                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        _StatusBadge(pedido.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(pedido.customerNome,
                        style: const TextStyle(color: AppColors.textSecondary)),
                    Text(
                      'Evento: ${_fmtDate(pedido.dataEvento)}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                'R\$ ${pedido.total.toStringAsFixed(2).replaceAll('.', ',')}',
                style: const TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDate(String iso) {
    if (iso.length < 10) return iso;
    final p = iso.substring(0, 10).split('-');
    return '${p[2]}/${p[1]}/${p[0]}';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);
  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'confirmado' => (AppColors.success, 'Confirmado'),
      'cancelado'  => (AppColors.danger,  'Cancelado'),
      _            => (AppColors.warning, 'Pendente'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11)),
    );
  }
}

class _Paginacao extends ConsumerWidget {
  const _Paginacao({required this.page, required this.pages, required this.total});
  final int page, pages, total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: page > 1
                ? () => ref.read(_paginaProvider.notifier).state = page - 1
                : null,
          ),
          Text('$page / $pages  ($total pedidos)',
              style: const TextStyle(color: AppColors.textSecondary)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: page < pages
                ? () => ref.read(_paginaProvider.notifier).state = page + 1
                : null,
          ),
        ],
      ),
    );
  }
}
