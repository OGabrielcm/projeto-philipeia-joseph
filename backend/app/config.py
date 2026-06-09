import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    JWT_SECRET       = os.environ['JWT_SECRET']
    JWT_EXPIRY_HOURS = int(os.getenv('JWT_EXPIRY_HOURS', '8'))

    ADMIN_EMAIL         = os.environ['ADMIN_EMAIL']
    ADMIN_PASSWORD_HASH = os.environ['ADMIN_PASSWORD_HASH']

    # Banco — Trusted_Connection (Windows Auth) se DB_USER não informado
    DB_SERVER   = os.getenv('DB_SERVER',   r'.\SQLEXPRESS')
    DB_NAME     = os.getenv('DB_NAME',     'philipeia')
    DB_DRIVER   = os.getenv('DB_DRIVER',   'SQL Server')
    DB_USER     = os.getenv('DB_USER',     '')
    DB_PASSWORD = os.getenv('DB_PASSWORD', '')

    SMTP_HOST         = os.getenv('SMTP_HOST',         'smtp.gmail.com')
    SMTP_PORT         = int(os.getenv('SMTP_PORT',     '587'))
    SMTP_USER         = os.getenv('SMTP_USER',         '')
    SMTP_APP_PASSWORD = os.getenv('SMTP_APP_PASSWORD', '')
    EMAIL_FROM_NAME   = os.getenv('EMAIL_FROM_NAME',   'Philipeia Indústria')

    def validate(self):
        required = ['JWT_SECRET', 'ADMIN_EMAIL', 'ADMIN_PASSWORD_HASH']
        missing = [k for k in required if not os.getenv(k)]
        if missing:
            raise RuntimeError(f"Variáveis de ambiente ausentes: {', '.join(missing)}")
