function Find-Drive-Letter-By-Id {
    param( [string]$drive_id_to_find)

    write-host Finding $drive_id_to_find -foregroundcolor Red

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

$files = get-item c:\users\thumb\*.* -exclude *.log,backup*.* | where {$_.mode -ne 'd----'}

$targetDevices = 'seagate-4tb-little', 'seagate-4tb-desktop'
foreach ($targetDevice in $targetDevices) {
    $drive = Find-Drive-Letter-By-Id $targetDevice

    foreach ($file in $files) {
        # write-host $file
        $targetDirectory = "$($drive)\luther-backup\delray\root"

        if (-Not (test-path -path "$($drive)\luther-backup\delray\root")) {
            new-item -path "$($drive)"  -name luther-backup\delray\root -itemtype directory
        }
        write-host Copying $file to $targetDirectory
        copy-item $file -destination  $targetDirectory -force
    }
}

