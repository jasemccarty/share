

Function Modify-ScsiController {

	<#
	.SYNOPSIS
    Update the SCSI controller
    .DESCRIPTION
    Update the SCSI controller
    .PARAMETER VM
	The VM to have the controller changed
	.PARAMETER ControllerType
	The Type of Controller to change to  
	
	.EXAMPLE
	PS C:\> Update-ScsiController -WITNESSVM $VM

	.NOTES
	Author                                    : Jase McCarty
	Version                                   : 0.1
    Requires                                  : PowerCLI 6.5
	==========Tested Against Environment==========
	VMware vSphere Hypervisor(ESXi) Version   : 6.7
	VMware vCenter Server Version             : 6.7
	PowerCLI Version                          : PowerCLI 11.2
	PowerShell Core Version                   : 6.1
	#>
	
	# Set Parameters
	[CmdletBinding()]Param(
	[Parameter(Mandatory=$true)][String]$VM,
	[Parameter(Mandatory=$true)][ValidateSet('ParaVirtual','VirtualBusLogic','VirtualLsiLogic','VirtualLsiLogicSAS')][String]$Type
	)

	# Retrive the Current VM
    $CurrentVM = Get-VM -Name $VM

	# Retrieve the Current Controller Type
	$ScsiController = $CurrentVM | Get-ScsiController

	If ($ScsiController.Type -ne $Type) {
		
		# Get the current power state of the VM
		$VmPowerState = $CurrentVM.PowerState

		# Is the VM currently running?
		If ($VmPowerState -ne "PoweredOff") {

			# Does the VM have VMwareTools installed?
			If (($CurrentVM | Get-View).Guest.ToolsStatus -eq "toolsOk") {

				# Shutdown the current VM so the controller can be changed
				$CurrentVM | Shutdown-VMGuest -Confirm:$false
			} else {
				# Power the VM off hard
				$CurrentVM | Stop-VM -Confirm:$false
			}

			# Let's wait until the VM is powered off before attempting to make a change
			While ($CurrentVM.PowerState -ne "PoweredOff") {
				# WAIT JUST A SECOND
				Start-Sleep -S 1
				# Refresh the VM's variable to update the Power State
				$CurrentVM = Get-VM -Name $VM
			}
		}

		# Proceed 
		Write-Host "$CurrentVM is PoweredOff:" -ForegroundColor Yellow -NoNewline
		Write-Host "Proceeding"

		# Change the current type to the new type
		$ScsiController | Set-ScsiController -Type $Type -Confirm:$false | Out-Null

		# What was the original state of the VM?
		If ($VmPowerState -eq "PoweredOn") {
			# Start the VM
			Write-Host "$CurrentVM was previously powered on:" -ForegroundColor Yellow -NoNewline
			Write-Host "Powering On"
			Start-VM -VM $CurrentVM | Out-Null
		}

	} else {
		# No need to make a change
		Write-Host "$CurrentVM already has a Scsi Controller Type of $Type :" -ForegroundColor Green -NoNewline
		Write-Host "No need to proceed."
	}

}

# Examples

# Change to LSI Logic Parallel
Modify-ScsiController -VM "ReallyOldVM" -Type VirtualLsiLogic

# Change to LSI Logic SAS
Modify-ScsiController -VM "OldVM" -Type VirtualLsiLogicSAS

# Change all the VM's that have the BusLogic Adapter to the LSI Logic Parallel Adapter
$CurrentVMs = Get-VM | Get-ScsiController| Select-Object Parent,Type | Where-Object {$_.Type -eq "VirtualBusLogic"}
Foreach ($WorkingVm in $CurrentVMs) {
	# Update the working VM to an alternate adapter
	Modify-ScsiController -VM $WorkingVm.Parent -Type VirtualLsiLogic
}
