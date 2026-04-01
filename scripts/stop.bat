@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Expense Analyzer - Stop

set "NO_PAUSE=0"
for %%A in (%*) do (
  if /I "%%~A"=="--no-pause" set "NO_PAUSE=1"
)

for %%I in ("%~dp0..") do set "PROJECT_DIR=%%~fI\"
set "CATALINA_BASE=%PROJECT_DIR%.tomcat-base"
set "PF=%ProgramFiles%"

call :resolveTomcatHome
if not defined CATALINA_HOME (
  echo [ERROR] Tomcat home kandupidikka mudiyala.
  echo.
  echo One-time fix:
  echo   setx CATALINA_HOME "C:\path\to\apache-tomcat-9.x"
  echo.
  if "%NO_PAUSE%"=="0" pause
  exit /b 1
)

if not exist "%CATALINA_BASE%\conf\server.xml" (
  set "CATALINA_BASE=%CATALINA_HOME%"
)

set "SHUTDOWN_BAT=%CATALINA_HOME%\bin\shutdown.bat"
if not exist "%SHUTDOWN_BAT%" (
  echo [ERROR] shutdown.bat kidaikkala:
  echo   %SHUTDOWN_BAT%
  if "%NO_PAUSE%"=="0" pause
  exit /b 1
)

echo [INFO] Stopping Tomcat...
echo [INFO] CATALINA_HOME=%CATALINA_HOME%
echo [INFO] CATALINA_BASE=%CATALINA_BASE%
call "%SHUTDOWN_BAT%"
echo [DONE] Stop command sent.
exit /b 0

:resolveTomcatHome
if defined CATALINA_HOME goto :eof
if defined TOMCAT_HOME (
  if exist "%TOMCAT_HOME%\bin\shutdown.bat" set "CATALINA_HOME=%TOMCAT_HOME%"
)
if defined CATALINA_HOME goto :eof

for /d %%D in ("%PF%\Apache Software Foundation\Tomcat 9.*") do (
  if exist "%%~fD\bin\shutdown.bat" (
    set "CATALINA_HOME=%%~fD"
    goto :eof
  )
)

for /d %%D in ("%PF%\Apache Tomcat 9.*") do (
  if exist "%%~fD\bin\shutdown.bat" (
    set "CATALINA_HOME=%%~fD"
    goto :eof
  )
)

for /d %%D in ("%PF%\TomCat\apache-tomcat*") do (
  if exist "%%~fD\bin\shutdown.bat" (
    set "CATALINA_HOME=%%~fD"
    goto :eof
  )
  for /d %%E in ("%%~fD\apache-tomcat*") do (
    if exist "%%~fE\bin\shutdown.bat" (
      set "CATALINA_HOME=%%~fE"
      goto :eof
    )
  )
)

goto :eof
