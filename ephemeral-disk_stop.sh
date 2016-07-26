#!/bin/bash
set -e

[ ! -r /etc/default/ephemeral-disk ] && exit 1

. /etc/default/ephemeral-list
. /etc/default/ephemeral-disk

disks_list=""
partitions_list=""
oldIFS=${IFS}
IFS=','
for disk in ${DISKS}; do
    disks_list="${disks_list} ${disk}"
    partitions_list="${partitions_list} ${disk}1"
done
IFS=${oldIFS}
disks_list=${disks_list## }
partitions_list=${partitions_list## }


if [ "${DESTROY_ON_STOP}" -eq "1" ]; then

    echo "Removing LVM LV ${VG_NAME}/${LV_DATA} ..."
    lvremove -f "${VG_NAME}/${LV_DATA}"

    echo "Removing LVM VG ${VG_NAME} ..."
    vgremove -f "${VG_NAME}"

    if [ "${ENABLE_MD}" -eq "1" ]; then
        echo "Removing LVM PV ${MD_DEVICE} ..."
        pvremove -f "${MD_DEVICE}"

        echo "Removing RAID device ${MD_DEVICE} ..."
        mdadm --stop "${MD_DEVICE}"
        sed -i '/^# Begin of ephemeral-scripts configuration/,/^# End of ephemeral-scripts configuration/{d}' "${MD_CONFIG}"

        echo "Wiping RAID partitions ${partitions_list[*]} ..."
        mdadm --zero-superblock ${partitions_list[*]}
    else
        echo "Removing LVM PV(s) ${disks_list[*]} ..."
        pvremove -f ${disks_list[*]}
    fi

    echo "Wiping disks ${disks_list[*]} ..."
    wipefs -faq ${disks_list[*]}
fi
