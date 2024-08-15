#### Developed by Amir Khan, amir.khan@eclit.com #####

# Get the directory of the running script
$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Definition
Write-Host "Script directory: $scriptDirectory"

# Define the paths to the MSI, config.txt, proxy.txt, and custom script files
$msiFilePath = Join-Path -Path $scriptDirectory -ChildPath "zabbix_agent2-7.0.2-windows-amd64-openssl.msi"
$configTxtPath = Join-Path -Path $scriptDirectory -ChildPath "config.txt"
$proxyTxtPath = Join-Path -Path $scriptDirectory -ChildPath "proxy.txt"
$customConfigPath = Join-Path -Path $scriptDirectory -ChildPath "ListInstalledSoftware.ps1"
$PskPath = Join-Path -Path $scriptDirectory -ChildPath "secret.psk"

# Output the paths being used
Write-Host "MSI file path: $msiFilePath"
Write-Host "Config.txt path: $configTxtPath"
Write-Host "Proxy.txt path: $proxyTxtPath"
Write-Host "Custom config path: $customConfigPath"
Write-Host "PSK path: $PskPath"

# Check if the MSI file exists
if (-Not (Test-Path -Path $msiFilePath)) {
    Write-Host "MSI file not found: $msiFilePath"
    exit 1
}

# Fetch the hostname
$hostname = (Get-WmiObject -Class Win32_ComputerSystem).Name
Write-Host "Hostname: $hostname"

# Fetch the proxy name specific to this hostname from proxy.txt
if (-Not (Test-Path -Path $proxyTxtPath)) {
    Write-Host "proxy.txt file not found: $proxyTxtPath"
    exit 1
}

$proxy = Get-Content -Path $proxyTxtPath | ForEach-Object {
    if ($_ -imatch "^$hostname=") {
        $_.Split('=')[1].Trim()
    }
}

# Check if the proxy was correctly fetched
if (-not $proxy) {
    Write-Host "Proxy value for hostname $hostname not found in proxy.txt."
    exit 1
}

Write-Host "Proxy name fetched: $proxy"

# Install the Zabbix agent with SERVER and SERVERACTIVE parameters
Write-Host "Installing Zabbix agent..."
try {
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$msiFilePath`" SERVER=$proxy SERVERACTIVE=$proxy /qn /l*v `"$scriptDirectory\zabbix_agent_install.log`"" -Wait -ErrorAction Stop
    Write-Host "Zabbix agent installation command executed."
} catch {
    Write-Host "Failed to install Zabbix agent. Error: $_"
    exit 1
}

# Check if the installation log file was created
$logFilePath = Join-Path -Path $scriptDirectory -ChildPath "zabbix_agent_install.log"
if (Test-Path -Path $logFilePath) {
    Write-Host "Installation log file created: $logFilePath"
} else {
    Write-Host "Installation log file not created."
}

# Define the path to the Zabbix agent configuration file and installation directory
$configFilePath = "C:\Program Files\Zabbix Agent 2\zabbix_agent2.conf"
$zabbixAgentDir = "C:\Program Files\Zabbix Agent 2"

Write-Host "Configuration file path: $configFilePath"
Write-Host "Zabbix Agent installation directory: $zabbixAgentDir"

# Check if the config file exists
if (-Not (Test-Path -Path $configFilePath)) {
    Write-Host "Configuration file not found: $configFilePath"
    exit 1
}

# Read the parameters from the config.txt file
if (-Not (Test-Path -Path $configTxtPath)) {
    Write-Host "config.txt file not found: $configTxtPath"
    exit 1
}
$configParams = Get-Content -Path $configTxtPath
Write-Host "Config parameters from config.txt: $configParams"

# Update the configuration file
Write-Host "Updating configuration file..."
$configContent = Get-Content -Path $configFilePath

# Update or add Hostname and TLSPSKIdentity
$configContent = $configContent | ForEach-Object {
    if ($_ -match "Hostname=") {
        # Replace the Hostname line with the new hostname value
        "Hostname=$hostname"
    } elseif ($_ -match "TLSPSKIdentity=") {
        $keypsk = Get-Content -Path $PskPath -Raw
        "TLSPSKIdentity=$hostname$keypsk"
    } else {
        $_
    }
}

# Add Hostname if it does not exist
if (-not ($configContent -join "`n" | Select-String -Pattern "Hostname=")) {
    $configContent += "Hostname=$hostname"
}

# Add any additional parameters from config.txt
$configContent += $configParams

# Write the updated configuration back to the file
try {
    Set-Content -Path $configFilePath -Value $configContent -ErrorAction Stop
    Write-Host "Configuration file updated successfully."
} catch {
    Write-Host "Failed to update configuration file. Error: $_"
    exit 1
}

# Copy the custom script and PSK file to the Zabbix Agent 2 installation directory
try {
    Copy-Item -Path $customConfigPath -Destination $zabbixAgentDir -Force
    Write-Host "Custom config file copied to Zabbix Agent 2 directory."
    Copy-Item -Path $PskPath -Destination $zabbixAgentDir -Force
    Write-Host "PSK file copied to Zabbix Agent 2 directory."
} catch {
    Write-Host "Failed to copy files. Error: $_"
    exit 1
}

# Restart the Zabbix Agent 2 service
Write-Host "Restarting Zabbix Agent 2 service..."
try {
    Start-Sleep -Seconds 10  # Add a delay to ensure the service is ready for a restart
    Restart-Service -Name "Zabbix Agent 2" -ErrorAction Stop
    Write-Host "Zabbix Agent 2 service restarted successfully."
} catch {
    Write-Host "Failed to restart Zabbix Agent 2 service. Error: $_"
    exit 1
}

Write-Host "Zabbix Agent 2 installed, configured, and custom config copied successfully."
