from .. import db
from .email import send_order_confirmation

# ── Queries ────────────────────────────────────────────────────────────────────

_INSERT_ORDER = """
INSERT INTO orders (
    customer_id, status,
    data_evento, hora_inicio, data_recolhimento, hora_recolhimento,
    endereco_logradouro, endereco_numero, endereco_complemento,
    endereco_bairro, endereco_cidade, endereco_estado, endereco_cep,
    observacoes, subtotal, taxa_instalacao, desconto, total, total_overridden
) OUTPUT INSERTED.id
VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
"""

_INSERT_ITEM = """
INSERT INTO order_items
    (order_id, tipo, style_volume_id, combo_id, quantidade, preco_unitario, consignado, posicao)
VALUES (?,?,?,?,?,?,?,?)
"""

_SELECT_ORDER = """
SELECT
    o.id, o.numero, o.status,
    o.data_evento, o.hora_inicio, o.data_recolhimento, o.hora_recolhimento,
    o.endereco_logradouro, o.endereco_numero, o.endereco_complemento,
    o.endereco_bairro, o.endereco_cidade, o.endereco_estado, o.endereco_cep,
    o.observacoes, o.subtotal, o.taxa_instalacao, o.desconto, o.total, o.total_overridden,
    o.cancelled_at, o.cancelled_reason, o.created_at, o.updated_at,
    o.customer_id,
    c.nome  AS customer_nome,
    c.cpf   AS customer_cpf,
    c.telefone AS customer_telefone,
    c.email AS customer_email
FROM orders o
JOIN customers c ON c.id = o.customer_id
WHERE o.id = ?
"""

_SELECT_ITEMS = """
SELECT
    oi.id, oi.tipo, oi.style_volume_id, oi.combo_id,
    oi.quantidade, oi.preco_unitario, oi.consignado, oi.posicao,
    COALESCE(s.nome + ' ' + CAST(sv.volume_litros AS VARCHAR) + 'L', cb.nome) AS descricao
FROM order_items oi
LEFT JOIN style_volumes sv ON sv.id = oi.style_volume_id
LEFT JOIN styles s         ON s.id  = sv.style_id
LEFT JOIN combos cb        ON cb.id = oi.combo_id
WHERE oi.order_id = ?
ORDER BY oi.posicao
"""

_LIST_BASE = """
SELECT
    o.id, o.numero, o.status,
    o.data_evento, o.total, o.created_at,
    c.nome AS customer_nome, c.cpf AS customer_cpf
FROM orders o
JOIN customers c ON c.id = o.customer_id
WHERE 1=1
"""

_DELETE_ITEMS = "DELETE FROM order_items WHERE order_id = ?"


# ── Helpers ────────────────────────────────────────────────────────────────────

def _ser_order(row: dict) -> dict:
    return {
        'id':                   row['id'],
        'numero':               row['numero'],
        'status':               row['status'],
        'data_evento':          str(row['data_evento']),
        'hora_inicio':          str(row['hora_inicio']),
        'data_recolhimento':    str(row['data_recolhimento']),
        'hora_recolhimento':    str(row['hora_recolhimento']),
        'endereco_logradouro':  row['endereco_logradouro'],
        'endereco_numero':      row['endereco_numero'],
        'endereco_complemento': row['endereco_complemento'],
        'endereco_bairro':      row['endereco_bairro'],
        'endereco_cidade':      row['endereco_cidade'],
        'endereco_estado':      row['endereco_estado'],
        'endereco_cep':         row['endereco_cep'],
        'observacoes':          row['observacoes'],
        'subtotal':             float(row['subtotal']),
        'taxa_instalacao':      float(row['taxa_instalacao']),
        'desconto':             float(row['desconto']),
        'total':                float(row['total']),
        'total_overridden':     bool(row['total_overridden']),
        'cancelled_at':         str(row['cancelled_at']) if row['cancelled_at'] else None,
        'cancelled_reason':     row['cancelled_reason'],
        'created_at':           str(row['created_at']),
        'updated_at':           str(row['updated_at']),
        'customer_id':          row['customer_id'],
        'customer_nome':        row['customer_nome'],
        'customer_cpf':         row['customer_cpf'],
        'customer_telefone':    row['customer_telefone'],
        'customer_email':       row['customer_email'],
    }


def _ser_item(row: dict) -> dict:
    return {
        'id':               row['id'],
        'tipo':             row['tipo'],
        'style_volume_id':  row['style_volume_id'],
        'combo_id':         row['combo_id'],
        'quantidade':       row['quantidade'],
        'preco_unitario':   float(row['preco_unitario']),
        'consignado':       bool(row['consignado']),
        'posicao':          row['posicao'],
        'descricao':        row['descricao'],
    }


def _calc_totais(itens: list, taxa: float, desconto: float, total_manual) -> tuple:
    subtotal = sum(i['quantidade'] * float(i['preco_unitario']) for i in itens)
    if total_manual is not None:
        return subtotal, float(total_manual), True
    return subtotal, subtotal + taxa - desconto, False


# ── Public API ─────────────────────────────────────────────────────────────────

def get_pedido(pedido_id: int) -> dict | None:
    row = db.fetchone(_SELECT_ORDER, pedido_id)
    if not row:
        return None
    order = _ser_order(row)
    order['itens'] = [_ser_item(r) for r in db.fetchall(_SELECT_ITEMS, pedido_id)]
    return order


def list_pedidos(status=None, data_inicio=None, data_fim=None,
                 q=None, page=1, per_page=25) -> dict:
    filters, params = [], []

    if status:
        filters.append('AND o.status = ?')
        params.append(status)
    if data_inicio:
        filters.append('AND o.data_evento >= ?')
        params.append(data_inicio)
    if data_fim:
        filters.append('AND o.data_evento <= ?')
        params.append(data_fim)
    if q:
        filters.append('AND (c.nome LIKE ? OR c.cpf LIKE ?)')
        pattern = f'%{q}%'
        params += [pattern, pattern]

    where = ' '.join(filters)
    count_sql = f"""
        SELECT COUNT(*) AS total FROM orders o
        JOIN customers c ON c.id = o.customer_id
        WHERE 1=1 {where}
    """
    total = db.fetchone(count_sql, *params)['total']

    list_sql = f"""
        {_LIST_BASE} {where}
        ORDER BY o.created_at DESC
        OFFSET ? ROWS FETCH NEXT ? ROWS ONLY
    """
    offset = (page - 1) * per_page
    rows   = db.fetchall(list_sql, *params, offset, per_page)

    return {
        'data': [
            {
                'id':            r['id'],
                'numero':        r['numero'],
                'status':        r['status'],
                'data_evento':   str(r['data_evento']),
                'total':         float(r['total']),
                'created_at':    str(r['created_at']),
                'customer_nome': r['customer_nome'],
                'customer_cpf':  r['customer_cpf'],
            }
            for r in rows
        ],
        'total':    total,
        'page':     page,
        'per_page': per_page,
        'pages':    (total + per_page - 1) // per_page,
    }


def create_order(data: dict) -> dict:
    taxa     = float(data.get('taxa_instalacao') or 0)
    desconto = float(data.get('desconto') or 0)
    subtotal, total, overridden = _calc_totais(
        data['itens'], taxa, desconto, data.get('total_manual')
    )
    end = data['endereco']

    with db.transaction() as conn:
        cursor = conn.cursor()
        cursor.execute(
            _INSERT_ORDER,
            data['customer_id'],
            data.get('status', 'pendente'),
            str(data['data_evento']),
            str(data['hora_inicio']),
            str(data['data_recolhimento']),
            str(data['hora_recolhimento']),
            end['logradouro'], end['numero'], end.get('complemento'),
            end['bairro'], end['cidade'], end['estado'].upper(),
            ''.join(filter(str.isdigit, end['cep'])),
            data.get('observacoes'),
            subtotal, taxa, desconto, total, int(overridden),
        )
        order_id = cursor.fetchone()[0]

        for pos, item in enumerate(data['itens']):
            cursor.execute(
                _INSERT_ITEM,
                order_id,
                item['tipo'],
                item.get('style_volume_id'),
                item.get('combo_id'),
                item['quantidade'],
                float(item['preco_unitario']),
                int(item.get('consignado', False)),
                pos,
            )

    pedido = get_pedido(order_id)
    send_order_confirmation(pedido, pedido['itens'])
    return pedido


def update_order(pedido_id: int, data: dict) -> dict | None:
    current = get_pedido(pedido_id)
    if not current:
        return None
    if current['status'] == 'cancelado':
        raise ValueError('Pedido cancelado não pode ser editado')

    sets, params = [], []

    scalar_fields = [
        ('status', 'status'), ('observacoes', 'observacoes'),
    ]
    for key, col in scalar_fields:
        if data.get(key) is not None:
            sets.append(f'{col} = ?')
            params.append(data[key])

    # taxa_instalacao pode ser atualizada sem alterar os itens
    if data.get('taxa_instalacao') is not None and data.get('itens') is None:
        nova_taxa = float(data['taxa_instalacao'])
        novo_total = float(current['subtotal']) + nova_taxa - float(current['desconto'])
        sets += ['taxa_instalacao = ?', 'total = ?']
        params += [nova_taxa, novo_total]

    date_fields = [
        ('data_evento', 'data_evento'), ('hora_inicio', 'hora_inicio'),
        ('data_recolhimento', 'data_recolhimento'), ('hora_recolhimento', 'hora_recolhimento'),
    ]
    for key, col in date_fields:
        if data.get(key) is not None:
            sets.append(f'{col} = ?')
            params.append(str(data[key]))

    if data.get('endereco'):
        end = data['endereco']
        for col, val in [
            ('endereco_logradouro', end['logradouro']),
            ('endereco_numero', end['numero']),
            ('endereco_complemento', end.get('complemento')),
            ('endereco_bairro', end['bairro']),
            ('endereco_cidade', end['cidade']),
            ('endereco_estado', end['estado'].upper()),
            ('endereco_cep', ''.join(filter(str.isdigit, end['cep']))),
        ]:
            sets.append(f'{col} = ?')
            params.append(val)

    if data.get('itens') is not None:
        taxa     = float(data.get('taxa_instalacao') or current['taxa_instalacao'])
        desconto = float(data.get('desconto') or current['desconto'])
        subtotal, total, overridden = _calc_totais(data['itens'], taxa, desconto, data.get('total_manual'))
        sets += ['subtotal = ?', 'taxa_instalacao = ?', 'desconto = ?', 'total = ?', 'total_overridden = ?']
        params += [subtotal, taxa, desconto, total, int(overridden)]

    if not sets:
        return current

    sets.append('updated_at = GETDATE()')
    params.append(pedido_id)

    with db.transaction() as conn:
        cursor = conn.cursor()
        cursor.execute(f"UPDATE orders SET {', '.join(sets)} WHERE id = ?", *params)
        if data.get('itens') is not None:
            cursor.execute(_DELETE_ITEMS, pedido_id)
            for pos, item in enumerate(data['itens']):
                cursor.execute(
                    _INSERT_ITEM,
                    pedido_id, item['tipo'],
                    item.get('style_volume_id'), item.get('combo_id'),
                    item['quantidade'], float(item['preco_unitario']),
                    int(item.get('consignado', False)), pos,
                )

    return get_pedido(pedido_id)


def cancel_order(pedido_id: int, motivo: str) -> dict | None:
    current = get_pedido(pedido_id)
    if not current:
        return None
    if current['status'] == 'cancelado':
        raise ValueError('Pedido já está cancelado')

    db.execute(
        """
        UPDATE orders SET
            status = 'cancelado',
            cancelled_at = GETDATE(),
            cancelled_reason = ?,
            updated_at = GETDATE()
        WHERE id = ?
        """,
        motivo, pedido_id,
    )
    return get_pedido(pedido_id)


def delete_order(pedido_id: int) -> bool:
    row = db.fetchone('SELECT id FROM orders WHERE id = ?', pedido_id)
    if not row:
        return False
    db.execute('DELETE FROM orders WHERE id = ?', pedido_id)
    return True
