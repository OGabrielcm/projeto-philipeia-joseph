class PedidoItem {
  const PedidoItem({
    required this.id,
    required this.tipo,
    this.styleVolumeId,
    this.comboId,
    required this.quantidade,
    required this.precoUnitario,
    required this.consignado,
    required this.posicao,
    required this.descricao,
  });

  final int id;
  final String tipo;
  final int? styleVolumeId;
  final int? comboId;
  final int quantidade;
  final double precoUnitario;
  final bool consignado;
  final int posicao;
  final String descricao;

  double get subtotal => quantidade * precoUnitario;

  factory PedidoItem.fromJson(Map<String, dynamic> j) => PedidoItem(
        id:             j['id'] as int,
        tipo:           j['tipo'] as String,
        styleVolumeId:  j['style_volume_id'] as int?,
        comboId:        j['combo_id'] as int?,
        quantidade:     j['quantidade'] as int,
        precoUnitario:  (j['preco_unitario'] as num).toDouble(),
        consignado:     j['consignado'] as bool? ?? false,
        posicao:        j['posicao'] as int,
        descricao:      j['descricao'] as String,
      );
}

class PedidoResumo {
  const PedidoResumo({
    required this.id,
    required this.numero,
    required this.status,
    required this.dataEvento,
    required this.total,
    required this.customerNome,
    required this.customerCpf,
    required this.createdAt,
  });

  final int id;
  final String numero;
  final String status;
  final String dataEvento;
  final double total;
  final String customerNome;
  final String customerCpf;
  final String createdAt;

  factory PedidoResumo.fromJson(Map<String, dynamic> j) => PedidoResumo(
        id:           j['id'] as int,
        numero:       j['numero'] as String,
        status:       j['status'] as String,
        dataEvento:   j['data_evento'] as String,
        total:        (j['total'] as num).toDouble(),
        customerNome: j['customer_nome'] as String,
        customerCpf:  j['customer_cpf'] as String,
        createdAt:    j['created_at'] as String,
      );
}

class Pedido {
  const Pedido({
    required this.id,
    required this.numero,
    required this.status,
    required this.dataEvento,
    required this.horaInicio,
    required this.dataRecolhimento,
    required this.horaRecolhimento,
    required this.enderecoLogradouro,
    required this.enderecoNumero,
    this.enderecoComplemento,
    required this.enderecoBairro,
    required this.enderecoCidade,
    required this.enderecoEstado,
    required this.enderecoCep,
    this.observacoes,
    required this.subtotal,
    required this.taxaInstalacao,
    required this.desconto,
    required this.total,
    required this.totalOverridden,
    this.cancelledAt,
    this.cancelledReason,
    required this.customerId,
    required this.customerNome,
    required this.customerCpf,
    required this.customerTelefone,
    this.customerEmail,
    required this.itens,
  });

  final int id;
  final String numero;
  final String status;
  final String dataEvento;
  final String horaInicio;
  final String dataRecolhimento;
  final String horaRecolhimento;
  final String enderecoLogradouro;
  final String enderecoNumero;
  final String? enderecoComplemento;
  final String enderecoBairro;
  final String enderecoCidade;
  final String enderecoEstado;
  final String enderecoCep;
  final String? observacoes;
  final double subtotal;
  final double taxaInstalacao;
  final double desconto;
  final double total;
  final bool totalOverridden;
  final String? cancelledAt;
  final String? cancelledReason;
  final int customerId;
  final String customerNome;
  final String customerCpf;
  final String customerTelefone;
  final String? customerEmail;
  final List<PedidoItem> itens;

  factory Pedido.fromJson(Map<String, dynamic> j) => Pedido(
        id:                  j['id'] as int,
        numero:              j['numero'] as String,
        status:              j['status'] as String,
        dataEvento:          j['data_evento'] as String,
        horaInicio:          j['hora_inicio'] as String,
        dataRecolhimento:    j['data_recolhimento'] as String,
        horaRecolhimento:    j['hora_recolhimento'] as String,
        enderecoLogradouro:  j['endereco_logradouro'] as String,
        enderecoNumero:      j['endereco_numero'] as String,
        enderecoComplemento: j['endereco_complemento'] as String?,
        enderecoBairro:      j['endereco_bairro'] as String,
        enderecoCidade:      j['endereco_cidade'] as String,
        enderecoEstado:      j['endereco_estado'] as String,
        enderecoCep:         j['endereco_cep'] as String,
        observacoes:         j['observacoes'] as String?,
        subtotal:            (j['subtotal'] as num).toDouble(),
        taxaInstalacao:      (j['taxa_instalacao'] as num).toDouble(),
        desconto:            (j['desconto'] as num).toDouble(),
        total:               (j['total'] as num).toDouble(),
        totalOverridden:     j['total_overridden'] as bool? ?? false,
        cancelledAt:         j['cancelled_at'] as String?,
        cancelledReason:     j['cancelled_reason'] as String?,
        customerId:          j['customer_id'] as int,
        customerNome:        j['customer_nome'] as String,
        customerCpf:         j['customer_cpf'] as String,
        customerTelefone:    j['customer_telefone'] as String,
        customerEmail:       j['customer_email'] as String?,
        itens:               (j['itens'] as List? ?? [])
            .map((e) => PedidoItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
