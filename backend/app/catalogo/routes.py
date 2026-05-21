from flask import Blueprint, jsonify
from ..auth.middleware import require_auth
from . import service

catalogo_bp = Blueprint('catalogo', __name__)


@catalogo_bp.get('/estilos')
@require_auth
def get_estilos():
    return jsonify(service.list_estilos()), 200


@catalogo_bp.get('/combos')
@require_auth
def get_combos():
    return jsonify(service.list_combos()), 200
