from .. import db

_SELECT_COLS = """
    id, nome, cpf, telefone, telefone_whatsapp,
    whatsapp_igual_principal, email,
    endereco_logradouro, endereco_numero, endereco_complemento,
    endereco_bairro, endereco_cidade, endereco_estado, endereco_cep,
    created_at, updated_at
"""

_SEARCH_SQL = f"""
SELECT {_SELECT_COLS}
FROM customers
WHERE deleted_at IS NULL
  AND (
    nome LIKE ? OR
    cpf  LIKE ?
  )
ORDER BY nome
OFFSET ? ROWS FETCH NEXT ? ROWS ONLY
"""

_COUNT_SQL = """
SELECT COUNT(*) AS total
FROM customers
WHERE deleted_at IS NULL
  AND (nome LIKE ? OR cpf LIKE ?)
"""

_GET_SQL = f"""
SELECT {_SELECT_COLS}
FROM customers
WHERE id = ? AND deleted_at IS NULL
"""

_GET_BY_CPF_SQL = f"""
SELECT {_SELECT_COLS}
FROM customers
WHERE cpf = ? AND deleted_at IS NULL
"""

_INSERT_SQL = """
INSERT INTO customers (
    nome, cpf, telefone, telefone_whatsapp, whatsapp_igual_principal,
    email, endereco_logradouro, endereco_numero, endereco_complemento,
    endereco_bairro, endereco_cidade, endereco_estado, endereco_cep
) OUTPUT INSERTED.id
VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)
"""

_UPDATE_SQL = """
UPDATE customers SET
    nome=?, cpf=?, telefone=?, telefone_whatsapp=?, whatsapp_igual_principal=?,
    email=?, endereco_logradouro=?, endereco_numero=?, endereco_complemento=?,
    endereco_bairro=?, endereco_cidade=?, endereco_estado=?, endereco_cep=?,
    updated_at=GETDATE()
WHERE id=? AND deleted_at IS NULL
"""

_DELETE_SQL = """
UPDATE customers SET deleted_at=GETDATE(), updated_at=GETDATE()
WHERE id=? AND deleted_at IS NULL
"""


def _clean_cpf(cpf: str) -> str:
    return ''.join(filter(str.isdigit, cpf))


def _clean_phone(phone: str | None) -> str | None:
    if phone is None:
        return None
    return ''.join(filter(str.isdigit, phone))


def list_clientes(q: str = '', page: int = 1, per_page: int = 25) -> dict:
    pattern = f'%{q}%'
    offset  = (page - 1) * per_page

    total = db.fetchone(_COUNT_SQL, pattern, pattern)['total']
    rows  = db.fetchall(_SEARCH_SQL, pattern, pattern, offset, per_page)

    return {
        'data':      [_serialize(r) for r in rows],
        'total':     total,
        'page':      page,
        'per_page':  per_page,
        'pages':     (total + per_page - 1) // per_page,
    }


def get_cliente(cliente_id: int) -> dict | None:
    row = db.fetchone(_GET_SQL, cliente_id)
    return _serialize(row) if row else None


def get_by_cpf(cpf: str) -> dict | None:
    row = db.fetchone(_GET_BY_CPF_SQL, _clean_cpf(cpf))
    return _serialize(row) if row else None


def create_cliente(data: dict) -> dict:
    cpf = _clean_cpf(data['cpf'])

    existing = db.fetchone(_GET_BY_CPF_SQL, cpf)
    if existing:
        raise ValueError(f'CPF já cadastrado (id={existing["id"]})')

    new_id = db.execute_insert(
        _INSERT_SQL,
        data['nome'],
        cpf,
        _clean_phone(data['telefone']),
        _clean_phone(data.get('telefone_whatsapp')),
        int(data.get('whatsapp_igual_principal', False)),
        data.get('email'),
        data['endereco_logradouro'],
        data['endereco_numero'],
        data.get('endereco_complemento'),
        data['endereco_bairro'],
        data['endereco_cidade'],
        data['endereco_estado'].upper(),
        ''.join(filter(str.isdigit, data['endereco_cep'])),
    )
    return get_cliente(new_id)


def update_cliente(cliente_id: int, data: dict) -> dict | None:
    current = get_cliente(cliente_id)
    if not current:
        return None

    merged = {**current, **{k: v for k, v in data.items() if v is not None}}

    cpf = _clean_cpf(merged['cpf'])
    existing = db.fetchone(_GET_BY_CPF_SQL, cpf)
    if existing and existing['id'] != cliente_id:
        raise ValueError('CPF já pertence a outro cliente')

    db.execute(
        _UPDATE_SQL,
        merged['nome'],
        cpf,
        _clean_phone(merged['telefone']),
        _clean_phone(merged.get('telefone_whatsapp')),
        int(merged.get('whatsapp_igual_principal', False)),
        merged.get('email'),
        merged['endereco_logradouro'],
        merged['endereco_numero'],
        merged.get('endereco_complemento'),
        merged['endereco_bairro'],
        merged['endereco_cidade'],
        merged['endereco_estado'].upper(),
        ''.join(filter(str.isdigit, merged['endereco_cep'])),
        cliente_id,
    )
    return get_cliente(cliente_id)


def delete_cliente(cliente_id: int) -> bool:
    row = db.fetchone(_GET_SQL, cliente_id)
    if not row:
        return False
    db.execute(_DELETE_SQL, cliente_id)
    return True


def _serialize(row: dict) -> dict:
    return {
        'id':                      row['id'],
        'nome':                    row['nome'],
        'cpf':                     row['cpf'],
        'telefone':                row['telefone'],
        'telefone_whatsapp':       row['telefone_whatsapp'],
        'whatsapp_igual_principal': bool(row['whatsapp_igual_principal']),
        'email':                   row['email'],
        'endereco_logradouro':     row['endereco_logradouro'],
        'endereco_numero':         row['endereco_numero'],
        'endereco_complemento':    row['endereco_complemento'],
        'endereco_bairro':         row['endereco_bairro'],
        'endereco_cidade':         row['endereco_cidade'],
        'endereco_estado':         row['endereco_estado'],
        'endereco_cep':            row['endereco_cep'],
        'created_at':              str(row['created_at']),
        'updated_at':              str(row['updated_at']),
    }
