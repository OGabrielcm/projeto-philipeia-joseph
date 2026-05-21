import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    JWT_SECRET       = os.environ['JWT_SECRET']
    JWT_EXPIRY_HOURS = int(os.getenv('JWT_EXPIRY_HOURS', '8'))

    ADMIN_EMAIL         = os.environ['ADMIN_EMAIL']
    ADMIN_PASSWORD_HASH = os.environ['ADMIN_PASSWORD_HASH']

    DB_SERVER   = os.environ['DB_SERVER']
    DB_NAME     = os.environ['DB_NAME']
    DB_USER     = os.environ['DB_USER']
    DB_PASSWORD = os.environ['DB_PASSWORD']
    DB_DRIVER   = os.getenv('DB_DRIVER', 'ODBC Driver 17 for SQL Server')

    SMTP_HOST        = os.getenv('SMTP_HOST', 'smtp.gmail.com')
    SMTP_PORT        = int(os.getenv('SMTP_PORT', '587'))
    SMTP_USER        = os.environ['SMTP_USER']
    SMTP_APP_PASSWORD = os.environ['SMTP_APP_PASSWORD']
    EMAIL_FROM_NAME  = os.getenv('EMAIL_FROM_NAME', 'Philipeia Indústria')

    def validate(self):
        """Falha rápida na inicialização se variável obrigatória estiver ausente."""
        required = [
            'JWT_SECRET', 'ADMIN_EMAIL', 'ADMIN_PASSWORD_HASH',
            'DB_SERVER', 'DB_NAME', 'DB_USER', 'DB_PASSWORD',
            'SMTP_USER', 'SMTP_APP_PASSWORD',
        ]
        missing = [k for k in required if not os.getenv(k)]
        if missing:
            raise RuntimeError(f"Variáveis de ambiente ausentes: {', '.join(missing)}")
