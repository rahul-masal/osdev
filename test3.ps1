# Function to Set DNS for a network adapter
function Set-DnsServers {
    param (
        [string]$adapterName,
        [string[]]$dnsServers
    )
    try {
        $adapter = Get-NetAdapter | Where-Object { $_.Name -eq $adapterName }
        if ($adapter) {
            Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ServerAddresses $dnsServers
            Write-Host "DNS for $adapterName set to $($dnsServers -join ', ')"
        } else {
            Write-Host "Adapter $adapterName not found."
        }
    } catch {
        Write-Host "Error setting DNS for $adapterName: $_"
    }
}

# Set DNS for Ethernet and Wi-Fi
Set-DnsServers -adapterName "Ethernet" -dnsServers @("8.8.8.8", "8.8.4.4")
Set-DnsServers -adapterName "Wi-Fi" -dnsServers @("8.8.8.8", "8.8.4.4")

# Function to Restrict Network Settings via Registry
function RestrictNetworkSettings {
    $regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Network Connections"
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force
    }

    # Prohibit access to properties of a LAN connection
    Set-ItemProperty -Path $regPath -Name "NC_LanChangeProperties" -Value 1 -Force
    # Prohibit users from modifying the network bridge
    Set-ItemProperty -Path $regPath -Name "NC_AllowNetBridge_NLA" -Value 0 -Force
    
    Write-Host "Network settings restricted via registry."
}

# Apply registry restrictions
RestrictNetworkSettings

# Optionally, restart the computer to apply group policy changes (comment this out if not needed)
# Restart-Computer -Force
