from .. import db

_INSERT_STYLE = """
INSERT INTO styles (nome, categoria) OUTPUT INSERTED.id VALUES (?,?)
"""

_INSERT_VOLUME = """
INSERT INTO style_volumes (style_id, volume_litros, preco) VALUES (?,?,?)
"""

_UPDATE_STYLE = """
UPDATE styles SET nome=?, categoria=?, updated_at=GETDATE() WHERE id=? AND ativo=1
"""

_DEACTIVATE_VOLUMES = """
UPDATE style_volumes SET ativo=0 WHERE style_id=?
"""

_ESTILOS_SQL = """
SELECT
    s.id          AS style_id,
    s.nome        AS style_nome,
    s.categoria,
    sv.id         AS sv_id,
    sv.volume_litros,
    sv.preco
FROM styles s
JOIN style_volumes sv ON sv.style_id = s.id AND sv.ativo = 1
WHERE s.ativo = 1
ORDER BY s.categoria, s.nome, sv.volume_litros
"""

_COMBOS_SQL = """
SELECT
    c.id,
    c.nome,
    c.preco,
    sv1.id            AS sv1_id,
    s1.nome           AS sv1_style_nome,
    sv1.volume_litros AS sv1_volume,
    sv1.preco         AS sv1_preco,
    sv2.id            AS sv2_id,
    s2.nome           AS sv2_style_nome,
    sv2.volume_litros AS sv2_volume,
    sv2.preco         AS sv2_preco
FROM combos c
JOIN style_volumes sv1 ON sv1.id = c.style_volume_1_id
JOIN styles s1         ON s1.id  = sv1.style_id
JOIN style_volumes sv2 ON sv2.id = c.style_volume_2_id
JOIN styles s2         ON s2.id  = sv2.style_id
WHERE c.ativo = 1
ORDER BY c.nome
"""


def list_estilos() -> list[dict]:
    rows = db.fetchall(_ESTILOS_SQL)

    # Agrupa volumes por estilo
    estilos: dict[int, dict] = {}
    for r in rows:
        sid = r['style_id']
        if sid not in estilos:
            estilos[sid] = {
                'id':        sid,
                'nome':      r['style_nome'],
                'categoria': r['categoria'],
                'volumes':   [],
            }
        estilos[sid]['volumes'].append({
            'id':            r['sv_id'],
            'volume_litros': r['volume_litros'],
            'preco':         float(r['preco']),
        })

    return list(estilos.values())


def _get_estilo(estilo_id: int) -> dict | None:
    for e in list_estilos():
        if e['id'] == estilo_id:
            return e
    return None


def create_estilo(data: dict) -> dict:
    estilo_id = db.execute_insert(_INSERT_STYLE, data['nome'], data['categoria'])
    for v in data.get('volumes', []):
        db.execute(_INSERT_VOLUME, estilo_id, int(v['volume_litros']), float(v['preco']))
    return _get_estilo(estilo_id)


def update_estilo(estilo_id: int, data: dict) -> dict | None:
    row = db.fetchone('SELECT id FROM styles WHERE id=? AND ativo=1', estilo_id)
    if not row:
        return None
    db.execute(_UPDATE_STYLE, data['nome'], data['categoria'], estilo_id)
    if 'volumes' in data:
        db.execute(_DEACTIVATE_VOLUMES, estilo_id)
        for v in data['volumes']:
            db.execute(_INSERT_VOLUME, estilo_id, int(v['volume_litros']), float(v['preco']))
    return _get_estilo(estilo_id)


def delete_estilo(estilo_id: int) -> bool:
    row = db.fetchone('SELECT id FROM styles WHERE id=? AND ativo=1', estilo_id)
    if not row:
        return False
    db.execute('UPDATE styles SET ativo=0, updated_at=GETDATE() WHERE id=?', estilo_id)
    db.execute(_DEACTIVATE_VOLUMES, estilo_id)
    return True


def list_combos() -> list[dict]:
    rows = db.fetchall(_COMBOS_SQL)
    return [
        {
            'id':    r['id'],
            'nome':  r['nome'],
            'preco': float(r['preco']),
            'item_1': {
                'style_volume_id': r['sv1_id'],
                'style_nome':      r['sv1_style_nome'],
                'volume_litros':   r['sv1_volume'],
                'preco':           float(r['sv1_preco']),
            },
            'item_2': {
                'style_volume_id': r['sv2_id'],
                'style_nome':      r['sv2_style_nome'],
                'volume_litros':   r['sv2_volume'],
                'preco':           float(r['sv2_preco']),
            },
        }
        for r in rows
    ]
