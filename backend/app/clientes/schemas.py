from marshmallow import Schema, fields, validate, validates, ValidationError, pre_load


def _cpf_valido(cpf: str) -> bool:
    if len(cpf) != 11 or not cpf.isdigit() or cpf == cpf[0] * 11:
        return False
    for pos in range(9, 11):
        soma = sum(int(cpf[i]) * (pos + 1 - i) for i in range(pos))
        digito = (soma * 10 % 11) % 10
        if digito != int(cpf[pos]):
            return False
    return True


class ClienteSchema(Schema):
    nome                     = fields.Str(required=True, validate=validate.Length(min=2, max=120))
    cpf                      = fields.Str(required=True)
    telefone                 = fields.Str(required=True)
    telefone_whatsapp        = fields.Str(load_default=None)
    whatsapp_igual_principal = fields.Bool(load_default=False)
    email                    = fields.Email(load_default=None, allow_none=True)

    @pre_load
    def normalizar_email(self, data, **kwargs):
        # String vazia é tratada como ausente (None)
        if isinstance(data.get('email'), str) and data['email'].strip() == '':
            data['email'] = None
        return data
    endereco_logradouro      = fields.Str(required=True)
    endereco_numero          = fields.Str(required=True)
    endereco_complemento     = fields.Str(load_default=None)
    endereco_bairro          = fields.Str(required=True)
    endereco_cidade          = fields.Str(required=True)
    endereco_estado          = fields.Str(required=True, validate=validate.Length(equal=2))
    endereco_cep             = fields.Str(required=True)

    @validates('cpf')
    def validate_cpf(self, value):
        digits = ''.join(filter(str.isdigit, value))
        if not _cpf_valido(digits):
            raise ValidationError('CPF inválido')

    @validates('telefone')
    def validate_telefone(self, value):
        digits = ''.join(filter(str.isdigit, value))
        if len(digits) not in (10, 11):
            raise ValidationError('Telefone inválido (10 ou 11 dígitos)')

    @validates('endereco_cep')
    def validate_cep(self, value):
        digits = ''.join(filter(str.isdigit, value))
        if len(digits) != 8:
            raise ValidationError('CEP inválido (8 dígitos)')


class ClienteUpdateSchema(ClienteSchema):
    nome = fields.Str(load_default=None, validate=validate.Length(min=2, max=120))
    cpf  = fields.Str(load_default=None)
    telefone             = fields.Str(load_default=None)
    endereco_logradouro  = fields.Str(load_default=None)
    endereco_numero      = fields.Str(load_default=None)
    endereco_bairro      = fields.Str(load_default=None)
    endereco_cidade      = fields.Str(load_default=None)
    endereco_estado      = fields.Str(load_default=None, validate=validate.Length(equal=2))
    endereco_cep         = fields.Str(load_default=None)
