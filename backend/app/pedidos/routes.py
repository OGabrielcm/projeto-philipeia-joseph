from flask import Blueprint, request, jsonify
from marshmallow import ValidationError
from ..auth.middleware import require_auth
from .schemas import CreateOrderSchema, UpdateOrderSchema, CancelOrderSchema
from . import service

pedidos_bp = Blueprint('pedidos', __name__)

_create_schema = CreateOrderSchema()
_update_schema = UpdateOrderSchema()
_cancel_schema = CancelOrderSchema()


@pedidos_bp.get('/')
@require_auth
def list_pedidos():
    page     = int(request.args.get('page', 1))
    per_page = min(int(request.args.get('per_page', 25)), 100)
    return jsonify(service.list_pedidos(
        status      = request.args.get('status'),
        data_inicio = request.args.get('data_inicio'),
        data_fim    = request.args.get('data_fim'),
        q           = request.args.get('q'),
        page        = page,
        per_page    = per_page,
    )), 200


@pedidos_bp.get('/<int:pedido_id>')
@require_auth
def get_pedido(pedido_id):
    pedido = service.get_pedido(pedido_id)
    if not pedido:
        return jsonify(error='Pedido não encontrado'), 404
    return jsonify(pedido), 200


@pedidos_bp.post('/')
@require_auth
def create_pedido():
    try:
        data = _create_schema.load(request.get_json(silent=True) or {})
    except ValidationError as e:
        return jsonify(errors=e.messages), 422

    pedido = service.create_order(data)
    return jsonify(pedido), 201


@pedidos_bp.put('/<int:pedido_id>')
@require_auth
def update_pedido(pedido_id):
    try:
        data = _update_schema.load(request.get_json(silent=True) or {})
    except ValidationError as e:
        return jsonify(errors=e.messages), 422

    try:
        pedido = service.update_order(pedido_id, data)
    except ValueError as e:
        return jsonify(error=str(e)), 409

    if not pedido:
        return jsonify(error='Pedido não encontrado'), 404
    return jsonify(pedido), 200


@pedidos_bp.delete('/<int:pedido_id>')
@require_auth
def delete_pedido(pedido_id):
    deleted = service.delete_order(pedido_id)
    if not deleted:
        return jsonify(error='Pedido não encontrado'), 404
    return '', 204


@pedidos_bp.post('/<int:pedido_id>/cancelar')
@require_auth
def cancelar_pedido(pedido_id):
    try:
        data = _cancel_schema.load(request.get_json(silent=True) or {})
    except ValidationError as e:
        return jsonify(errors=e.messages), 422

    try:
        pedido = service.cancel_order(pedido_id, data['motivo'])
    except ValueError as e:
        return jsonify(error=str(e)), 409

    if not pedido:
        return jsonify(error='Pedido não encontrado'), 404
    return jsonify(pedido), 200
