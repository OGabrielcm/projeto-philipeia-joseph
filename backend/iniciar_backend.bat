@echo off
title Philipeia Backend
cd /d "%~dp0"
echo ==========================================
echo  Philipeia - Backend API
echo  http://localhost:5000
echo ==========================================
python wsgi.py
pause
