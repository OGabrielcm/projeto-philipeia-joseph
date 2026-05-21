from functools import wraps
from flask import request, jsonify, current_app
import jwt


def require_auth(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = request.headers.get('Authorization', '').removeprefix('Bearer ').strip()
        if not token:
            return jsonify(error='Token ausente'), 401
        try:
            jwt.decode(token, current_app.config['JWT_SECRET'], algorithms=['HS256'])
        except jwt.ExpiredSignatureError:
            return jsonify(error='Sessão expirada'), 401
        except jwt.InvalidTokenError:
            return jsonify(error='Token inválido'), 401
        return f(*args, **kwargs)
    return decorated
