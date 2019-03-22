Function EsxiPhysicalDisks {

    # Set our Parameters
	[CmdletBinding()]Param(
        [Parameter(Mandatory=$true)][String]$Cluster
    )

    # Retrieve the Cluster Object
    $WorkingCluster = Get-Cluster -Name $Cluster 

    # Write the cluster name
    Write-Host "Cluster: $WorkingCluster"

    # Enumerate the hosts and loop through them
    Foreach ($VMHost in ($WorkingCluster|Get-VMHost|Sort-Object Name)) {

        # Denote the current host
        Write-Host "Current Host:" $VMHost

        # Connect to the esxcli instance of the current host
        $EsxCli = Get-EsxCli -VMHost $VMHost -V2

        # Retrieve all of the Disks in the Current Host
        $ScsiLuns = Get-ScsiLun -VmHost $VMHost -LunType disk | Sort-Object Name, CapacityGB

        # Loop through all of the physical disks
        Foreach ($ScsiLun in $ScsiLuns) {
            
            # Retrieve the physical location of the current disk
            Try {
                $DeviceLocation = $EsxCli.storage.core.device.physical.get.Invoke(@{device=$ScsiLun.CanonicalName}).physicallocation
                $DeviceInfo = $EsxCli.storage.core.device.list.Invoke() # | Where-Object {$_.device -match $ScsiLun.CanonicalName}
            }
            Catch {
                $DeviceLocation = "Not Available"
            }

            # Only report physical devices that we can return their location information
            If ($DeviceInfo.drivetype -match "physical" -and $DeviceLocation -ne "Not Available") {
                # Output the device and location information for each physical device
                Write-Host "Physical Device: " -ForegroundColor Yellow -NoNewline
                Write-Host $ScsiLun.CanonicalName -NoNewline
                Write-Host " Location:" -Foregroundcolor Yellow -NoNewLine
                Write-Host $DeviceLocation -NoNewLine
                Write-Host " HBA Path:" -ForegroundColor Yellow -NoNewline
                Write-Host $ScsiLun.RuntimeName -NoNewline
                Write-Host " SSD:" -ForegroundColor Yellow -NoNewline
                Write-Host $ScsiLun.IsSsd -NoNewline
                Write-Host " Size (GB):" -ForegroundColor Yellow -NoNewline
                $CapacityGB = [math]::Round(($ScsiLun.CapacityGB/0.9325))
                Write-Host $CapacityGB
            }
        }
            Write-Host ""
    }

}

EsxiPhysicalDisks -Cluster $Args[1]
