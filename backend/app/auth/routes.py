from datetime import datetime, timezone, timedelta
from flask import Blueprint, request, jsonify, current_app
import jwt
import bcrypt

auth_bp = Blueprint('auth', __name__)


@auth_bp.post('/login')
def login():
    data = request.get_json(silent=True) or {}
    email = data.get('email', '').strip().lower()
    senha = data.get('senha', '')

    admin_email = current_app.config['ADMIN_EMAIL'].strip().lower()
    admin_hash  = current_app.config['ADMIN_PASSWORD_HASH'].encode()

    if email != admin_email or not bcrypt.checkpw(senha.encode(), admin_hash):
        return jsonify(error='Credenciais inválidas'), 401

    expiry_hours = current_app.config['JWT_EXPIRY_HOURS']
    expires_at   = datetime.now(timezone.utc) + timedelta(hours=expiry_hours)
    token = jwt.encode(
        {'sub': 'admin', 'exp': expires_at},
        current_app.config['JWT_SECRET'],
        algorithm='HS256',
    )

    return jsonify(token=token, expires_at=expires_at.isoformat()), 200


@auth_bp.post('/logout')
def logout():
    # Stateless — o client descarta o token localmente
    return jsonify(message='Logout efetuado'), 200
