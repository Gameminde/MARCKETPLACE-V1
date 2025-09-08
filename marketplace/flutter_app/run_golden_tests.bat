@echo off
setlocal enabledelayedexpansion

rem Golden Test Runner Script for Marketplace Flutter App (Windows)
rem This script helps manage golden tests execution and golden file updates

set UPDATE_GOLDENS=false
set RUN_ALL=false
set VERBOSE=false
set DEVICE_FILTER=
set THEME_FILTER=

rem Parse command line arguments
:parse_args
if "%~1"=="" goto :end_parse
if "%~1"=="-u" set UPDATE_GOLDENS=true
if "%~1"=="--update-goldens" set UPDATE_GOLDENS=true
if "%~1"=="-a" set RUN_ALL=true
if "%~1"=="--all" set RUN_ALL=true
if "%~1"=="-v" set VERBOSE=true
if "%~1"=="--verbose" set VERBOSE=true
if "%~1"=="-d" (
    shift
    set DEVICE_FILTER=%~1
)
if "%~1"=="--device" (
    shift
    set DEVICE_FILTER=%~1
)
if "%~1"=="-t" (
    shift
    set THEME_FILTER=%~1
)
if "%~1"=="--theme" (
    shift
    set THEME_FILTER=%~1
)
if "%~1"=="-h" goto :show_usage
if "%~1"=="--help" goto :show_usage
shift
goto :parse_args
:end_parse

rem Validate Flutter installation
flutter --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Flutter is not installed or not in PATH
    exit /b 1
)

rem Change to project directory
cd /d "%~dp0"

echo [INFO] Running golden tests from: %CD%

rem Prepare test command
set TEST_COMMAND=flutter test test/golden/golden_test.dart

rem Add update goldens flag if requested
if "%UPDATE_GOLDENS%"=="true" (
    set TEST_COMMAND=%TEST_COMMAND% --update-goldens
    echo [INFO] Updating golden files...
) else (
    echo [INFO] Running golden tests...
)

rem Add verbose flag if requested
if "%VERBOSE%"=="true" (
    set TEST_COMMAND=%TEST_COMMAND% --verbose
)

rem Add device filter if specified
if not "%DEVICE_FILTER%"=="" (
    set TEST_COMMAND=%TEST_COMMAND% --dart-define=DEVICE_FILTER=%DEVICE_FILTER%
    echo [INFO] Filtering by device: %DEVICE_FILTER%
)

rem Add theme filter if specified
if not "%THEME_FILTER%"=="" (
    set TEST_COMMAND=%TEST_COMMAND% --dart-define=THEME_FILTER=%THEME_FILTER%
    echo [INFO] Filtering by theme: %THEME_FILTER%
)

rem Clean previous test results
echo [INFO] Cleaning previous test results...
flutter clean >nul 2>&1

rem Get dependencies
echo [INFO] Getting dependencies...
flutter pub get >nul 2>&1

rem Create golden directories if they don't exist
if not exist "test\golden\goldens" mkdir "test\golden\goldens"
if not exist "test\golden\screenshots" mkdir "test\golden\screenshots"

rem Run the tests
echo [INFO] Executing: %TEST_COMMAND%

%TEST_COMMAND%

if errorlevel 1 (
    echo [ERROR] Golden tests failed!
    if "%UPDATE_GOLDENS%"=="false" (
        echo.
        echo [WARNING] If the UI changes are intentional, update the golden files:
        echo     %0 --update-goldens
        echo.
        echo [WARNING] Or run with verbose output to see detailed differences:
        echo     %0 --verbose
    )
    exit /b 1
) else (
    echo [SUCCESS] Golden tests completed successfully!
    
    if "%UPDATE_GOLDENS%"=="true" (
        echo [SUCCESS] Golden files have been updated.
        echo [WARNING] Please review the changes and commit them if they look correct.
        
        rem Show git status for golden files if git is available
        git status --porcelain test/golden/goldens/ >nul 2>&1
        if not errorlevel 1 (
            echo.
            echo [INFO] Git status for golden files:
            git status --porcelain test/golden/goldens/
        )
    )
)

rem Success message
echo.
echo [SUCCESS] All golden tests completed successfully!

if "%RUN_ALL%"=="true" (
    echo [INFO] Ran complete test suite including slow tests.
)

if not "%DEVICE_FILTER%%THEME_FILTER%"=="" (
    echo [WARNING] Ran filtered tests only. Run without filters for complete coverage.
)

goto :eof

:show_usage
echo Golden Test Runner for Marketplace Flutter App
echo.
echo Usage: %0 [OPTIONS]
echo.
echo OPTIONS:
echo     -u, --update-goldens    Update golden files (equivalent to --update-goldens)
echo     -a, --all              Run all golden tests including slow ones
echo     -v, --verbose          Verbose output
echo     -d, --device DEVICE    Filter by device (mobile, tablet, desktop)
echo     -t, --theme THEME      Filter by theme (light, dark)
echo     -h, --help             Show this help message
echo.
echo EXAMPLES:
echo     %0                          # Run golden tests
echo     %0 -u                       # Update golden files
echo     %0 -a                       # Run all tests including slow ones
echo     %0 -d mobile               # Run only mobile device tests
echo     %0 -t dark                 # Run only dark theme tests
echo     %0 -u -v                   # Update with verbose output
echo.
exit /b 0