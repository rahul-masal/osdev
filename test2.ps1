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

# Modify permissions for the registry keys to block users from changing settings
# Install the NTFSSecurity module to manipulate registry key permissions if necessary
Install-Module -Name NTFSSecurity -Force

# Lockdown registry keys to prevent users from changing settings
$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
$acl = Get-Acl $registryPath
$acl.SetAccessRuleProtection($true, $false) # Disable inheritance
$rule = New-Object System.Security.AccessControl.RegistryAccessRule ("Users", "ReadKey", "Allow")
$acl.AddAccessRule($rule)
Set-Acl -Path $registryPath -AclObject $acl

Write-Output "Network settings have been restricted and locked."

# ----- Apply Local Group Policies -----

# Function to set Local Group Policy using the built-in COM object
function Set-LocalGroupPolicy {
    param (
        [string]$policyPath,
        [string]$policyName,
        [string]$settingValue
    )

    $wmiPolicy = Get-WmiObject -Namespace "root\rsop\computer" -Class "RSOP_SecuritySettingBoolean" -ErrorAction SilentlyContinue
    $regPolFile = "$env:SystemRoot\System32\GroupPolicy\Machine\Registry.pol"

    # Set Policy via Registry modification for Local Group Policy
    if ($settingValue -eq "Enabled") {
        New-ItemProperty -Path $policyPath -Name $policyName -Value 1 -Force
    } elseif ($settingValue -eq "Disabled") {
        New-ItemProperty -Path $policyPath -Name $policyName -Value 0 -Force
    }
}

# Disable access to properties of a LAN connection (Local Group Policy)
$policyLAN = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Network"
Set-LocalGroupPolicy -policyPath $policyLAN -policyName "NoNetworkConnections" -settingValue "Enabled"

# Prohibit TCP/IP advanced configuration (Local Group Policy)
$policyTCPIP = "HKLM:\Software\Policies\Microsoft\Windows\Network Connections"
Set-LocalGroupPolicy -policyPath $policyTCPIP -policyName "NC_AllowNetSetup" -settingValue "Disabled"

Write-Output "Local Group Policy has been applied to restrict network settings."

# Restart the system to apply all settings
Restart-Computer -Force
