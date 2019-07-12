<#==========================================================================
Script Name: VsanComponentsPerHostByVM.ps1
Created on: 7/12/2019
Created by: Jase McCarty
Github: http://www.github.com/jasemccarty
Twitter: @jasemccarty
Website: http://www.jasemccarty.com
===========================================================================
#>

# Look for an argument that is the name of the cluster
If ($args[0]) {
    $ClusterName = $args[0]
} else {
    Write-Host "Please include the name of the cluster to run this script against" -ForegroundColor Yellow
    Write-Host
    exit
}

If (Get-Cluster -Name $ClusterName -ErrorAction SilentlyContinue) {
    # Inform the User that Data is being Retrieved
    Write-Host "Retrieving: " -ForegroundColor Green

    # Inform & Retrieve the Cluster Object
    Write-Host "      Cluster "
    $Cluster = Get-Cluster -Name $ClusterName

    # Ensure the the Cluster has vSAN Enabled
    If ($Cluster.VsanEnabled -ne $true) {
        Write-Host "      vSAN is not enabled on Cluster $ClusterName, exiting" -ForegroundColor Yellow
        exit 
    }

    # Inform & Retrieve the Host Objects in the Cluster
    Write-Host "      Hosts in Cluster $ClusterName (sorted by name)"
    $ClusterHosts = $Cluster | Get-VMHost | Sort-Object Name

    # Inform & Retrieve the VM's in the Cluster that are on vSAN
    Write-Host "      All VM's in Cluster $ClusterName (sorted by name)"
    $ClusterVMs = $Cluster | Get-VM -ErrorAction SilentlyContinue | Sort-Object Name 

    If ($ClusterVMs.Count -eq 0) {
        Write-Host "      There are no VM's on Cluster $ClusterName, exiting" -ForegroundColor Yellow
        exit
    }

    # Inform & Retrieve the Associated Objects in vSAN
    Write-Host "      All associated vSAN Objects in Cluster $ClusterName "
    $ClusterObjects = Get-VsanObject -Cluster $Cluster

    # Ensure there is at least one object on the vSAN Cluster
    If ($ClusterObjects.Count -gt 0) {

        # Inform & Retrieve the Associated Components in vSAN
        Write-Host "      All associated vSAN Components in Cluster $ClusterName "
        $ClusterComponents = Get-VsanComponent -VsanObject $ClusterObjects

    } else {
        Write-Host "      There are no vSAN Objects on Cluster $ClusterName, exiting" -ForegroundColor Yellow 
        exit
    } 

    # Begin the Report Generation
    Write-Host " "
    Write-Host "Generating Host & VM Component Count Report" -ForegroundColor Green

    # Loop through the Hosts in the vSAN Cluster 
    ForEach ($VmHost in $ClusterHosts) {

        # Put the vSAN Components in a variable, sorted by the VM they are associated with
        $VsanComponentsOnCurrentHost = $ClusterComponents.Where{$_.VsanDisk.VsanDiskGroup.VMHost -eq $VmHost} | Sort-Object VsanObject.VM

        # Print a line to easily separate hosts in the report
        Write-Host "_________________________________________________________________" -ForegroundColor Green

        # Write the name of the host and the component count on that host
        Write-Host "Host $VmHost has" $VsanComponentsOnCurrentHost.Count "components"

        # Loop through the VMs on the Cluster 
        Foreach ($VM in $ClusterVMs) {

            # Return each VM and the number of components on the current host
            $VmComponentsOnCurrentHost = $VsanComponentsOnCurrentHost.Where{$_.VsanObject.VM -eq $VM}

            # Only if the VM has components on the current host, return a count of the number of components
            If ($VmComponentsOnCurrentHost.Count -gt 0) {

                # Display the name of the VM and how many components it has (must have at least 1 component on the current host)
                Write-Host "     VM:" $VM "has" $VmComponentsOnCurrentHost.Count -NoNewline

                # Choose to be grammatically correct depending on the component count for the current VM
                If ($VmComponentsOnCurrentHost.Count -eq 1) {
                    Write-Host " component" 
                } else {
                    Write-Host " components"
                }
            }
        }
        # Write a blank line to make things a bit more clean.
        Write-Host ""
    }
    # Indicate the script is finished
    Write-Host "Completed"
} 
else {
    # The Cluster could not be retrieved, so exiting
    Write-Host "Could not retrive Cluster $ClusterName" -ForegroundColor Yellow
    exit
}
