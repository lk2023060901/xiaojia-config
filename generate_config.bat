@echo off
setlocal enabledelayedexpansion

rem Example: use Excel and schema in this folder,
rem and generate JSON configs via Luban into the output folder.

rem Script directory (so it can be run from anywhere)
set "SCRIPT_DIR=%~dp0"
pushd "%SCRIPT_DIR%"

set "WORKSPACE=%SCRIPT_DIR%.."

rem Allow net8.0 Luban to run on higher .NET runtimes (e.g. only .NET 10 installed)
set DOTNET_ROLL_FORWARD=Major

call :ensure_dotnet
if errorlevel 1 goto :end

call :find_luban
if "%LUBAN_DLL%"=="" (
    echo Luban.dll not found, try to build...
    call :build_luban
    call :find_luban
)

if "%LUBAN_DLL%"=="" (
    echo Luban.dll still not found after build.
    echo Please check your .NET environment and try to run:
    echo   %WORKSPACE%\Tools\luban\Tools\build-luban.bat
    goto :end
)

rem 输出目录
if not exist "output\json\server" (
    mkdir "output\json\server"
)
if not exist "output\bin\client" (
    mkdir "output\bin\client"
)
if not exist "output\code\cpp" (
    mkdir "output\code\cpp"
)
if not exist "output\code\go" (
    mkdir "output\code\go"
)

echo(
echo Generate client bin to output/bin/client ...
dotnet "%LUBAN_DLL%" ^
  -t client ^
  -d bin ^
  --conf "%SCRIPT_DIR%luban.conf" ^
  -x outputDataDir=output/bin/client

echo(
echo Generate server JSON to output/json/server ...
dotnet "%LUBAN_DLL%" ^
  -t server ^
  -d json ^
  --conf "%SCRIPT_DIR%luban.conf" ^
  -x outputDataDir=output/json/server

echo(
echo Generate C++ code to output/code/cpp ...
dotnet "%LUBAN_DLL%" ^
  -t all ^
  -c cpp-sharedptr-bin ^
  --conf "%SCRIPT_DIR%luban.conf" ^
  -x outputCodeDir=output/code/cpp

echo(
echo Generate Go code to output/code/go ...
dotnet "%LUBAN_DLL%" ^
  -t all ^
  -c go-json ^
  --conf "%SCRIPT_DIR%luban.conf" ^
  -x outputCodeDir=output/code/go ^
  -x lubanGoModule=demo/luban

echo(
echo Generate finished.
echo   Data:
echo     client (bin): %CD%\output\bin\client
echo     server (json): %CD%\output\json\server
echo   Code:
echo     C++: %CD%\output\code\cpp
echo     Go:  %CD%\output\code\go

:end
pause
popd
exit /b 0

:ensure_dotnet
rem Check if dotnet command exists
where dotnet >nul 2>nul
if errorlevel 1 (
    echo .NET SDK not found. Installing latest version...
    call :install_dotnet
    if errorlevel 1 exit /b 1
    goto :verify_dotnet
)

rem Get dotnet version
for /f "tokens=*" %%i in ('dotnet --version 2^>nul') do set "DOTNET_VERSION=%%i"
if "%DOTNET_VERSION%"=="" (
    echo Failed to get .NET version. Installing latest version...
    call :install_dotnet
    if errorlevel 1 exit /b 1
    goto :verify_dotnet
)

rem Extract major version (e.g., "8.0.100" -> "8")
for /f "tokens=1 delims=." %%a in ("%DOTNET_VERSION%") do set "DOTNET_MAJOR=%%a"

echo Found .NET version: %DOTNET_VERSION%

rem Check if version is less than 8
if %DOTNET_MAJOR% LSS 8 (
    echo .NET version is lower than 8.0. Installing latest version...
    call :install_dotnet
    if errorlevel 1 exit /b 1
    goto :verify_dotnet
)

echo .NET version is sufficient (8.0 or higher^).
exit /b 0

:verify_dotnet
rem Verify installation
where dotnet >nul 2>nul
if errorlevel 1 (
    echo .NET installation failed or not in PATH.
    echo Please manually install .NET SDK from: https://dotnet.microsoft.com/download
    exit /b 1
)

for /f "tokens=*" %%i in ('dotnet --version 2^>nul') do set "DOTNET_VERSION=%%i"
echo .NET installed successfully. Version: %DOTNET_VERSION%
exit /b 0

:install_dotnet
echo(
echo ========================================
echo Installing .NET SDK (latest version)
echo ========================================
echo(

rem Create temp directory for installer
set "TEMP_DIR=%TEMP%\dotnet_install_%RANDOM%"
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

rem Download dotnet-install.ps1 script
set "INSTALL_SCRIPT=%TEMP_DIR%\dotnet-install.ps1"
echo Downloading .NET installation script...

powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://dot.net/v1/dotnet-install.ps1' -OutFile '%INSTALL_SCRIPT%'}" >nul 2>nul

if not exist "%INSTALL_SCRIPT%" (
    echo Failed to download installation script.
    echo Please manually install .NET SDK from: https://dotnet.microsoft.com/download
    rmdir /s /q "%TEMP_DIR%" 2>nul
    exit /b 1
)

rem Run installation script (install latest LTS version)
echo Installing .NET SDK... (this may take a few minutes^)
powershell -ExecutionPolicy Bypass -File "%INSTALL_SCRIPT%" -Channel LTS -InstallDir "%ProgramFiles%\dotnet"

if errorlevel 1 (
    echo Installation failed. Trying user-level installation...
    powershell -ExecutionPolicy Bypass -File "%INSTALL_SCRIPT%" -Channel LTS
)

rem Clean up
rmdir /s /q "%TEMP_DIR%" 2>nul

rem Refresh PATH in current session
set "PATH=%ProgramFiles%\dotnet;%USERPROFILE%\.dotnet;%PATH%"

echo(
echo Installation completed.
exit /b 0

:find_luban
set "LUBAN_DLL="
if exist "%WORKSPACE%\Tools\Luban\Luban.dll" (
    set "LUBAN_DLL=%WORKSPACE%\Tools\Luban\Luban.dll"
    exit /b 0
)
if exist "%WORKSPACE%\Tools\luban\Tools\Luban\Luban.dll" (
    set "LUBAN_DLL=%WORKSPACE%\Tools\luban\Tools\Luban\Luban.dll"
    exit /b 0
)
exit /b 0

:build_luban
set "BUILD1=%WORKSPACE%\Tools\build-luban.bat"
set "BUILD2=%WORKSPACE%\Tools\luban\Tools\build-luban.bat"

if exist "%BUILD1%" (
    echo Run build script: %BUILD1%
    pushd "%WORKSPACE%\Tools"
    call "build-luban.bat"
    popd
    exit /b 0
)

if exist "%BUILD2%" (
    echo Run build script: %BUILD2%
    for %%D in ("%BUILD2%") do (
        pushd "%%~dpD"
        call "%%~nxD"
        popd
    )
    exit /b 0
)

echo No valid build script found: %BUILD1% or %BUILD2%.
exit /b 0
