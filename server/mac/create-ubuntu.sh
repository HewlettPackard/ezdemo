#!/usr/bin/env bash

set -euo pipefail

echo "Creating ${NAME} with ${CPU} cores and ${MEM}GB Memory, allocating ${DISKSIZE}GB for data disks."

BASEDIR=$(pwd)
VMDIR="vms/${NAME}"
BASEIMG="${HOME}/Downloads/ubuntu-20.04-server-cloudimg-amd64.img"

[ -d "${VMDIR}" ] || mkdir -p "${VMDIR}"

DISK1="${NAME}-disk1.img"
DISK2="${NAME}-disk2.img"
DISK3="${NAME}-disk3.img"
DISK4="${NAME}-disk4.img" ## DF only
SWAP="${NAME}-swap.img"
SWAPSIZE=$(expr ${MEM} / 5 + 1)
SSH_PUB_KEY=$(<../generated/controller.pub_key)

INIT_USER=$(eval "cat <<EOF
#cloud-config
preserve_hostname: False
hostname: ${NAME}
fqdn: ${NAME}.local
ssh_authorized_keys: 
  - ${SSH_PUB_KEY}
EOF
" 2> /dev/null)
INIT_META=$(eval "cat <<EOF
instance-id: ${NAME}
hostname: ${NAME}.local
EOF
" 2> /dev/null)

# Common options for ssd/flash drives
# DRIVE_OPTIONS="l2-cache-size=8M,cache=none,aio=threads,discard=unmap"
DRIVE_OPTIONS="if=none,format=qcow2,discard=unmap"
# Randomize MAC for each VM
OUI="52:54:00:$(openssl rand -hex 3 | sed 's/\(..\)/\1:/g; s/:$//')"
IP=$(grep -s "${NAME}" hosts.out | cut -d',' -f2 || echo "")

pushd "${VMDIR}" > /dev/null
  DATADISKS=""
  FIRST_RUN=$([[ -f "${DISK1}" ]] ; echo $?)
  if [[ "${FIRST_RUN}" == "1" ]]; then
    echo "${INIT_USER}" > user-data
    echo "${INIT_META}" > meta-data
    rm -f ci.iso
    hdiutil makehybrid -o ci.iso -hfs -joliet -iso -default-volume-name cidata . &> /dev/null
    qemu-img create -f qcow2 -F qcow2 -b "${BASEIMG}" "${DISK1}" &> /dev/null
    qemu-img create -f raw "${SWAP}" "${SWAPSIZE}G" &> /dev/null
    qemu-img resize "${DISK1}" 500G &> /dev/null
    if [[ "${DISKSIZE}" != "0" ]]; then
        qemu-img create -f qcow2 "${DISK2}" "${DISKSIZE}G" &> /dev/null
        qemu-img create -f qcow2 "${DISK3}" "${DISKSIZE}G" &> /dev/null
        if [ "${NAME:0:2}" == "df" ]; then
          qemu-img create -f qcow2 "${DISK4}" "${DISKSIZE}G" &> /dev/null
        fi
    fi
  fi
  if [[ "${DISKSIZE}" != "0" ]]; then
    DATADISKS="-drive file=${DISK2},id=disk2,${DRIVE_OPTIONS} -device scsi-hd,drive=disk2,bus=scsi0.0 -drive file=${DISK3},id=disk3,${DRIVE_OPTIONS} -device scsi-hd,drive=disk3,bus=scsi0.0"
    if [ "${NAME}" == "df" ]; then
      DATADISKS="${DATADISKS} -drive file=${DISK4},id=disk4,${DRIVE_OPTIONS} -device scsi-hd,drive=disk4,bus=scsi0.0"
    fi
  fi

   sudo /Library/Application\ Support/com.canonical.multipass/bin/qemu-system-aarch64 \
    -machine virt,highmem=off -accel hvf \
    -smp "${CPU}" -cpu cortex-a72 \
    -m "${MEM}G" \
    -drive file="/Library/Application Support/com.canonical.multipass/bin/../Resources/qemu/edk2-aarch64-code.fd",if=pflash,format=raw,readonly=on \
    -nic vmnet-macos,mode=shared,model=virtio-net-pci,mac=${OUI} \
    -device virtio-scsi-pci,id=scsi0 \
    -drive file="${DISK1}",id=disk1,"${DRIVE_OPTIONS}" -device scsi-hd,drive=disk1,bus=scsi0.0 \
    -drive file="${SWAP}",id=swap,format=raw,if=none -device scsi-cd,drive=swap,bus=scsi0.0 ${DATADISKS} \
    -drive file=ci.iso,id=cd0,format=raw,if=none,readonly=on -device scsi-cd,drive=cd0,bus=scsi0.0 -display none -monitor none -daemonize -serial file:console.out # | tee console.out &
    if [[ "${FIRST_RUN}" == "1" ]]; then
      while [ "${IP}" == "" ]; do
        sleep 2
        IP=$(grep "| enp0s1 | True |" console.out | grep -v '/64' | cut -d'|' -f4 | tr -d ' ') || true
      done
      echo "${NAME},${IP}" >> ${BASEDIR}/hosts.out
      ssh-keygen -R ${IP} &> /dev/null
    fi
popd > /dev/null

printf '{"hostname":"%s","ip_address":"%s"}' "${NAME}" "${IP}"

exit 0
