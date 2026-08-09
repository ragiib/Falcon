@echo off
setlocal enableextensions
cd /d "C:\falcon"
if not exist "logs" mkdir "logs"

set "LOGFILE=C:\falcon\logs\falcon_wake_startup.log"
echo [FALCON WAKE STARTUP WRAPPER] Starting Falcon Wake Service Wrapper at %DATE% %TIME% >> "%LOGFILE%"

set "PYTHON_EXE=C:\Program Files\Python311\python.exe"
if not exist "%PYTHON_EXE%" (
    set "PYTHON_EXE=python"
)

echo [FALCON WAKE STARTUP WRAPPER] Using Python: %PYTHON_EXE% >> "%LOGFILE%"
"%PYTHON_EXE%" "C:\falcon\scripts\falcon_wake_listener.py" >> "%LOGFILE%" 2>&1
