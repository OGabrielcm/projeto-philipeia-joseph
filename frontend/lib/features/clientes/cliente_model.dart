class Cliente {
  const Cliente({
    required this.id,
    required this.nome,
    required this.cpf,
    required this.telefone,
    this.telefoneWhatsapp,
    this.whatsappIgualPrincipal = false,
    this.email,
    required this.enderecoLogradouro,
    required this.enderecoNumero,
    this.enderecoComplemento,
    required this.enderecoBairro,
    required this.enderecoCidade,
    required this.enderecoEstado,
    required this.enderecoCep,
  });

  final int id;
  final String nome;
  final String cpf;
  final String telefone;
  final String? telefoneWhatsapp;
  final bool whatsappIgualPrincipal;
  final String? email;
  final String enderecoLogradouro;
  final String enderecoNumero;
  final String? enderecoComplemento;
  final String enderecoBairro;
  final String enderecoCidade;
  final String enderecoEstado;
  final String enderecoCep;

  factory Cliente.fromJson(Map<String, dynamic> j) => Cliente(
        id:                      j['id'] as int,
        nome:                    j['nome'] as String,
        cpf:                     j['cpf'] as String,
        telefone:                j['telefone'] as String,
        telefoneWhatsapp:        j['telefone_whatsapp'] as String?,
        whatsappIgualPrincipal:  j['whatsapp_igual_principal'] as bool? ?? false,
        email:                   j['email'] as String?,
        enderecoLogradouro:      j['endereco_logradouro'] as String,
        enderecoNumero:          j['endereco_numero'] as String,
        enderecoComplemento:     j['endereco_complemento'] as String?,
        enderecoBairro:          j['endereco_bairro'] as String,
        enderecoCidade:          j['endereco_cidade'] as String,
        enderecoEstado:          j['endereco_estado'] as String,
        enderecoCep:             j['endereco_cep'] as String,
      );

  Map<String, dynamic> toJson() => {
        'nome':                     nome,
        'cpf':                      cpf,
        'telefone':                 telefone,
        'telefone_whatsapp':        telefoneWhatsapp,
        'whatsapp_igual_principal': whatsappIgualPrincipal,
        'email':                    email,
        'endereco_logradouro':      enderecoLogradouro,
        'endereco_numero':          enderecoNumero,
        'endereco_complemento':     enderecoComplemento,
        'endereco_bairro':          enderecoBairro,
        'endereco_cidade':          enderecoCidade,
        'endereco_estado':          enderecoEstado,
        'endereco_cep':             enderecoCep,
      };

  String get enderecoFormatado =>
      '$enderecoLogradouro, $enderecoNumero'
      '${enderecoComplemento != null ? ', $enderecoComplemento' : ''}'
      ' — $enderecoBairro, $enderecoCidade/$enderecoEstado';
}
