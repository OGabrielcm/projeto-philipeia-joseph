import logging
import logging.config
from flask import Flask, jsonify
from flask_cors import CORS
from .config import Config

_LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'default': {
            'format': '%(asctime)s [%(levelname)s] %(name)s: %(message)s',
            'datefmt': '%Y-%m-%d %H:%M:%S',
        },
    },
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
            'formatter': 'default',
        },
    },
    'root': {
        'level': 'INFO',
        'handlers': ['console'],
    },
    'loggers': {
        'app.pedidos.email': {'level': 'INFO'},
        'werkzeug': {'level': 'WARNING'},
    },
}


def create_app() -> Flask:
    logging.config.dictConfig(_LOGGING)
    log = logging.getLogger(__name__)

    app = Flask(__name__)
    CORS(app, resources={r'/api/*': {'origins': '*'}})

    config = Config()
    config.validate()
    app.config.from_object(config)

    from .auth.routes import auth_bp
    from .clientes.routes import clientes_bp
    from .catalogo.routes import catalogo_bp
    from .pedidos.routes import pedidos_bp

    app.register_blueprint(auth_bp,     url_prefix='/api/v1/auth')
    app.register_blueprint(clientes_bp, url_prefix='/api/v1/clientes')
    app.register_blueprint(catalogo_bp, url_prefix='/api/v1/catalogo')
    app.register_blueprint(pedidos_bp,  url_prefix='/api/v1/pedidos')

    _register_error_handlers(app)

    log.info('Philipeia API iniciada')
    return app


def _register_error_handlers(app: Flask) -> None:
    log = logging.getLogger(__name__)

    @app.errorhandler(404)
    def not_found(_):
        return jsonify(error='Recurso não encontrado'), 404

    @app.errorhandler(405)
    def method_not_allowed(_):
        return jsonify(error='Método não permitido'), 405

    @app.errorhandler(Exception)
    def unhandled(exc):
        log.exception('Erro não tratado: %s', exc)
        return jsonify(error='Erro interno do servidor'), 500
