#### Developed by Amir Khan, amir.khan@eclit.com #####

# Uninstall Zabbix agent using MSIEXEC
Write-Host "Uninstalling Zabbix agent..."
try {
    $product = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "Zabbix Agent*" }
    if ($product) {
        $product.Uninstall()
        Write-Host "Zabbix agent uninstalled successfully."
    } else {
        Write-Host "Zabbix agent not found."
    }
} catch {
    Write-Host "Failed to uninstall Zabbix agent. Error: $_"
    exit 1
}

# Define registry paths related to Zabbix agent
$registryPaths = @(
    "HKLM:\SOFTWARE\Zabbix Agent",
    "HKLM:\SOFTWARE\Wow6432Node\Zabbix Agent",
    "HKCU:\SOFTWARE\Zabbix Agent",
    "HKCU:\SOFTWARE\Wow6432Node\Zabbix Agent"
)

# Remove registry entries
Write-Host "Removing registry entries related to Zabbix agent..."
foreach ($path in $registryPaths) {
    if (Test-Path $path) {
        try {
            Remove-Item -Path $path -Recurse -Force
            Write-Host "Removed registry path: $path"
        } catch {
            Write-Host "Failed to remove registry path: $path. Error: $_"
        }
    } else {
        Write-Host "Registry path not found: $path"
    }
}

Write-Host "Zabbix agent uninstallation and cleanup completed."