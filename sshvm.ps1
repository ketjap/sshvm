<#
.SYNOPSIS
    On a local Hyper-V connect with SSH to a VM guest.

.DESCRIPTION
    When the VM is stopped or paused it will be started. When the network is the ip address will be grapped to used for the SSH session with the provided username.
    The hostkey will not be checked and the ip will not be added to the known_hosts file. When disconnecting the ssh session you can choose to shut down,
    suspend or do nothing with the guest.

.PARAMETER VMName
    The VM name where to connect to.

.PARAMETER UserName
    The UserName which will be used for the ssh connection.

.NOTES
    Author: Sander Siemonsma

.EXAMPLE
    .\sshvm.ps1 -VMName MyLinuxGuest -UserName user1

    This will connect to MyLinuxGuest with username user1.

.LINK
    GitHub: https://github.com/ketjap/sshvm
#>

param(
    [Parameter(Mandatory = $true)]
    [string]
    $VMName,

    [string]
    $UserName = $env:USERNAME
)

switch ((Get-VM -Name $VMNAme).State) {
    "Off" {
        Write-Output -InputObject "Start VM: $VMName"
        Start-VM -Name $VMName
    }
    "Paused" {
        Write-Output -InputObject "Resume VM: $VMName"
        Resume-VM -Name $VMName
    }
}

if (!($vmnet = (Get-VMNetworkAdapter -VMName $VMName).IPAddresses | Select-Object -First 1)) {
    Write-Host -Object "Waiting for network to be ready." -NoNewline
    while (!($vmnet = (Get-VMNetworkAdapter -VMName $VMName).IPAddresses | Select-Object -First 1)) {
        Write-Host -Object "." -NoNewline
        Start-Sleep -Seconds 2
    }
    Write-Host -Object "."
}
Write-Output -InputObject "Network address: $vmnet`n"

ssh -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=\\.\NUL"  "$UserName@$vmnet"

switch (Read-Host -Prompt "Do you want to stop VM $($VMName)? `e[37;1m[Y] Yes `e[33;1m[N] No `e[37;1m[S] Suspend `e[0m(default is ""N"")") {
    "Y" {
        Stop-VM -Name $VMName
        Write-Output -InputObject "VM $VMName stopped..."
    }
    "S" {
        Suspend-VM -Name $VMName
        Write-Output -InputObject "VM $VMName suspended..."
    }
    default {
        Write-Output -InputObject "Keep VM $VMName running..."
    }
}
