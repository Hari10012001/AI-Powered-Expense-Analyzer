@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Expense Analyzer - Start

set "NO_PAUSE=0"
set "NO_OPEN=0"
for %%A in (%*) do (
  if /I "%%~A"=="--no-pause" set "NO_PAUSE=1"
  if /I "%%~A"=="--no-open" set "NO_OPEN=1"
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

if not defined JAVA_HOME (
  echo [WARN] JAVA_HOME set panna better. Ippo system PATH Java use aagum.
)

set "STARTUP_BAT=%CATALINA_HOME%\bin\startup.bat"
if not exist "%STARTUP_BAT%" (
  echo [ERROR] startup.bat kidaikkala:
  echo   %STARTUP_BAT%
  if "%NO_PAUSE%"=="0" pause
  exit /b 1
)

call :prepareCatalinaBase
if errorlevel 1 (
  if "%NO_PAUSE%"=="0" pause
  exit /b 1
)

call :deployApp
if errorlevel 1 (
  if "%NO_PAUSE%"=="0" pause
  exit /b 1
)

echo [INFO] Starting Tomcat...
echo [INFO] CATALINA_HOME=%CATALINA_HOME%
echo [INFO] CATALINA_BASE=%CATALINA_BASE%
call "%STARTUP_BAT%"

set "APP_CTX=ExpenseAnalyzer"
set "APP_URL=http://localhost:8080/%APP_CTX%/login.jsp"
if "%NO_OPEN%"=="0" (
  echo [INFO] Opening %APP_URL%
  start "" "%APP_URL%"
)
echo [DONE] Server start command sent.
exit /b 0

:prepareCatalinaBase
if not exist "%CATALINA_BASE%\conf\server.xml" (
  echo [INFO] Initializing project local Tomcat base...
  if exist "%CATALINA_BASE%" rmdir /s /q "%CATALINA_BASE%"
  mkdir "%CATALINA_BASE%\conf" "%CATALINA_BASE%\logs" "%CATALINA_BASE%\temp" "%CATALINA_BASE%\webapps" "%CATALINA_BASE%\work" 2>nul
  xcopy "%CATALINA_HOME%\conf\*" "%CATALINA_BASE%\conf\" /E /I /Y >nul
  if not exist "%CATALINA_BASE%\conf\server.xml" (
    echo [ERROR] CATALINA_BASE initialize aagala.
    exit /b 1
  )
)
exit /b 0

:deployApp
set "APP_CTX=ExpenseAnalyzer"
set "APP_DIR=%CATALINA_BASE%\webapps\%APP_CTX%"
set "SRC_WEBAPP=%PROJECT_DIR%src\main\webapp"
set "SRC_JAVA=%PROJECT_DIR%src\main\java"
set "CLASSES_DIR=%APP_DIR%\WEB-INF\classes"
set "LIB_DIR=%APP_DIR%\WEB-INF\lib"
set "SERVLET_JAR=%CATALINA_HOME%\lib\servlet-api.jar"
set "ARGFILE=%TEMP%\expense_java_files_%RANDOM%.txt"

if not exist "%SRC_WEBAPP%" (
  echo [ERROR] Source webapp path missing:
  echo   %SRC_WEBAPP%
  exit /b 1
)

if exist "%APP_DIR%" rmdir /s /q "%APP_DIR%"
mkdir "%APP_DIR%" 2>nul
xcopy "%SRC_WEBAPP%\*" "%APP_DIR%\" /E /I /Y >nul
mkdir "%CLASSES_DIR%" 2>nul
mkdir "%LIB_DIR%" 2>nul

if exist "%SRC_WEBAPP%\WEB-INF\lib\*.jar" (
  copy /Y "%SRC_WEBAPP%\WEB-INF\lib\*.jar" "%LIB_DIR%\" >nul
)

where javac >nul 2>nul
if errorlevel 1 (
  echo [WARN] javac kidaikkala. class compile skip pannrom.
  exit /b 0
)

if not exist "%SERVLET_JAR%" (
  echo [WARN] servlet-api.jar kidaikkala. class compile skip pannrom.
  exit /b 0
)

if not exist "%SRC_JAVA%" (
  echo [WARN] Java source path kidaikkala. class compile skip pannrom.
  exit /b 0
)

del /f /q "%ARGFILE%" >nul 2>nul
for /r "%SRC_JAVA%" %%F in (*.java) do (
  set "SRC_FILE=%%~fF"
  set "SRC_FILE=!SRC_FILE:\=/!"
  echo "!SRC_FILE!">>"%ARGFILE%"
)

if not exist "%ARGFILE%" (
  echo [WARN] Java source files illa. class compile skip pannrom.
  exit /b 0
)

echo [INFO] Compiling Java classes...
javac -cp "%SERVLET_JAR%" -d "%CLASSES_DIR%" @"%ARGFILE%"
if errorlevel 1 (
  echo [ERROR] Java compile fail aayiduchu.
  del /f /q "%ARGFILE%" >nul 2>nul
  exit /b 1
)
del /f /q "%ARGFILE%" >nul 2>nul
echo [INFO] App deployed to %APP_DIR%
exit /b 0

:resolveTomcatHome
if defined CATALINA_HOME goto :eof
if defined TOMCAT_HOME (
  if exist "%TOMCAT_HOME%\bin\startup.bat" set "CATALINA_HOME=%TOMCAT_HOME%"
)
if defined CATALINA_HOME goto :eof

for /d %%D in ("%PF%\Apache Software Foundation\Tomcat 9.*") do (
  if exist "%%~fD\bin\startup.bat" (
    set "CATALINA_HOME=%%~fD"
    goto :eof
  )
)

for /d %%D in ("%PF%\Apache Tomcat 9.*") do (
  if exist "%%~fD\bin\startup.bat" (
    set "CATALINA_HOME=%%~fD"
    goto :eof
  )
)

for /d %%D in ("%PF%\TomCat\apache-tomcat*") do (
  if exist "%%~fD\bin\startup.bat" (
    set "CATALINA_HOME=%%~fD"
    goto :eof
  )
  for /d %%E in ("%%~fD\apache-tomcat*") do (
    if exist "%%~fE\bin\startup.bat" (
      set "CATALINA_HOME=%%~fE"
      goto :eof
    )
  )
)

goto :eof
