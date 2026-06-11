# setup.ps1 — Configura o ambiente de desenvolvimento Philipeia
# Execucao: .\setup.ps1   (na raiz do projeto, como administrador se necessario)

$projectRoot = $PSScriptRoot

function Write-Step { param($msg) Write-Host "  >> $msg" -ForegroundColor Cyan }
function Write-Ok   { param($msg) Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn { param($msg) Write-Host "  [!]  $msg" -ForegroundColor Yellow }
function Write-Fail { param($msg) Write-Host "  [ERRO] $msg" -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Philipeia -- Setup de Desenvolvimento  " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# ── 1. Verificar Python ──────────────────────────────────────────────────────
Write-Step "Verificando Python..."
try {
    $pyVer = & python --version 2>&1
    Write-Ok "$pyVer encontrado."
} catch {
    Write-Fail "Python nao encontrado. Instale em https://python.org e tente novamente."
}

# ── 2. Instalar dependencias do backend ──────────────────────────────────────
Write-Step "Instalando dependencias do backend..."
& pip install -r "$projectRoot\backend\requirements.txt" --quiet
if ($LASTEXITCODE -ne 0) { Write-Fail "pip install falhou. Verifique sua conexao e tente novamente." }
Write-Ok "Dependencias instaladas."

# ── 3. Criar backend\.env ────────────────────────────────────────────────────
Write-Host ""
Write-Step "Configurando backend\.env..."

$envPath     = "$projectRoot\backend\.env"
$examplePath = "$projectRoot\backend\.env.example"

if (Test-Path $envPath) {
    Write-Ok "backend\.env ja existe -- nenhuma alteracao feita."
} else {
    # Gera JWT_SECRET aleatorio via Python (ja disponivel no passo anterior)
    $jwtSecret = & python -c "import secrets; print(secrets.token_hex(32))"
    if ($LASTEXITCODE -ne 0) { Write-Fail "Nao foi possivel gerar JWT_SECRET." }

    # Gera hash bcrypt da senha padrao de dev
    $adminHash = & python -c "import bcrypt; print(bcrypt.hashpw(b'philipeia123', bcrypt.gensalt(12)).decode())"
    if ($LASTEXITCODE -ne 0) { Write-Fail "Nao foi possivel gerar hash bcrypt." }

    # Substitui placeholders usando Replace literal (evita interpretacao de $ do hash bcrypt)
    $content = [System.IO.File]::ReadAllText($examplePath, [System.Text.Encoding]::UTF8)
    $content = $content.Replace("TROQUE_POR_UMA_STRING_ALEATORIA_LONGA", $jwtSecret)
    $content = $content.Replace("HASH_BCRYPT_DA_SENHA", $adminHash)
    $content = $content.Replace("admin@exemplo.com", "admin@philipeia.com")
    [System.IO.File]::WriteAllText($envPath, $content, [System.Text.Encoding]::UTF8)

    Write-Ok "backend\.env criado."
    Write-Ok "JWT_SECRET gerado automaticamente."
    Write-Ok "Admin de dev: admin@philipeia.com / philipeia123"
}

# ── 4. Setup do banco de dados ───────────────────────────────────────────────
Write-Host ""
Write-Step "Configurando banco de dados SQL Server Express..."

# Localiza sqlcmd
$sqlcmd = $null
$sqlcmdDefault = "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\SQLCMD.EXE"

if (Get-Command sqlcmd -ErrorAction SilentlyContinue) {
    $sqlcmd = "sqlcmd"
} elseif (Test-Path $sqlcmdDefault) {
    $sqlcmd = $sqlcmdDefault
} else {
    Write-Warn "sqlcmd nao encontrado no PATH nem no caminho padrao."
    Write-Warn "Instale o SQL Server Express ou execute db\setup.bat manualmente apos instalar."
    Write-Host ""
    Write-Host "  Setup parcial concluido (banco de dados pendente)." -ForegroundColor Yellow
    Write-Host "  Quando o SQL Server estiver instalado, execute: db\setup.bat" -ForegroundColor Yellow
    Write-Host ""
    exit 0
}

Write-Step "[1/2] Criando schema (tabelas, indices, constraints)..."
& $sqlcmd -S ".\SQLEXPRESS" -E -f 65001 -i "$projectRoot\db\01_schema.sql"
if ($LASTEXITCODE -ne 0) {
    Write-Fail "Falha ao executar 01_schema.sql. Verifique se o servico SQL Server (SQLEXPRESS) esta rodando (services.msc)."
}
Write-Ok "Schema criado."

Write-Step "[2/2] Inserindo dados iniciais do catalogo..."
& $sqlcmd -S ".\SQLEXPRESS" -E -f 65001 -i "$projectRoot\db\02_seed.sql"
if ($LASTEXITCODE -ne 0) { Write-Fail "Falha ao executar 02_seed.sql." }
Write-Ok "Dados iniciais inseridos."

# ── Resumo ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "  Setup concluido com sucesso!           " -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Credenciais de dev:" -ForegroundColor Yellow
Write-Host "    Email : admin@philipeia.com"
Write-Host "    Senha : philipeia123"
Write-Host ""
Write-Host "  Para iniciar o backend:"
Write-Host "    backend\iniciar_backend.bat"
Write-Host "    -- ou --"
Write-Host "    cd backend && python wsgi.py"
Write-Host ""
