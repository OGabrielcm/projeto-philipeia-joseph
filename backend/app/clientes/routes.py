import logging
from flask import Blueprint, request, jsonify
from marshmallow import ValidationError
from ..auth.middleware import require_auth
from .schemas import ClienteSchema, ClienteUpdateSchema
from . import service

_log = logging.getLogger(__name__)
clientes_bp = Blueprint('clientes', __name__)

_schema        = ClienteSchema()
_update_schema = ClienteUpdateSchema()


@clientes_bp.get('/')
@require_auth
def list_clientes():
    q        = request.args.get('q', '').strip()
    page     = int(request.args.get('page', 1))
    per_page = min(int(request.args.get('per_page', 25)), 100)
    return jsonify(service.list_clientes(q, page, per_page)), 200


@clientes_bp.get('/<int:cliente_id>')
@require_auth
def get_cliente(cliente_id):
    cliente = service.get_cliente(cliente_id)
    if not cliente:
        return jsonify(error='Cliente não encontrado'), 404
    return jsonify(cliente), 200


@clientes_bp.post('/')
@require_auth
def create_cliente():
    payload = request.get_json(silent=True) or {}
    try:
        data = _schema.load(payload)
    except ValidationError as e:
        _log.warning('Cliente 422 - payload=%s errors=%s', payload, e.messages)
        return jsonify(errors=e.messages), 422

    try:
        cliente = service.create_cliente(data)
    except ValueError as e:
        return jsonify(error=str(e)), 409

    return jsonify(cliente), 201


@clientes_bp.put('/<int:cliente_id>')
@require_auth
def update_cliente(cliente_id):
    try:
        data = _update_schema.load(request.get_json(silent=True) or {})
    except ValidationError as e:
        return jsonify(errors=e.messages), 422

    try:
        cliente = service.update_cliente(cliente_id, data)
    except ValueError as e:
        return jsonify(error=str(e)), 409

    if not cliente:
        return jsonify(error='Cliente não encontrado'), 404
    return jsonify(cliente), 200


@clientes_bp.delete('/<int:cliente_id>')
@require_auth
def delete_cliente(cliente_id):
    deleted = service.delete_cliente(cliente_id)
    if not deleted:
        return jsonify(error='Cliente não encontrado'), 404
    return '', 204
