<#==========================================================================
Script Name: SetRxDispatchQueues.ps1
Created on: 9 AUG 2019
Created by: Jase McCarty
Github: http://www.github.com/jasemccarty
Twitter: @jasemccarty
Website: http://www.jasemccarty.com
===========================================================================

.DESCRIPTION
This script sets Tcpip Rx Dispatch Queue Settings for Physical NICs

Syntax is:
SetRxDispatchQueue.ps1 -VIServer <vCenter/ESXiHost> -Queue <value> -ClusterName <ClusterName>

.Notes

#>

# Set our Parameters
[CmdletBinding()]Param(
  [Parameter(Mandatory=$True)]
  [string]$VIServer,

  [Parameter(Mandatory=$False)]
  [string]$ClusterName,

  [Parameter(Mandatory = $true)]
  [Int]$Queue

)
	
function SetRxDispatchQueue{
Param ([string]$ESXHost,[Int]$RxQueue)
				
				$RxQueueVal  = Get-AdvancedSetting -Entity $ESXHost -Name "Net.TcpipRxDispatchQueues"

				# Display the Host this is being performed on
				Write-Host "Host:" $ESXHost

				# If any of these are set to the opposite, toggle the setting
				If($RxQueueVal.value -ne $Queue){
					# Show that host is being updated
					Write-Host "On $ESXHost the TcpipRxDispatchQueue value is " -foregroundcolor red -backgroundcolor white
					$RxQueueVal | Set-AdvancedSetting -Value $Queue -Confirm:$false
					Write-Host "A reboot of host $ESXHost is required for the updates to take effect" -foregroundcolor white -backgroundcolor red 
				}  else {
					Write-Host "On $ESXHost the TcpipRxDispatchQueue value is already set to $Queue" -ForegroundColor green
					Write-Host "A reboot of host $ESXHost is not required as no updates have been made" -foregroundcolor green 
				}
				
				Write-Host " "

}

	
#Connect-VIServer $VIServer

# If the ClusterName variable is passed, it is expected that the VIServer used will be a vCenter Server
If ($ClusterName) {
				
	# Get the Cluster Name
	$Cluster = Get-Cluster -Name $ClusterName -ErrorAction SilentlyContinue
				
	# Display the Cluster
	Write-Host Cluster: $($Cluster.name)
			
	# Cycle through each ESXi Host in the cluster
	Foreach ($ESXHost in ($Cluster |Get-VMHost | Sort-Object "Name")){
		
		# Execute the funtion to get/set the TSO/LRO settings
		SetRxDispatchQueue -ESXHost $ESXHost -RxQueue $Queue
		
	}

} 
