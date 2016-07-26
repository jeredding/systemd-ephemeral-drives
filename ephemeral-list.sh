#!/bin/bash
# ephemeral-list.sh

METADATA_URL_BASE="http://169.254.169.254/2012-01-12"
DRIVE_SCHEME='xvd'
ephemerals=$(curl --silent ${METADATA_URL_BASE}/meta-data/block-device-mapping/ | grep ephemeral)
for disk in ${ephemerals}; do
  echo "Probing ${disk} .."
  device_name=$(curl --silent ${METADATA_URL_BASE}/meta-data/block-device-mapping/${disk})
  device_name=$(echo ${device_name} | sed "s/sd/${DRIVE_SCHEME}/")
  device_path="/dev/${device_name}"
  if [ -b ${device_path} ]; then
    echo "Detected ephemeral disk: ${device_path}"
    [[ "x${DRIVES}" == "x" ]] && DRIVES="${device_path}" || DRIVES="${DRIVES},${device_path}"
  else
    echo "Ephemeral disk ${disk}, ${device_path} is not present. skipping"
  fi
done

echo "DISKS=\"$DRIVES\"" > /etc/default/ephemeral-list