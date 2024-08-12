#### Developed by Amir Khan, amir.khan@eclit.com #####

# Get the directory of the running script
$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Definition
Write-Host "Script directory: $scriptDirectory"

# Define the paths to the MSI, config.txt, and proxy.txt files
$msiFilePath = Join-Path -Path $scriptDirectory -ChildPath "zabbix_agent2-6.4.13-windows-amd64-openssl.msi"
$configTxtPath = Join-Path -Path $scriptDirectory -ChildPath "config.txt"
$proxyTxtPath = Join-Path -Path $scriptDirectory -ChildPath "proxy.txt"

# Output the paths being used
Write-Host "MSI file path: $msiFilePath"
Write-Host "Config.txt path: $configTxtPath"
Write-Host "Proxy.txt path: $proxyTxtPath"

# Check if the MSI file exists
if (-Not (Test-Path -Path $msiFilePath)) {
    Write-Host "MSI file not found: $msiFilePath"
    exit 1
}

# Fetch the proxy value from proxy.txt
if (-Not (Test-Path -Path $proxyTxtPath)) {
    Write-Host "proxy.txt file not found: $proxyTxtPath"
    exit 1
}
$proxy = Get-Content -Path $proxyTxtPath | Select-Object -First 1
Write-Host "Proxy value: $proxy"

# Install the Zabbix agent with SERVER and SERVERACTIVE parameters
Write-Host "Installing Zabbix agent..."
try {
    Start-Process -FilePath msiexec.exe -ArgumentList "/i `"$msiFilePath`" SERVER=$proxy SERVERACTIVE=$proxy /qn /l*v `"$scriptDirectory\zabbix_agent_install.log`"" -Wait -ErrorAction Stop
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

# Define the path to the Zabbix agent configuration file
$configFilePath = "C:\Program Files\Zabbix Agent 2\zabbix_agent2.conf"
Write-Host "Configuration file path: $configFilePath"

# Check if the config file exists
if (-Not (Test-Path -Path $configFilePath)) {
    Write-Host "Configuration file not found: $configFilePath"
    exit 1
}

# Fetch the hostname
$hostname = (Get-WmiObject -Class Win32_ComputerSystem).Name
Write-Host "Hostname: $hostname"

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

# Update or add Hostname
$configContent = $configContent | ForEach-Object {
    if ($_ -match "Hostname=") {
        "Hostname=$hostname"
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

# Restart the Zabbix Agent 2 service
Write-Host "Restarting Zabbix Agent 2 service..."
try {
    Restart-Service -Name "Zabbix Agent 2" -ErrorAction Stop
    Write-Host "Zabbix Agent 2 service restarted successfully."
} catch {
    Write-Host "Failed to restart Zabbix Agent 2 service. Error: $_"
    exit 1
}

Write-Host "Zabbix Agent 2 installed and configured successfully."