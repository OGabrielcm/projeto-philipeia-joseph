import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/dio_client.dart' show dioMessage;
import '../../core/theme/app_colors.dart';
import '../../core/widgets/error_view.dart';
import 'pedido_model.dart';
import 'pedido_service.dart';

final _pedidoDetalheProvider =
    FutureProvider.autoDispose.family<Pedido, int>((ref, id) {
  return ref.watch(pedidoServiceProvider).buscarPorId(id);
});

class DetalhesPedidoScreen extends ConsumerWidget {
  const DetalhesPedidoScreen({super.key, required this.pedidoId});
  final int pedidoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_pedidoDetalheProvider(pedidoId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do Pedido')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(_pedidoDetalheProvider(pedidoId)),
        ),
        data: (pedido) => _DetalheBody(
          pedido: pedido,
          onCancelado: () => ref.invalidate(_pedidoDetalheProvider(pedidoId)),
        ),
      ),
    );
  }
}

class _DetalheBody extends ConsumerWidget {
  const _DetalheBody({required this.pedido, required this.onCancelado});
  final Pedido pedido;
  final VoidCallback onCancelado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _header(context),
        const SizedBox(height: 20),
        _secao('Cliente', _secaoCliente()),
        _secao('Evento', _secaoEvento()),
        _secao('Itens', _secaoItens()),
        _secao('Valores', _secaoValores()),
        if (pedido.observacoes != null && pedido.observacoes!.isNotEmpty)
          _secao('Observações', Text(pedido.observacoes!,
              style: const TextStyle(color: AppColors.textSecondary))),
        if (pedido.cancelledReason != null) _secaoCancelamento(),
        const SizedBox(height: 24),
        if (pedido.status != 'cancelado')
          _BotaoCancelar(pedido: pedido, onCancelado: onCancelado),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _header(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(pedido.numero,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge!
                    .copyWith(fontSize: 22)),
          ),
          _StatusBadge(pedido.status),
        ],
      );

  Widget _secao(String titulo, Widget conteudo) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10, top: 4),
            child: Text(titulo,
                style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
          conteudo,
          const Divider(height: 28),
        ],
      );

  Widget _secaoCliente() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _info('Nome', pedido.customerNome),
          _info('CPF', _fmtCpf(pedido.customerCpf)),
          _info('Telefone', pedido.customerTelefone),
          if (pedido.customerEmail != null) _info('E-mail', pedido.customerEmail!),
        ],
      );

  Widget _secaoEvento() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _info('Data do evento', _fmtDate(pedido.dataEvento)),
          _info('Hora início', pedido.horaInicio.substring(0, 5)),
          _info('Recolhimento', '${_fmtDate(pedido.dataRecolhimento)} às ${pedido.horaRecolhimento.substring(0, 5)}'),
          const SizedBox(height: 6),
          _info('Endereço',
              '${pedido.enderecoLogradouro}, ${pedido.enderecoNumero}'
              '${pedido.enderecoComplemento != null ? ', ${pedido.enderecoComplemento}' : ''}'
              '\n${pedido.enderecoBairro}, ${pedido.enderecoCidade}/${pedido.enderecoEstado}'
              '\nCEP: ${pedido.enderecoCep}'),
        ],
      );

  Widget _secaoItens() => Column(
        children: [
          ...pedido.itens.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    if (item.consignado)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(Icons.lock_outline,
                            size: 14, color: AppColors.warning),
                      ),
                    Expanded(
                      child: Text(
                        '${item.quantidade}x ${item.descricao}',
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    ),
                    Text(
                      'R\$ ${item.subtotal.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              )),
        ],
      );

  Widget _secaoValores() => Column(
        children: [
          _valorRow('Subtotal', pedido.subtotal),
          _valorRow('Taxa de instalação', pedido.taxaInstalacao),
          _valorRow('Desconto', -pedido.desconto),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                const Text('Total',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold)),
                if (pedido.totalOverridden)
                  const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Tooltip(
                      message: 'Total alterado manualmente',
                      child: Icon(Icons.warning_amber,
                          size: 14, color: AppColors.warning),
                    ),
                  ),
              ]),
              Text(
                'R\$ ${pedido.total.toStringAsFixed(2).replaceAll('.', ',')}',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ],
          ),
        ],
      );

  Widget _secaoCancelamento() => _secao(
        'Cancelamento',
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (pedido.cancelledAt != null)
            _info('Data', _fmtDate(pedido.cancelledAt!.substring(0, 10))),
          _info('Motivo', pedido.cancelledReason ?? ''),
        ]),
      );

  Widget _info(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(label,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ),
      );

  Widget _valorRow(String label, double value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary)),
            Text(
              'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );

  String _fmtDate(String iso) {
    if (iso.length < 10) return iso;
    final p = iso.substring(0, 10).split('-');
    return '${p[2]}/${p[1]}/${p[0]}';
  }

  String _fmtCpf(String cpf) {
    if (cpf.length != 11) return cpf;
    return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.${cpf.substring(6, 9)}-${cpf.substring(9)}';
  }
}

// ── Badge de status ────────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }
}

// ── Botão cancelar ─────────────────────────────────────────────────────────────

class _BotaoCancelar extends ConsumerStatefulWidget {
  const _BotaoCancelar({required this.pedido, required this.onCancelado});
  final Pedido pedido;
  final VoidCallback onCancelado;

  @override
  ConsumerState<_BotaoCancelar> createState() => _BotaoCancelarState();
}

class _BotaoCancelarState extends ConsumerState<_BotaoCancelar> {
  Future<void> _confirmar() async {
    final motivoCtrl = TextEditingController();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        title: const Text('Cancelar pedido',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Informe o motivo do cancelamento:',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: motivoCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Motivo obrigatório...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Voltar',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger,
                foregroundColor: Colors.white),
            onPressed: () {
              if (motivoCtrl.text.trim().length < 5) return;
              Navigator.of(ctx).pop(true);
            },
            child: const Text('Confirmar cancelamento'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    try {
      await ref
          .read(pedidoServiceProvider)
          .cancelar(widget.pedido.id, motivoCtrl.text.trim());
      widget.onCancelado();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pedido cancelado.'),
          backgroundColor: AppColors.danger,
        ));
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.danger,
        side: const BorderSide(color: AppColors.danger),
      ),
      onPressed: _confirmar,
      child: const Text('Cancelar pedido'),
    );
  }
}
