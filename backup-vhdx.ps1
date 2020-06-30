param (
    [parameter(position=0)]
    [switch] $dryrun = $false,
    [string] $config_file = 'backup.config',
    [switch] $shutdown = $false
)

$vhdxs = "C:\Users\thumb\VMs\rp-Win10Git\RP-Win10Git.vhdx"

function Is-Elevated {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

function run-backup {
    if ($dryrun) {
        $command = './backup.ps1 -dryrun -config_file ' + $config_file
    }
    else {
        $command = './backup.ps1 -config_file ' + $config_file
    }
    write-host $command
    invoke-expression $command
}

function perform-backup {
    foreach ($vhdx in $vhdxs) {
        if (-not (test-path $vhdx -PathType leaf)) {
            write-host "Could not find VHDX file: $($vhdx)"  -backgroundcolor white -foregroundcolor red
            return
        }

        try {
            $attached = get-vhd $vhdx | select -expandproperty attached
            if (-not ($attached)) {
                write-host Mounting $vhdx  -foregroundcolor white -backgroundcolor  green
                Mount-vhd -path $vhdx
                start-sleep -seconds 5
                run-backup
                Dismount-vhd -Path $vhdx
            }
        }
        catch  {
            $ErrorMessage = $_.Exception.Message
            $FailedItem = $_.Exception.ItemName
            write-host An error occurred with $vhdx -backgroundcolor white -foregroundcolor red
            write-host $ErrorMessage
            write-host $FailedItem
        }
    }
}

if ((Is-Elevated) -eq $false)  {
    write-host You must run this command from an elevated session -foregroundcolor red -backgroundcolor white
    exit
}

if (-Not (Test-Path $config_file)) {
    write-host "Couldn't find $($config_file) file"   -foregroundcolor white -backgroundcolor red
    exit
}

perform-backup

if (($shutdown) -eq $true)  {
    stop-computer
}

