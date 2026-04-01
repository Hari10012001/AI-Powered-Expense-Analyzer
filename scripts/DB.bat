@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Expense Analyzer - DB Setup

set "NO_PAUSE=0"
for %%A in (%*) do (
  if /I "%%~A"=="--no-pause" set "NO_PAUSE=1"
)

for %%I in ("%~dp0..") do set "PROJECT_DIR=%%~fI\"
set "SCHEMA_FILE=%PROJECT_DIR%db\schema.sql"
set "PF=%ProgramFiles%"

if not exist "%SCHEMA_FILE%" (
  set "SCHEMA_FILE=%PROJECT_DIR%schema.sql"
)

if not exist "%SCHEMA_FILE%" (
  echo [ERROR] schema.sql kidaikkala:
  echo   %SCHEMA_FILE%
  if "%NO_PAUSE%"=="0" pause
  exit /b 1
)

call :resolveMysqlExe
if not defined MYSQL_EXE (
  echo [ERROR] mysql.exe kandupidikka mudiyala.
  echo.
  echo One-time fix options:
  echo 1^) MySQL bin PATH add pannunga
  echo 2^) allathu setx MYSQL_HOME "C:\Program Files\MySQL\MySQL Server 8.0"
  echo.
  if "%NO_PAUSE%"=="0" pause
  exit /b 1
)

set "MYSQL_HOST=localhost"
if defined EXPENSE_MYSQL_HOST set "MYSQL_HOST=%EXPENSE_MYSQL_HOST%"

set "MYSQL_PORT=3306"
if defined EXPENSE_MYSQL_PORT set "MYSQL_PORT=%EXPENSE_MYSQL_PORT%"

set "MYSQL_USER=root"
if defined EXPENSE_MYSQL_USER set "MYSQL_USER=%EXPENSE_MYSQL_USER%"

set "MYSQL_PASSWORD=root"
if defined EXPENSE_MYSQL_PASSWORD set "MYSQL_PASSWORD=%EXPENSE_MYSQL_PASSWORD%"

echo [INFO] MySQL executable: %MYSQL_EXE%
echo [INFO] Host: %MYSQL_HOST%
echo [INFO] Port: %MYSQL_PORT%
echo [INFO] User: %MYSQL_USER%
echo [INFO] Applying schema.sql...

"%MYSQL_EXE%" -h "%MYSQL_HOST%" -P %MYSQL_PORT% -u "%MYSQL_USER%" -p"%MYSQL_PASSWORD%" < "%SCHEMA_FILE%"
if errorlevel 1 (
  if "%NO_PAUSE%"=="1" (
    echo [ERROR] DB setup fail (no-pause mode). EXPENSE_MYSQL_USER / EXPENSE_MYSQL_PASSWORD set pannitu retry pannunga.
    exit /b 1
  )
  echo [WARN] Default credentials work aagala. Manual credential try pannalaam.
  set "INPUT_USER="
  set "INPUT_PASS="
  set /p INPUT_USER=MySQL username default root:
  if not defined INPUT_USER set "INPUT_USER=root"
  set /p INPUT_PASS=MySQL password empty na just Enter:
  if defined INPUT_PASS (
    "%MYSQL_EXE%" -h "%MYSQL_HOST%" -P %MYSQL_PORT% -u "%INPUT_USER%" -p"%INPUT_PASS%" < "%SCHEMA_FILE%"
  ) else (
    "%MYSQL_EXE%" -h "%MYSQL_HOST%" -P %MYSQL_PORT% -u "%INPUT_USER%" < "%SCHEMA_FILE%"
  )
  if errorlevel 1 (
    echo [ERROR] DB setup fail aayiduchu.
    echo.
    echo Check pannunga:
    echo - MySQL server run aagudha?
    echo - username/password correct-aa?
    echo - next time easy-ku env var set pannunga:
    echo     setx EXPENSE_MYSQL_USER "your_user"
    echo     setx EXPENSE_MYSQL_PASSWORD "your_password"
    echo.
    if "%NO_PAUSE%"=="0" pause
    exit /b 1
  )
)

echo [DONE] Database ready. (expense_db + tables + default admin user)
echo [DONE] Login:
echo   Email: admin@example.com
echo   Password: admin123
if "%NO_PAUSE%"=="0" pause
exit /b 0

:resolveMysqlExe
if defined MYSQL_HOME (
  if exist "%MYSQL_HOME%\bin\mysql.exe" (
    set "MYSQL_EXE=%MYSQL_HOME%\bin\mysql.exe"
    goto :eof
  )
)

for /f "delims=" %%I in ('where mysql 2^>nul') do (
  set "MYSQL_EXE=%%I"
  goto :eof
)

if exist "%PF%\MySQL\MySQL Server 8.0\bin\mysql.exe" (
  set "MYSQL_EXE=%PF%\MySQL\MySQL Server 8.0\bin\mysql.exe"
  goto :eof
)
if exist "%PF%\MySQL\MySQL Server 8.4\bin\mysql.exe" (
  set "MYSQL_EXE=%PF%\MySQL\MySQL Server 8.4\bin\mysql.exe"
  goto :eof
)
goto :eof
