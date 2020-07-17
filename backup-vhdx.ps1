param (
    [parameter(position=0)]
    [switch] $dryrun = $false,
    [string] $config_file = 'backup.config',
    [switch] $shutdown = $false
)

$vhdxs = "C:\Users\thumb\VMs\rp-Win10Git\RP-Win10Git.vhdx", "C:\Users\Public\Documents\Hyper-V\Virtual hard disks\win10rp-1809.vhdx"

function Is-Elevated {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

function run-backup-set {
    write-host 'RUNNING'  -backgroundcolor white -foregroundcolor red
    if ($dryrun) {
        $command = './backup.ps1 -dryrun -config_file ' + $config_file
    }
    else {
        $command = './backup.ps1 -config_file ' + $config_file
    }
    write-host $command
    invoke-expression $command
}

function show-exception-error($msg) {
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
    write-host $msg  -backgroundcolor white -foregroundcolor red
    write-host $ErrorMessage
    write-host $FailedItem
}

function mount-vhdxs {
    $result = $true
    foreach ($vhdx in $vhdxs) {
        try {
            if (-not (test-path $vhdx -PathType leaf)) {
                write-host "Could not find VHDX file: $($vhdx)"  -backgroundcolor white -foregroundcolor red
                $result = $false
                continue
            }
            $attached = get-vhd $vhdx | select -expandproperty attached
            if ($attached) {
                write-host "VHDX file is available: $($vhdx)"  -backgroundcolor white -foregroundcolor red
                $result = $false
            }
            else {
                write-host "VHDX file is available: $($vhdx)"  -backgroundcolor white -foregroundcolor green
            }
            write-host Mounting $vhdx  -foregroundcolor white -backgroundcolor  green
            Mount-vhd -path $vhdx
            start-sleep -seconds 5
    }
        catch  {
            show-exception-error "An error occurred with $($vhdx)"
            return $false
        }
    }

    return $result
}

function perform-backup {
    try {
        run-backup-set
    }
    catch  {
        show-exception-error "An error occurred with $($vhdx)"
    }
}

function dismount-vhdxs {
    foreach ($vhdx in $vhdxs) {
        try {
            Dismount-vhd -Path $vhdx
        }
        catch {
            show-exception-error "An error occurred with $($vhdx)"
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

write-host Using config file: $config_file


# $available = are-vhdxs-available
# write-host $available
# exit

if (mount-vhdxs) {
    perform-backup
    dismount-vhdxs

    if (($shutdown) -eq $true)  {
        stop-computer
    }
}