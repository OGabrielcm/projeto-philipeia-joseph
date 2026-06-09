import smtplib
import logging
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

log = logging.getLogger(__name__)


def send_recovery_email(email: str, code: str, config: object) -> None:
    try:
        msg = MIMEMultipart('alternative')
        msg['Subject'] = 'Recuperação de Senha — Philipeia'
        msg['From']    = f"{config['EMAIL_FROM_NAME']} <{config['SMTP_USER']}>"
        msg['To']      = email

        html = f"""
<!DOCTYPE html>
<html lang="pt-BR">
<head><meta charset="utf-8"/></head>
<body style="margin:0;padding:0;background:#16181B;font-family:Arial,sans-serif;color:#B5B9C0">
  <table width="100%" cellpadding="0" cellspacing="0">
    <tr><td align="center" style="padding:32px 16px">
      <table width="480" cellpadding="0" cellspacing="0"
             style="background:#1F2125;border-radius:8px;overflow:hidden">
        <tr><td style="background:#FFD300;padding:24px 32px">
          <h1 style="margin:0;color:#16181B;font-size:20px">Philipeia Indústria</h1>
          <p style="margin:4px 0 0;color:#16181B;font-size:12px">Recuperação de Senha</p>
        </td></tr>
        <tr><td style="padding:32px">
          <p>Recebemos uma solicitação para recuperar a senha desta conta.</p>
          <p>Use o código abaixo para redefinir sua senha:</p>
          <div style="font-size:32px;font-weight:bold;color:#FFFFFF;letter-spacing:8px;
                      background:#16181B;padding:16px;border-radius:8px;
                      text-align:center;margin:24px 0">{code}</div>
          <p style="font-size:12px;color:#7A7E85">
            Este código expira em 30 minutos.<br>
            Se você não solicitou a recuperação, ignore este e-mail.
          </p>
        </td></tr>
        <tr><td style="background:#16181B;padding:16px 32px;text-align:center">
          <p style="margin:0;font-size:11px;color:#7A7E85">
            Philipeia Indústria — Bairro Renascer, Cabedelo/PB
          </p>
        </td></tr>
      </table>
    </td></tr>
  </table>
</body>
</html>
"""
        msg.attach(MIMEText(html, 'html', 'utf-8'))

        with smtplib.SMTP(config['SMTP_HOST'], int(config['SMTP_PORT'])) as server:
            server.starttls()
            server.login(config['SMTP_USER'], config['SMTP_APP_PASSWORD'])
            server.sendmail(config['SMTP_USER'], email, msg.as_string())

        log.info('E-mail de recuperação enviado para %s', email)
    except Exception as exc:
        log.error('Falha ao enviar e-mail de recuperação para %s: %s', email, exc)
