# Define DNS servers
$dnsServers = "8.8.8.8", "8.8.4.4"

# Function to set DNS for a specific adapter
function Set-DnsForAdapter {
    param (
        [string]$adapterName
    )
    
    $adapter = Get-NetAdapter -Name $adapterName -ErrorAction SilentlyContinue
    if ($adapter) {
        Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses $dnsServers
        Write-Output "DNS settings updated for $adapterName"
    } else {
        Write-Output "Adapter $adapterName not found"
    }
}

# Set DNS for Wi-Fi adapter
Set-DnsForAdapter -adapterName "*Wi-Fi*"

# Set DNS for Ethernet adapter
Set-DnsForAdapter -adapterName "*Ethernet*"

# Disable access to network settings via Control Panel
$regPathNetwork = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Network"
$regPathNC = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Network Connections"

# Ensure registry paths exist
if (-not (Test-Path $regPathNetwork)) {
    New-Item -Path $regPathNetwork -Force
}
if (-not (Test-Path $regPathNC)) {
    New-Item -Path $regPathNC -Force
}

# Apply registry settings to disable access to network settings
Set-ItemProperty -Path $regPathNetwork -Name "NoNetworkConnections" -Value 1 -Force
Set-ItemProperty -Path $regPathNC -Name "NC_AllowNetSetup" -Value 0 -Force

Write-Output "Network settings have been restricted."
