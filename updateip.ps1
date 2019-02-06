Function Set-VMGuestWindowsIp {
	<#
	.SYNOPSIS
	This function is a modification the Set-VMGuestNetworkInterface
	.DESCRIPTION
	This function is a modification the Set-VMGuestNetworkInterface
    .PARAMETER VM
	The VM 
	.PARAMETER Adapter
	The Name of the Windows Network Adapter
	.PARAMETER IP
	The IP of the Windows Network Adapter
	.PARAMETER Netmask
	The Netmask of the Windows Network Adapter
	.PARAMETER Gateway
	The Gateway of the Windows Network Adapter
	.PARAMETER GuestUser
	The Windows Guest User Account
	.PARAMETER GuestPass
	The Windows Guest User Account Password
	.PARAMETER SetDns
	True or False, set the DNS Address to the Hardcoded DNS
    
	.EXAMPLE
	PS C:\> UpdateIp.ps1 -VM VMNAME -Adapter "Local Network Connection" -GuestUser "admin" -GuestPass "pass" -SetDns $true
	.EXAMPLE 
	PS C:\> UpdateIp.ps1 -VM VMNAME -Adapter "Local Network Connection" -GuestUser "admin" -GuestPass "pass" -SetDns $true -IP "192.168.0.5" -Netmask "255.255.255.0" -Gateway "192.168.0.1"

	.NOTES
	Author                                    : Jase McCarty
	Version                                   : 0.1
	#>


    param(
        [Parameter(Mandatory=$true)][String]$VM,
        [Parameter(Mandatory=$true)][String]$Adapter,
        [Parameter(Mandatory=$false)][String]$IP,
        [Parameter(Mandatory=$false)][String]$Netmask,
        [Parameter(Mandatory=$false)][String]$Gateway,
        [Parameter(Mandatory=$true)][String]$GuestUser,
        [Parameter(Mandatory=$true)][String]$GuestPass,
        [Parameter(Mandatory=$true)][Boolean]$SetDns
    )
    
    # Windows netsh path
    $netshPath = "C:\Windows\System32\netsh.exe"
    # Set DNS Entries
    $pdns = "10.198.6.8"
    $sdns = "10.127.75.8"

    $netsh = "$netshPath interface ip set address $Adapter static $IP $NetMask $Gateway1"
    $netsh1 = "$netshPath interface ip set dnsserver $Adapter static $pdns"
    $netsh2 = "$netshPath interface ip set dnsserver $Adapter static $sdns Index=2"

    If ($IP) {
        # Set the IP Address
        Invoke-VMScript -VM (Get-VM -Name $VM) -GuestUser $GuestUser -GuestPassword $GuestPass -ScriptType bat -ScriptText $netsh 
    }   

    If ($SetDns -eq $true) {
        # Set the Primary DNS
        Invoke-VMScript -VM (Get-VM -Name $VM) -GuestUser $GuestUser -GuestPassword $GuestPass -ScriptType bat -ScriptText $netsh1 

        # Set the Secondary DNS
        Invoke-VMScript -VM (Get-VM -Name $VM) -GuestUser $GuestUser -GuestPassword $GuestPass -ScriptType bat -ScriptText $netsh2 
    }

}
 
# Windows Path
#$vmlist = Get-Content C:\Scripts\logs\serverlist.txt

# Path on my Mac
$vmList = Get-Content /Users/jase/PowerCLI/serverlist.txt

foreach ($VM in $vmlist) {
 
    Set-VMGuestWindowsDNS -VM $VM -GuestUser "admin" -GuestPass "pass" -SetDns $true
}
