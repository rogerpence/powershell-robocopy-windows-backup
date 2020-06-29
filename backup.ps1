param (
    [parameter(position=0)]
    [switch] $dryrun = $false,
    [string] $config_file = 'backup.config',
    [switch] $noshutdown = $true
)

class Robo {
    [string] static GetCmd(
            [string]$source,
            [string]$target,
            [string]$robo_args,
            [string]$exclude_folders,
            [string]$exclude_files,
            [string]$logfile)
        {

        $sb = [System.Text.StringBuilder]::new()
        [void]$sb.Append('robocopy {source} {target} ')
        [void]$sb.Append('/xd {exclude_folders} ')
        [void]$sb.Append('/xf {exclude_files} ')
        [void]$sb.Append('{robo_args} ')
        [void]$sb.Append('/log+:' + $logfile)

        $sb.replace('{source}', $source.trim())
        $sb.replace('{target}', $target.trim())
        $sb.replace('{robo_args}', $robo_args)
        $sb.replace('{exclude_folders}', [string]::join(' ', $exclude_folders))
        $sb.replace('{exclude_files}', [string]::join(' ', $exclude_files))

        return $sb.ToString()
    }
}

function Find-Drive-Letter-By-Id {
    param( [string]$drive_id_to_find)

    $array = Get-PSDrive -psprovider FileSystem

    foreach ($a in $array)
    {
        if ($a.tostring().trim() -eq 'py') {
            continue
        }

        $idFilePath = $a.name + ":" + '\luther-drive-id.txt'
        if (Test-Path ($idFilePath)) {
            $driveid = get-content $idFilePath
            if ($driveid -eq $drive_id_to_find) {
                $result = $a.name + ':'
                return $result
            }
        }
    }

    return 'not-found'
}

function Backup-Directory {
    param (
        [Parameter(Position=0)]
        [string] $source_device,
        [string] $source_directory,
        [string] $target_device
    )

    $device_not_found = $false

    $source_drive = Find-Drive-Letter-By-Id $source_device
    if ($source_drive -eq 'not-found') {
        write-host "$($source_device) not found" -backgroundcolor white -foregroundcolor red
        $device_not_found = $true
    }
    $target_drive = Find-Drive-Letter-By-Id $target_device
    if ($target_drive -eq 'not-found') {
        write-host "$($target_device) not found" -backgroundcolor white -foregroundcolor red
        $device_not_found = $true
    }

    if ($device_not_found) {
        return
    }

    $source = "$($source_drive)\$($source_directory)"

    $target = "$($target_drive)\$($source_device)\$($source_directory)"

    # This is dead code. right?
    if (Test-Path $source -PathType Leaf ) {
        write-host Source is a file
        # $target = split-path -path $target
        # $target = "$($target)\"
        # copy-item $source -destination $target
        write-host("From: $($source)")
        write-host("From: $($target)")
        exit
    }
    else {
        write-host "From: $($source)" -backgroundcolor white -foregroundcolor blue
        write-host "To: $($target)" -backgroundcolor white -foregroundcolor blue

        Launch-Robo $source $target $exclude_folders $exclude_files $robo_args
    }
}

function Launch-Robo {
    param (
        [string] $source,
        [string] $target,
        [string] $exclude_folders,
        [string] $exclude_files,
        [string] $robo_args
    )

    # $logfile = [string]::Format('c:\users\{0}\{1}.log', $user, $source_drive_id)
    $logfile = "$($target)"
    $drive = $logfile.substring(0,3)
    $logfile = $logfile.replace('\', '-')
    $logfile = $logfile.substring(3)
    $logfile = "$($drive)$($logfile).log"

    '-------------------------------------------------------------------------------'  | add-content $logfile -encoding ascii
    $backup_message = 'Backup device: ' + $target_drive_id
    $backup_message | add-content $logfile -encoding ascii

    $cmd = [Robo]::GetCmd($source, $target, $robo_args, $exclude_folders, $exclude_files, $logfile)
    if ($dryrun) {
        write-host Dry run -backgroundcolor white -foregroundcolor blue
        write-host $cmd
    }
    else {
        write-host not a dry run
        #write-host $cmd
        $command = [scriptblock]::create($cmd)
        $command.invoke()
    }
}

function Read-Backup-Config {
    $config = $config_file
    if (Test-Path ($config) ) {
        $lines = get-content $config
        return $lines
    }
    else {
        write-host "Couldn't find $($config) file"   -foregroundcolor white -backgroundcolor red
        exit
    }
}

#--End of routines and classes--------------------------------------------------------------------

$exclude_folders = 'node_modules __pycache__ AppData dat env site-packages .git'
$exclude_files = 'NTUSER.DAT* ntuser.ini *.gm2 *.gbp *.pst'
$robo_args = '/mt:64 /mir /tee'

$lines = Read-Backup-Config
foreach ($line in $lines) {
    if ($line.trim().startswith('#')) {

    }
    else {
        $cmd = [scriptblock]::create($line)
        #write-host $cmd
        $cmd.invoke()
    }
}

if (($noshutdown) -eq $true)  {
    exit
}

stop-computer
