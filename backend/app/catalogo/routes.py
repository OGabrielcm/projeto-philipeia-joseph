from flask import Blueprint, jsonify, request
from ..auth.middleware import require_auth
from . import service

catalogo_bp = Blueprint('catalogo', __name__)


@catalogo_bp.get('/estilos')
@require_auth
def get_estilos():
    return jsonify(service.list_estilos()), 200


@catalogo_bp.post('/estilos')
@require_auth
def create_estilo():
    data = request.get_json(silent=True) or {}
    nome = (data.get('nome') or '').strip()
    categoria = (data.get('categoria') or '').strip()
    volumes = data.get('volumes', [])
    if not nome:
        return jsonify(error='nome é obrigatório'), 422
    if categoria not in ('chopp', 'drink'):
        return jsonify(error='categoria deve ser chopp ou drink'), 422
    try:
        estilo = service.create_estilo({'nome': nome, 'categoria': categoria, 'volumes': volumes})
    except Exception as e:
        return jsonify(error=str(e)), 409
    return jsonify(estilo), 201


@catalogo_bp.put('/estilos/<int:estilo_id>')
@require_auth
def update_estilo(estilo_id):
    data = request.get_json(silent=True) or {}
    nome = (data.get('nome') or '').strip()
    categoria = (data.get('categoria') or '').strip()
    if not nome:
        return jsonify(error='nome é obrigatório'), 422
    if categoria not in ('chopp', 'drink'):
        return jsonify(error='categoria deve ser chopp ou drink'), 422
    try:
        estilo = service.update_estilo(estilo_id, {
            'nome': nome, 'categoria': categoria,
            'volumes': data.get('volumes', []),
        })
    except Exception as e:
        return jsonify(error=str(e)), 409
    if not estilo:
        return jsonify(error='Estilo não encontrado'), 404
    return jsonify(estilo), 200


@catalogo_bp.delete('/estilos/<int:estilo_id>')
@require_auth
def delete_estilo(estilo_id):
    deleted = service.delete_estilo(estilo_id)
    if not deleted:
        return jsonify(error='Estilo não encontrado'), 404
    return '', 204


@catalogo_bp.get('/combos')
@require_auth
def get_combos():
    return jsonify(service.list_combos()), 200
