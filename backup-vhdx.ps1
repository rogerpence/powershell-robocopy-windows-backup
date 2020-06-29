param (
    [parameter(position=0)]
    [switch] $dryrun = $false,
    [string] $config_file = 'backup.config',
    [switch] $noshutdown = $false
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

function mount-vhdxs {
    foreach ($vhdx in $vhdxs) {
        $attached = get-vhd $vhdx | select -expandproperty attached
        if (-not ($attached)) {
            write-host Mounting $vhdx  -foregroundcolor white -backgroundcolor  red
            Mount-vhd -path $vhdx
            start-sleep -seconds 5
            run-backup
            Dismount-vhd -Path $vhdx
        }
        else {
            write-host Could not attach to $vhdx  -foregroundcolor white -backgroundcolor  red
        }

        write-host $vm
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

mount-vhdxs

if (($noshutdown) -eq $true)  {
    exit
}

stop-computer
