# systemd-ephemeral-drives

Systemd thinks it knows best, and getting ephemeral data partitions correctly configured isn't a single command.

This is based off of some work from [bhuisgen](https://github.com/bhuisgen/ephemeral-scripts) put together with a much more focused purpose.
Scripts have been refactored and any unnecessary cruft for the use case has been eliminated.
The instructions are basically the same to get started.

## Dependencies

    # apt install make parted lvm2

If you have multiple ephemeral disks, you can use software RAID to increase IO performance:

    # apt install mdadm

## ephemeral-disk

This script prepares the ephemeral disks of an EC2 instance at each system boot by creating a swap partition (if enabled in configuration) and a data partition wich will be mounted in the directory */mnt/data*. If the partitions are already created, nothing is done except mounting them. After mounting, the service starts by dependency all required services.

LVM is used like this:
* a LVM volume group *ephemeral* of all disks
* a LVM logical volume *swap* for the swap partition
* a LVM logical volume *data* for the data partition

The LVM volume group will have sufficient free space to allow snapshot creation and backup with the script *ephemeral-backup*.

### Installation

    # cd ephemeral-disk/

    # cp ephemeral-disk.dist ephemeral-disk
    # vim ephemeral-disk

    # cp ephemeral-units.service.dist ephemeral-units.service
    # vim ephemeral-units.service

    # make install

### Usage

Start the ephemeral disk services:

    # make enable
    # make start

Check that swap and data partitions are created and mounted:

    # cat /proc/swaps
    # free -m
    # lvs
    # cd /ephemeral/data

To be sure verify your bootorder after a system restart:

    # systemd-analyze plot > bootorder.svg

The unit *ephemeral-units.service* must be started before all units using the ephemeral storage.


