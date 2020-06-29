param (
    [parameter(position=0)]
    [switch] $dryrun = $false,
    [string] $config_file = 'backup.config'
)

write-host $config_file

if (-Not (Test-Path $config_file)) {
    write-host "Couldn't find $($config_file) file"   -foregroundcolor white -backgroundcolor red
}
else {
    write-host "Found $($config_file) file"   -foregroundcolor white -backgroundcolor green
}
