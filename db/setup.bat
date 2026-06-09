@echo off
setlocal
title Philipeia — Setup do Banco de Dados

set SQLCMD="C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\SQLCMD.EXE"
set SERVER=.\SQLEXPRESS
set SCRIPT_DIR=%~dp0

echo.
echo  ============================================
echo   Philipeia — Setup automatico do banco
echo   Instancia: %SERVER%
echo  ============================================
echo.

REM Tenta localizar sqlcmd no PATH primeiro
where sqlcmd >nul 2>&1
if %errorlevel% == 0 (
    set SQLCMD=sqlcmd
)

echo [1/2] Criando schema (tabelas, indices, constraints)...
%SQLCMD% -S "%SERVER%" -E -f 65001 -i "%SCRIPT_DIR%01_schema.sql"
if %errorlevel% neq 0 (
    echo.
    echo ERRO: falha ao executar 01_schema.sql.
    echo Verifique se o SQL Server Express esta rodando e tente novamente.
    pause
    exit /b 1
)

echo.
echo [2/2] Inserindo dados iniciais do catalogo...
%SQLCMD% -S "%SERVER%" -E -f 65001 -i "%SCRIPT_DIR%02_seed.sql"
if %errorlevel% neq 0 (
    echo.
    echo ERRO: falha ao executar 02_seed.sql.
    pause
    exit /b 1
)

echo.
echo  ============================================
echo   Banco philipeia configurado com sucesso!
echo   Proximo passo: configure backend\.env
echo   (veja db\README.md para instrucoes)
echo  ============================================
echo.
pause
