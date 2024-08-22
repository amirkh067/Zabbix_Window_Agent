# Define the service name for Zabbix Agent 2
$serviceName = "Zabbix Agent 2"

# Check if the Zabbix Agent 2 service exists
$service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

if ($null -ne $service) {
    # Check if the service is running
    if ($service.Status -eq 'Running') {
        Write-Host "Stopping Zabbix Agent 2 service..."
        Stop-Service -Name $serviceName -Force
        Write-Host "Zabbix Agent 2 service stopped."

        Write-Host "Starting Zabbix Agent 2 service..."
        Start-Service -Name $serviceName
        Write-Host "Zabbix Agent 2 service started."
    } else {
        Write-Host "Zabbix Agent 2 service is not running, starting the service..."
        Start-Service -Name $serviceName
        Write-Host "Zabbix Agent 2 service started."
    }
} else {
    Write-Host "Zabbix Agent 2 service not found."
}