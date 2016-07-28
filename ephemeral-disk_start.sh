#!/bin/bash
set -e

[ ! -r /etc/default/ephemeral-disk ] && exit 1

. /etc/default/ephemeral-list
. /etc/default/ephemeral-disk

disks_list=""
partitions_list=""
partitions_count=0
oldIFS=${IFS}
IFS=','
for disk in ${DISKS}; do
    disks_list="${disks_list} ${disk}"
    partitions_list="${partitions_list} ${disk}1"
    partitions_count=$((partitions_count + 1))
done
IFS=${oldIFS}
disks_list=${disks_list## }
partitions_list=${partitions_list## }

[[ "x${disks_list[*]}" == "x" ]] && {
    echo "no disks detected by ephemeral-disk_start.sh"
    exit 1
}

LV_DISK="/dev/${VG_NAME}/${LV_DATA}"

if [ ! -b "${LV_DISK}" ]; then
    echo "Wiping disk(s) ${disks_list[*]} ..."
    wipefs -faq ${disks_list[*]}

    for disk in ${disks_list}; do
        echo "Partitioning disk ${disk} ..."
        parted --script "${disk}" mklabel gpt
        parted --script --align optimal "${disk}" mkpart primary ext2 2048s 100%

        if [ "${partitions_count}" -gt 1 ]; then
            echo "Enabling partition RAID flag ..."
            parted --script "${disk}" set 1 raid on
        else
            echo "Enabling partition LVM flag ..."
            parted --script "${disk}" set 1 lvm on
        fi
    done

    echo "Probing partitions ..."
    partprobe

    if [ "${partitions_count}" -gt 1 ]; then
        echo "Creating MD device /dev/md0 ..."
        yes | mdadm --create "${MD_DEVICE}" --level="${MD_LEVEL}" --chunk="${MD_CHUNK}" --raid-devices="${partitions_count}" ${partitions_list[*]}

        echo "Storing MD device configuration ..."
        sed -i '/^# Begin of ephemeral-scripts configuration/,/^# End of ephemeral-scripts configuration/{d}' "${MD_CONFIG}"
        {
            echo "# Begin of ephemeral-scripts configuration" ;
            mdadm --detail --scan >> "${MD_CONFIG}" ;
            echo "# End of ephemeral-scripts configuration" ;
        } >> "${MD_CONFIG}"

        echo "Creating LVM PV ${MD_DEVICE} ..."
        pvcreate -f "${MD_DEVICE}"

        echo "Creating LVM VG ${VG_NAME} ..."
        vgcreate -f "${VG_NAME}" "${MD_DEVICE}"
    else
        echo "Creating LVM PV(s) ${partitions_list[*]} ..."
        pvcreate -fy ${partitions_list[*]}

        echo "Creating LVM VG ${VG_NAME} ..."
        vgcreate -f "${VG_NAME}" ${partitions_list[*]}
    fi

    echo "Creating LVM LV ${VG_NAME}/${LV_DATA} ..."
    lvcreate --yes -l "${LV_DATA_EXTENTS}" -n "${LV_DATA}" "${VG_NAME}"

    echo "Formating data partition ..."
    sh -c "mkfs.${MOUNT_FSTYPE} -F \"/dev/${VG_NAME}/${LV_DATA}\""
fi

echo "Creating data mountpoint ..."
mkdir -p "${MOUNT_PATH}"
