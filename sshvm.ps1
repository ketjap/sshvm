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

switch (Read-Host -Prompt "Do you want to stop VM $($VMName)? [Y] Yes [N] No [S] Suspend (default is ""N"")") {
    "Y" {
        Stop-VM -Name $VMName
    }
    "S" {
        Suspend-VM -Name $VMName
    }
    default {
        Write-Output -InputObject "Keep VM $VMName running..."
    }
}
