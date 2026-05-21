from .. import db

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
