@echo off
REM #### Developed by Amir Khan, amir.khan@eclit.com ####

REM Get the current script directory
set scriptDirectory=%~dp0

REM Define file paths
set msiFilePath=%scriptDirectory%zabbix_agent2-7.0.2-windows-amd64-openssl.msi
set configTxtPath=%scriptDirectory%config.txt
set proxyTxtPath=%scriptDirectory%proxy.txt
set customConfigPath=%scriptDirectory%ListInstalledSoftware.ps1
set PskPath=%scriptDirectory%secret.psk
set logFilePath=%scriptDirectory%zabbix_agent_install.log
set configFilePath=C:\Program Files\Zabbix Agent 2\zabbix_agent2.conf
set zabbixAgentDir=C:\Program Files\Zabbix Agent 2

REM Ensure necessary files are available
if not exist "%msiFilePath%" (
    echo MSI file not found: %msiFilePath%
    exit /b 1
)

if not exist "%proxyTxtPath%" (
    echo proxy.txt file not found: %proxyTxtPath%
    exit /b 1
)

REM Get the hostname
for /f "tokens=2 delims==" %%a in ('wmic computersystem get name /value') do set hostname=%%a

echo Hostname: %hostname%

REM Fetch proxy from proxy.txt
for /f "tokens=2 delims==" %%a in ('findstr /i "^%hostname%=" "%proxyTxtPath%"') do set proxy=%%a

if "%proxy%"=="" (
    echo Proxy value for hostname %hostname% not found in proxy.txt.
    exit /b 1
)

echo Proxy name fetched: %proxy%

REM Install the Zabbix agent
echo Installing Zabbix agent...
msiexec /i "%msiFilePath%" SERVER=%proxy% SERVERACTIVE=%proxy% /qn /l*v "%logFilePath%"
if %errorlevel% neq 0 (
    echo Zabbix agent installation failed.
    exit /b 1
)

REM Check if the log file was created
if exist "%logFilePath%" (
    echo Installation log file created: %logFilePath%
) else (
    echo Installation log file not created.
)

REM Ensure the config file exists
if not exist "%configFilePath%" (
    echo Configuration file not found: %configFilePath%
    exit /b 1
)

REM Read parameters from config.txt
if not exist "%configTxtPath%" (
    echo config.txt file not found: %configTxtPath%
    exit /b 1
)

REM Append config.txt parameters to the configuration file
echo Updating configuration file...
for /f "delims=" %%a in ('type "%configTxtPath%"') do (
    echo %%a>> "%configFilePath%"
)

REM Copy custom files to the Zabbix Agent installation directory
copy /y "%customConfigPath%" "%zabbixAgentDir%"
if %errorlevel% neq 0 (
    echo Failed to copy custom config file.
    exit /b 1
)

copy /y "%PskPath%" "%zabbixAgentDir%"
if %errorlevel% neq 0 (
    echo Failed to copy PSK file.
    exit /b 1
)

REM Restart Zabbix Agent service
echo Restarting Zabbix Agent 2 service...
net stop "Zabbix Agent 2"
net start "Zabbix Agent 2"
if %errorlevel% neq 0 (
    echo Failed to restart Zabbix Agent 2 service.
    exit /b 1
)

echo Zabbix Agent 2 installed, configured, and custom config copied successfully.
exit /b 0
