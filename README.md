# Windows backup with RoboCopy and Powershell

This backup scheme backs up folders from a source device and writes them to a target device. PowerShell drives the process and RoboCopy writes the source data to the target device.

RoboCopy is very fast and this backup is the fastest backup I've ever used. As configured, RoboCopy mirrors the source directory into the target directory. See the [RoboCopy docs for more information.](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/robocopy)

One of the reasons this backup is fast is that it uses RoboCopy's ability to exclude directories and files. For example, using as it is currently configured, among the folders excluded are `node_modules` and `.git` folders.

Another important thing about this backup is that it is, mostly, unattended and drive-letter insenstive. My backup scheme backs up to an often changing set of Hyper-Vs and externally attached backup devices. _Every_ commercial backup systems I've ever used requires hard-coded source and target drive letters and that pain and hassle has also inhibited a reliable backup for me.

This system requires you to identify each drive with a file identifier. Once that is in place, this back up system refers to source and target drives not by drive letter, but their assigned name.

## Avoiding drive letters with drive identifiers

A key component to this system is that it doesn't identify target drives by drive letter, rather it identifies by special naming scheme. Ideally, the drive volume name would be the identifier, but occasinally a USB-connected drive doesn't mount the volume name appropriately.

To identify target drives, there must be a file in the root named `rp-drive-id.txt.` This file should have a name, without embedded blanks, on the first line. Use any naming scheme you want. I identify each external drive with a name and clearly apply a physical label to the device. For example, I have a small 4TB Seagate drive that I have named 'seagate-4tb-little.'

In the case of HYPER-V volumes, they are named the same as the PC name.

> Each drive you want to use as a source or target drive _must_ have an `rp-drive-id.txt` file in its root to uniquely identify that drive.

## Using the scripts

There are two scripts:

* **backup-vhdx.ps1** This script mounts any Hyper-v volumes (the `.VHDX` file) by with PowerShell. It also unmounts them before it ends. Once specified drives are mounted, the `backup.ps1` script is launched.

VHDX files are currently identifed in the `backup-vhdx.ps1` script in the `$vhdxs` array.

* **backup.ps1** This script performs the backup and assumes all necessary drives are mounted and available. This script can be run stand-alone on any machine, but if that machine has Hyper-V volumes, the volumes must first be mounted.

`backup-vhdx` is a wrapper for `backup` to ensure that VHDX drives mounted and available for `backup.`

## Configuration file

`backup.ps1` reads a configuration file for backup instructions. The default configuration file name is `backup.config` but you can add others.

The backup configuration file defines 'backup sets' which provide source and targets drives for the backup. Each backup set must be on one line. The example below is on multiple lines for readability purposes. The \ characters shows line breaks for readability purposes.

backup-directory -source_device delray \
                 -source_directory users\thumb\documents \
                 -target_device seagate-4tb-little

* **-source-device** defines a device name that should be available in a drive identifier file.

* **-source_directory** defines the top level directory to backup from the drive identified by `-source-device`. Not that you *DO NOT* include the drive specifier here. The drive specifier gets resolved by looking at the drive identifier file present on `-source-device`

* **-target-device** defines a device name that should be available in a drive identifier file. The backup top-level directory is the name of the target device and then he exact structure from the source device.

For example, assume the source device `delray` resolves to drive `F:` and the target device resolves to drive `G:` then given this drive set:

backup-directory -source_device delray \
                 -source_directory users\thumb\documents \
                 -target_device seagate-4tb-little

The backup will be present at `G:\delray\users\thumb\documents\'

RoboCopy uses creates a log file using this naming scheme:

    `G:\delray-users-thumb-documents.log`

This log file is appended to each time the backup set is run.

## RoboCopy configuration

These configuration values are currently hardcoded in `backup.ps1`

Excluded folders:

    node_modules __pycache__ AppData dat env site-packages .git

Excluded files:

    NTUSER.DAT* ntuser.ini *.gm2 *.gbp *.pst

Command line arguments:

    /mt:64 /mir /tee

> Note the `/mt` flag specifies how may files RoboCopy copies at once (by governing threads available). I typically use backup at the end of the day on my way of the office so my PC is dedicated the RoboCopy process. You may want to fiddle with the `/mt` setting for your environment and use cases.

## Using this backup for directories in VHDX files

Let's assume there are two source directories that need to be backed up, each on a VHDX file: `zimmie` and `zevon`. `zimmie` is this VHDX file:

    C:\Users\thumb\VMs\zimmie\zimmie.vhdx

and 'zevon` is present in this VHDX file:

    C:\Users\thumb\VMs\zevon\zevon.vhdx

and there are two backup devices identified as:

    seagate-4tb-little

and

    seagate-4tb-desktop

The contents of `backup.config` are: (remember to remove the \ and put each backup set definition on one line)

    backup-directory -source_device zimmie \
                    -source_directory users\thumb\documents \
                    -target_device seagate-4tb-little

    backup-directory -source_device zevon \
                    -source_directory users\thumb\documents \
                    -target_device seagate-4tb-little

    backup-directory -source_device zimmie \
                    -source_directory users\thumb\documents \
                    -target_device seagate-6tb-desktop

    backup-directory -source_device zevon \
                    -source_directory users\thumb\documents \
                    -target_device seagate-6tb-desktop

Because we're doing back up that needs VHDX files mounted, the PowerShell terminal must be launched as an administrator.

Then do this backup with this command line:

    `./backup-vhdx`

This will mount the VHDXs, run each backup as specified, then unmount the VHDXs and shut down the PC.

./backup-vhdx has three optional command line arguments:

* **-dryrun** If present the backup is not performed but the command line to run RoboCopy is shown.
* **-noshutdown** If present the PC is not shut down when the back up finishes.
* **-config_file [config file name]** Specifies an alternative backup set definition.

> Note that although `backup-vhdx` does mount VHDX files, `backup-vhdx` can also have back up back up sets that don't reference VHDX files.

## Using this backup for directories not in VHDX files

If you don't need to mount VHDX files, the PowerShell terminal does not need to be launched as an administrator. The command line is:

    `./backup`

The command line arguments for backup are the same as for backup-vhdx.

## Using this backup to backup specified files

RoboCopy doesn't work well with single files, it expects its backup sources being directories. There may be times when you want to backup what is essentially a single file. Consider backing up a VHDX file itself (not directories inside it--but the file itself).

Assume the VHDX is at this physical location on the device named 'delray'

    C:\Users\thumb\VMs\zimmie\zimmie.vhdx

This backup set

    backup-directory -source_device delray \
                    -source_directory C:\Users\thumb\VMs\zimmie \
                    -target_device seagate-6tb-desktop

would backup the VHDX's parent folder which would include the .VHDX file itself.

> As an aside, RoboCopy is very fast. It copies a file much faster than PowerShell's COPY-ITEM or DOS's COPY command.

Note the location of VHDX files have the potential to be troublesome with this backup scheme. I typically backup a system's `x:/users/username/documents` folder every night. If I'm on a host system that also has VHDX files under the documents folder, they would be backed up and takes a long time.

I always keep VHDX files outside the `documents` folder that weekly I can back them up with a different configuration file.

Alternatively you could add the `.VHDX` extension to RoboCopy's excluded files list, but for that to be flexible enough you'd probably want to make that setting available at runtime. There currently isn't a way to do that.





