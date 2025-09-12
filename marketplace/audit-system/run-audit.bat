@echo off
echo 🇩🇿 ALGERIA MARKETPLACE PHASE 2 COMPREHENSIVE AUDIT
echo ================================================
echo.
echo Banking-grade validation for 45 million users
echo.

cd /d "%~dp0"
npm run build
if %errorlevel% neq 0 (
    echo ❌ Build failed
    pause
    exit /b 1
)

echo.
echo 🚀 Starting comprehensive audit...
echo.

node dist/index.js full

echo.
echo 📊 Audit completed. Check the report above.
echo.
pause