import os
import secrets
from datetime import datetime, timezone, timedelta
from flask import Blueprint, request, jsonify, current_app
import jwt
import bcrypt

from .middleware import require_auth
from .recovery_email import send_recovery_email

auth_bp = Blueprint('auth', __name__)

_recovery_tokens: dict = {} 


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


def _update_env(updates: dict) -> None:
    env_path = os.path.normpath(
        os.path.join(os.path.dirname(__file__), '..', '..', '..', '.env')
    )
    if not os.path.exists(env_path):
        return
    with open(env_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    updated_keys: set = set()
    new_lines = []
    for line in lines:
        stripped = line.rstrip('\n')
        if '=' in stripped and not stripped.lstrip().startswith('#'):
            key = stripped.split('=', 1)[0].strip()
            if key in updates:
                new_lines.append(f'{key}={updates[key]}\n')
                updated_keys.add(key)
                continue
        new_lines.append(line if line.endswith('\n') else line + '\n')
    for key, val in updates.items():
        if key not in updated_keys:
            new_lines.append(f'{key}={val}\n')
    with open(env_path, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)


@auth_bp.patch('/perfil')
@require_auth
def atualizar_perfil():
    data = request.get_json(silent=True) or {}
    senha_atual = data.get('senha_atual', '')

    admin_hash = current_app.config['ADMIN_PASSWORD_HASH'].encode()
    if not bcrypt.checkpw(senha_atual.encode(), admin_hash):
        return jsonify(error='Senha atual incorreta'), 401

    novo_email = (data.get('email') or '').strip().lower()
    nova_senha = (data.get('nova_senha') or '').strip()

    if not novo_email and not nova_senha:
        return jsonify(error='Informe o novo e-mail ou a nova senha'), 422

    env_updates: dict = {}

    if novo_email:
        current_app.config['ADMIN_EMAIL'] = novo_email
        env_updates['ADMIN_EMAIL'] = novo_email

    if nova_senha:
        if len(nova_senha) < 6:
            return jsonify(error='A nova senha deve ter pelo menos 6 caracteres'), 422
        novo_hash = bcrypt.hashpw(nova_senha.encode(), bcrypt.gensalt(12)).decode()
        current_app.config['ADMIN_PASSWORD_HASH'] = novo_hash
        env_updates['ADMIN_PASSWORD_HASH'] = novo_hash

    _update_env(env_updates)

    return jsonify(
        message='Perfil atualizado com sucesso',
        email=current_app.config['ADMIN_EMAIL'],
    ), 200
