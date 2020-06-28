param (
    [parameter(position=0)]
    [switch] $dryrun = $false,
    [string] $config_file = 'backup.config'
)


write-host "In test.ps1 $($dryrun) $($config_file)"