# Philipeia — Database Setup

Banco de dados: **SQL Server Express 2022** | Instância padrão: `.\SQLEXPRESS`

---

## Pré-requisitos

| Software | Link |
|---|---|
| SQL Server Express 2022 | https://www.microsoft.com/pt-br/sql-server/sql-server-downloads |
| SSMS (opcional, para inspeção visual) | https://aka.ms/ssmsfullsetup |

A autenticação usada é **Windows Authentication** (Trusted Connection) — nenhuma senha de banco necessária.

---

## Execução rápida (um clique)

```
db\setup.bat
```

O script localiza o `sqlcmd` automaticamente e executa os dois arquivos na ordem correta.

---

## Execução manual via sqlcmd

```bat
REM Passo 1 — criar banco e tabelas
sqlcmd -S ".\SQLEXPRESS" -E -i db\01_schema.sql

REM Passo 2 — inserir catálogo inicial
sqlcmd -S ".\SQLEXPRESS" -E -i db\02_seed.sql
```

> **Flag `-E`** = Windows Authentication (sem usuário/senha).  
> Se o `sqlcmd` não estiver no PATH, use o caminho completo:  
> `"C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\SQLCMD.EXE"`

---

## Connection String

### Windows Authentication (padrão — recomendado)
```
Server=.\SQLEXPRESS;Database=philipeia;Trusted_Connection=yes;TrustServerCertificate=yes;
```

### SQL Server Authentication (opcional)
```
Server=.\SQLEXPRESS;Database=philipeia;User Id=SEU_USUARIO;Password=SUA_SENHA;TrustServerCertificate=yes;
```

### pyodbc (formato usado pelo backend Flask)
```python
# Windows Auth
"DRIVER={SQL Server};SERVER=.\SQLEXPRESS;DATABASE=philipeia;Trusted_Connection=yes;TrustServerCertificate=yes;"

# SQL Auth
"DRIVER={SQL Server};SERVER=.\SQLEXPRESS;DATABASE=philipeia;UID=usuario;PWD=senha;TrustServerCertificate=yes;"
```

---

## Ordem de execução dos arquivos

| Ordem | Arquivo | Conteúdo |
|---|---|---|
| 1° | `01_schema.sql` | `CREATE DATABASE`, tabelas, índices, constraints, colunas computadas |
| 2° | `02_seed.sql` | `INSERT` do catálogo inicial (estilos, volumes, combo de exemplo) |

Ambos os scripts são **idempotentes**: podem ser executados múltiplas vezes sem erros e sem duplicar dados.

---

## Estrutura do banco

```
philipeia
├── customers        — clientes (CPF, endereço, contatos)
├── styles           — tipos de produto (chopp / drink)
├── style_volumes    — volumes disponíveis por estilo + preço
├── combos           — pacotes com dois style_volumes
├── orders           — pedidos de eventos (numero = PED-XXXXX)
└── order_items      — itens individuais ou combos de cada pedido
```

### Diagrama de relacionamentos

```
customers ──< orders ──< order_items >── style_volumes >── styles
                                    └──< combos >── style_volumes (×2)
```

---

## Configurar o backend após criar o banco

Copie `backend/.env.example` para `backend/.env` e preencha os valores:

```bash
cp backend/.env.example backend/.env
```

Variáveis obrigatórias:

| Variável | Descrição |
|---|---|
| `JWT_SECRET` | String aleatória longa (ex: `openssl rand -hex 32`) |
| `ADMIN_EMAIL` | E-mail de login do administrador |
| `ADMIN_PASSWORD_HASH` | Hash bcrypt da senha (ver abaixo) |

**Gerar hash bcrypt da senha:**
```python
# No terminal Python (dentro de backend/)
import bcrypt
print(bcrypt.hashpw(b"SUA_SENHA", bcrypt.gensalt(12)).decode())
```

---

## Problemas comuns

| Erro | Solução |
|---|---|
| `sqlcmd: command not found` | Use o caminho completo do `SQLCMD.EXE` (ver acima) |
| `Cannot open database "philipeia"` | Execute `01_schema.sql` antes do `02_seed.sql` |
| `CREATE TABLE failed — SET options incorrect` | O `01_schema.sql` já inclui `SET QUOTED_IDENTIFIER ON` antes da tabela `orders` |
| `Login failed for user` | Use `-E` para Windows Auth ou configure `DB_USER`/`DB_PASSWORD` no `.env` |
| `Named Pipes Provider: Could not open...` | Inicie o serviço: `services.msc` → SQL Server (SQLEXPRESS) → Iniciar |
