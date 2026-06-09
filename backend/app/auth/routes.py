import secrets
from datetime import datetime, timezone, timedelta
from flask import Blueprint, request, jsonify, current_app
import jwt
import bcrypt

from .middleware import require_auth
from .recovery_email import send_recovery_email

auth_bp = Blueprint('auth', __name__)

_recovery_tokens: dict = {}  # email → {code, expires}


@auth_bp.post('/login')
def login():
    data  = request.get_json(silent=True) or {}
    email = data.get('email', '').strip().lower()
    senha = data.get('senha', '')

    admin_email = current_app.config['ADMIN_EMAIL'].strip().lower()
    admin_hash  = current_app.config['ADMIN_PASSWORD_HASH'].encode()

    if email != admin_email or not bcrypt.checkpw(senha.encode(), admin_hash):
        return jsonify(error='Credenciais inválidas'), 401

    expiry_hours = current_app.config['JWT_EXPIRY_HOURS']
    expires_at   = datetime.now(timezone.utc) + timedelta(hours=expiry_hours)
    token = jwt.encode(
        {'sub': email, 'exp': expires_at},
        current_app.config['JWT_SECRET'],
        algorithm='HS256',
    )

    return jsonify(token=token, expires_at=expires_at.isoformat()), 200


@auth_bp.post('/logout')
def logout():
    return jsonify(message='Logout efetuado'), 200


@auth_bp.get('/me')
@require_auth
def me():
    return jsonify(
        email=current_app.config['ADMIN_EMAIL'],
        nome='Administrador',
        role='admin',
    ), 200


@auth_bp.post('/recuperar-senha')
def recuperar_senha():
    data  = request.get_json(silent=True) or {}
    email = data.get('email', '').strip().lower()

    admin_email = current_app.config['ADMIN_EMAIL'].strip().lower()
    if email == admin_email:
        code    = secrets.token_hex(3).upper()  # 6-char hex code
        expires = datetime.now(timezone.utc) + timedelta(minutes=30)
        _recovery_tokens[email] = {'code': code, 'expires': expires}
        send_recovery_email(email, code, current_app.config)

    return jsonify(message='Se o e-mail estiver cadastrado, você receberá as instruções em breve.'), 200
