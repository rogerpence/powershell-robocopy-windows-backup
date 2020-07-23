$vhdxs = "C:\Users\thumb\VMs\rp-Win10Git\RP-Win10Git.vhdx", "C:\Users\Public\Documents\Hyper-V\Virtual hard disks\win10rp-1809.vhdx"

function show-exception-error($msg) {
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
    write-host $msg  -backgroundcolor white -foregroundcolor red
    write-host $ErrorMessage
    write-host $FailedItem
}

foreach ($vhdx in $vhdxs) {
    try {
        if (-not((get-vhd $vhdx | select -expandproperty attached))) {
            write-host Mounting $vhdx -foregroundcolor green -backgroundcolor white
            mount-vhd $vhdx
        }
        else {
            write-host $vhdx not mounted -foregroundcolor yellow -backgroundcolor green
        }
    }
    catch  {
        show-exception-error "An error occurred with $($vhdx)"
    }
}