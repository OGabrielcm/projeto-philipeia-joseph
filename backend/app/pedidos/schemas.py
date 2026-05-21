from marshmallow import Schema, fields, validates_schema, validates, ValidationError, validate


class EnderecoSchema(Schema):
    logradouro  = fields.Str(required=True)
    numero      = fields.Str(required=True)
    complemento = fields.Str(load_default=None)
    bairro      = fields.Str(required=True)
    cidade      = fields.Str(required=True)
    estado      = fields.Str(required=True, validate=validate.Length(equal=2))
    cep         = fields.Str(required=True)

    @validates('cep')
    def validate_cep(self, value):
        digits = ''.join(filter(str.isdigit, value))
        if len(digits) != 8:
            raise ValidationError('CEP inválido (8 dígitos)')


class OrderItemSchema(Schema):
    tipo            = fields.Str(required=True, validate=validate.OneOf(['item', 'combo']))
    style_volume_id = fields.Int(load_default=None)
    combo_id        = fields.Int(load_default=None)
    quantidade      = fields.Int(required=True, validate=validate.Range(min=1))
    preco_unitario  = fields.Decimal(required=True, places=2, as_string=False)
    consignado      = fields.Bool(load_default=False)

    @validates_schema
    def validate_tipo(self, data, **kwargs):
        if data['tipo'] == 'item' and not data.get('style_volume_id'):
            raise ValidationError('style_volume_id obrigatório para tipo=item', 'style_volume_id')
        if data['tipo'] == 'combo' and not data.get('combo_id'):
            raise ValidationError('combo_id obrigatório para tipo=combo', 'combo_id')
        if data['tipo'] == 'combo' and data.get('consignado'):
            raise ValidationError('Combo não pode ser consignado', 'consignado')


class CreateOrderSchema(Schema):
    customer_id       = fields.Int(required=True)
    data_evento       = fields.Date(required=True)
    hora_inicio       = fields.Time(required=True)
    data_recolhimento = fields.Date(required=True)
    hora_recolhimento = fields.Time(required=True)
    endereco          = fields.Nested(EnderecoSchema, required=True)
    observacoes       = fields.Str(load_default=None, validate=validate.Length(max=2000))
    itens             = fields.List(
        fields.Nested(OrderItemSchema),
        required=True,
        validate=validate.Length(min=1),
    )
    taxa_instalacao = fields.Decimal(load_default=0, places=2, as_string=False)
    desconto        = fields.Decimal(load_default=0, places=2, as_string=False)
    total_manual    = fields.Decimal(load_default=None, places=2, as_string=False, allow_none=True)
    status          = fields.Str(
        load_default='pendente',
        validate=validate.OneOf(['pendente', 'confirmado']),
    )

    @validates_schema
    def validate_datas(self, data, **kwargs):
        if data['data_recolhimento'] < data['data_evento']:
            raise ValidationError(
                'data_recolhimento deve ser >= data_evento', 'data_recolhimento'
            )


class UpdateOrderSchema(Schema):
    data_evento       = fields.Date(load_default=None)
    hora_inicio       = fields.Time(load_default=None)
    data_recolhimento = fields.Date(load_default=None)
    hora_recolhimento = fields.Time(load_default=None)
    endereco          = fields.Nested(EnderecoSchema, load_default=None)
    observacoes       = fields.Str(load_default=None, validate=validate.Length(max=2000))
    itens             = fields.List(fields.Nested(OrderItemSchema), load_default=None)
    taxa_instalacao   = fields.Decimal(load_default=None, places=2, as_string=False)
    desconto          = fields.Decimal(load_default=None, places=2, as_string=False)
    total_manual      = fields.Decimal(load_default=None, places=2, as_string=False, allow_none=True)
    status            = fields.Str(load_default=None, validate=validate.OneOf(['pendente', 'confirmado']))


class CancelOrderSchema(Schema):
    motivo = fields.Str(required=True, validate=validate.Length(min=5, max=500))
