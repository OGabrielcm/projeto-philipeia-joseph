import smtplib
import os
import logging
from datetime import datetime
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

log = logging.getLogger(__name__)


def send_order_confirmation(order: dict, itens: list) -> None:
    """Envia e-mail de confirmação ao cliente após criação do pedido.

    Falha silenciosa: SMTP indisponível ou cliente sem e-mail não cancela o pedido.
    """
    email_destino = order.get('customer_email')
    if not email_destino:
        return

    try:
        msg = MIMEMultipart('alternative')
        msg['Subject'] = f"Confirmação de Pedido {order['numero']} — Philipeia"
        msg['From']    = f"{os.environ['EMAIL_FROM_NAME']} <{os.environ['SMTP_USER']}>"
        msg['To']      = email_destino

        msg.attach(MIMEText(_build_html(order, itens), 'html', 'utf-8'))

        with smtplib.SMTP(os.environ['SMTP_HOST'], int(os.environ['SMTP_PORT'])) as server:
            server.starttls()
            server.login(os.environ['SMTP_USER'], os.environ['SMTP_APP_PASSWORD'])
            server.sendmail(os.environ['SMTP_USER'], email_destino, msg.as_string())

        log.info('E-mail enviado para %s (pedido %s)', email_destino, order['numero'])

    except Exception as exc:
        log.error('Falha ao enviar e-mail para %s: %s', email_destino, exc)


def _build_html(order: dict, itens: list) -> str:
    data_evento = _fmt_date(order['data_evento'])
    hora_inicio = order['hora_inicio'][:5]

    itens_rows = ''.join(
        f"<tr>"
        f"<td style='padding:6px 12px;border-bottom:1px solid #3A3D42'>{i['descricao']}</td>"
        f"<td style='padding:6px 12px;border-bottom:1px solid #3A3D42;text-align:center'>{i['quantidade']}</td>"
        f"<td style='padding:6px 12px;border-bottom:1px solid #3A3D42;text-align:right'>"
        f"R$ {float(i['preco_unitario']):.2f}</td>"
        f"<td style='padding:6px 12px;border-bottom:1px solid #3A3D42;text-align:right'>"
        f"R$ {i['quantidade'] * float(i['preco_unitario']):.2f}</td>"
        f"</tr>"
        for i in itens
    )

    endereco = (
        f"{order['endereco_logradouro']}, {order['endereco_numero']}"
        + (f", {order['endereco_complemento']}" if order.get('endereco_complemento') else '')
        + f" — {order['endereco_bairro']}, {order['endereco_cidade']}/{order['endereco_estado']}"
    )

    return f"""
<!DOCTYPE html>
<html lang="pt-BR">
<head><meta charset="utf-8"/></head>
<body style="margin:0;padding:0;background:#16181B;font-family:Arial,sans-serif;color:#B5B9C0">
  <table width="100%" cellpadding="0" cellspacing="0">
    <tr><td align="center" style="padding:32px 16px">
      <table width="600" cellpadding="0" cellspacing="0"
             style="background:#1F2125;border-radius:8px;overflow:hidden">

        <!-- Header -->
        <tr><td style="background:#FFD300;padding:24px 32px">
          <h1 style="margin:0;color:#16181B;font-size:22px">Philipeia Indústria</h1>
          <p style="margin:4px 0 0;color:#16181B;font-size:13px">Gestão de Pedidos</p>
        </td></tr>

        <!-- Body -->
        <tr><td style="padding:32px">
          <h2 style="margin:0 0 8px;color:#FFFFFF;font-size:18px">
            Pedido {order['numero']} registrado!
          </h2>
          <p style="margin:0 0 24px">
            Olá, <strong style="color:#FFFFFF">{order['customer_nome']}</strong>.
            Seu pedido foi registrado com sucesso.
          </p>

          <h3 style="color:#FFD300;font-size:13px;margin:0 0 12px;text-transform:uppercase;letter-spacing:.5px">
            Detalhes do evento
          </h3>
          <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:24px">
            <tr>
              <td width="40%" style="padding:4px 0;color:#7A7E85;font-size:12px">Data</td>
              <td style="padding:4px 0;color:#B5B9C0">{data_evento} às {hora_inicio}</td>
            </tr>
            <tr>
              <td style="padding:4px 0;color:#7A7E85;font-size:12px">Endereço</td>
              <td style="padding:4px 0;color:#B5B9C0">{endereco}</td>
            </tr>
          </table>

          <h3 style="color:#FFD300;font-size:13px;margin:0 0 12px;text-transform:uppercase;letter-spacing:.5px">
            Itens do pedido
          </h3>
          <table width="100%" cellpadding="0" cellspacing="0"
                 style="border-collapse:collapse;margin-bottom:24px">
            <thead>
              <tr style="background:#16181B">
                <th style="padding:8px 12px;text-align:left;color:#7A7E85;font-size:12px">Item</th>
                <th style="padding:8px 12px;text-align:center;color:#7A7E85;font-size:12px">Qtd</th>
                <th style="padding:8px 12px;text-align:right;color:#7A7E85;font-size:12px">Unit.</th>
                <th style="padding:8px 12px;text-align:right;color:#7A7E85;font-size:12px">Total</th>
              </tr>
            </thead>
            <tbody>{itens_rows}</tbody>
          </table>

          <!-- Totais -->
          <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:32px">
            <tr>
              <td style="padding:4px 0;color:#7A7E85">Subtotal</td>
              <td style="padding:4px 0;text-align:right;color:#B5B9C0">
                R$ {float(order['subtotal']):.2f}</td>
            </tr>
            <tr>
              <td style="padding:4px 0;color:#7A7E85">Taxa de instalação</td>
              <td style="padding:4px 0;text-align:right;color:#B5B9C0">
                R$ {float(order['taxa_instalacao']):.2f}</td>
            </tr>
            <tr>
              <td style="padding:4px 0;color:#7A7E85">Desconto</td>
              <td style="padding:4px 0;text-align:right;color:#B5B9C0">
                R$ {float(order['desconto']):.2f}</td>
            </tr>
            <tr style="border-top:1px solid #3A3D42">
              <td style="padding:12px 0 4px;color:#FFFFFF;font-weight:bold">Total</td>
              <td style="padding:12px 0 4px;text-align:right;color:#FFD300;font-weight:bold;font-size:16px">
                R$ {float(order['total']):.2f}</td>
            </tr>
          </table>

          <p style="font-size:12px;color:#7A7E85;margin:0">
            Em caso de dúvidas, entre em contato com a Philipeia Indústria.
          </p>
        </td></tr>

        <!-- Footer -->
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


def _fmt_date(iso: str) -> str:
    try:
        d = datetime.strptime(iso[:10], '%Y-%m-%d')
        return d.strftime('%d/%m/%Y')
    except ValueError:
        return iso
