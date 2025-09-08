@echo off
REM Script uvx global pour MCP
REM Utilise l'installation globale de uv

REM Chemin vers l'installation globale de uv
set UV_PATH=C:\Users\youcef cheriet\AppData\Local\Programs\Python\Python312\Scripts\uv.exe

REM Vérifier que uv existe
if not exist "%UV_PATH%" (
    echo Erreur: uv non trouve a %UV_PATH%
    echo Tentative d'utilisation de uv depuis PATH...
    uv tool run %*
    exit /b %ERRORLEVEL%
)

REM Exécuter uv tool run avec tous les arguments
"%UV_PATH%" tool run %*