#!/usr/bin/env bash

set -euo pipefail

echo "Creating ${NAME} with ${CPU} cores and ${MEM}GB Memory, allocating ${DATADISK}GB for data disks." > ${NAME}-debug.log

BASEDIR=$(pwd)
VMDIR="vms/${NAME}"
BASEIMG="${HOME}/Downloads/CentOS-7-x86_64-GenericCloud-2009.qcow2"
CDROM="-cdrom ci.iso"

[ -d "${VMDIR}" ] || mkdir -p "${VMDIR}"

DISK1="${NAME}-disk1.img"
DISK2="${NAME}-disk2.img"
DISK3="${NAME}-disk3.img"
DISK4="${NAME}-disk4.img" ## DF only
SWAP="${NAME}-swap.img"
SWAPSIZE=$(expr ${MEM} / 5 + 1)
# SSH_PUB_KEY=$(<~/.ssh/id_rsa.pub)
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
DRIVE_OPTIONS="l2-cache-size=8M,cache=none,aio=threads,discard=unmap"
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
    qemu-img create -o cluster_size=1M -f qcow2 -F qcow2 -b "${BASEIMG}" "${DISK1}" &> /dev/null
    qemu-img create -f raw "${SWAP}" "${SWAPSIZE}G" &> /dev/null
    qemu-img resize "${DISK1}" 500G &> /dev/null
    if [[ "${DATADISK}" != "0" ]]; then
        qemu-img create -f qcow2 -o cluster_size=1M "${DISK2}" "${DATADISK}G" &> /dev/null
        qemu-img create -f qcow2 -o cluster_size=1M "${DISK3}" "${DATADISK}G" &> /dev/null
        if [ "${NAME}" == "df" ]; then
          qemu-img create -f qcow2 -o cluster_size=1M "${DISK4}" "${DATADISK}G" &> /dev/null
        fi
    fi
  fi
  if [[ "${DATADISK}" != "0" ]]; then
    DATADISKS="-drive file=${DISK2},if=none,id=disk2,${DRIVE_OPTIONS} -device virtio-blk,drive=disk2,iothread=io1 -drive file=${DISK3},if=none,id=disk3,${DRIVE_OPTIONS} -device virtio-blk,drive=disk3,iothread=io1"
    if [ "${NAME}" == "df" ]; then
      DATADISKS="${DATADISKS} -drive file=${DISK4},if=none,id=disk4,${DRIVE_OPTIONS} -device virtio-blk,drive=disk4,iothread=io1"
    fi
  fi

  echo "Starting ${NAME}" >> ${BASEDIR}/${NAME}-debug.log
   sudo /Library/Application\ Support/com.canonical.multipass/bin/qemu-system-x86_64 \
    -accel tcg,thread=multi \
    -M pc,acpi=on,graphics=off,mem-merge=off \
    -smp "${CPU}" \
    -m "${MEM}G" \
    -L /opt/homebrew/Cellar/qemu/6.2.0/share/qemu/ \
    -nic vmnet-macos,mode=shared,model=virtio-net-pci,mac=${OUI} \
    -object iothread,id=io1 -device virtio-rng-pci \
    -drive file="${DISK1}",if=none,id="disk1,${DRIVE_OPTIONS}" -device virtio-blk,drive=disk1,bootindex=1,iothread=io1 \
    -drive file="${SWAP}",if=none,id=swap,format=raw -device virtio-blk,drive=swap ${DATADISKS} \
    ${CDROM} -display none -monitor none -daemonize -serial file:console.out # | tee console.out &
    if [[ "${FIRST_RUN}" == "1" ]]; then
      while [ "${IP}" == "" ]; do
        sleep 2
        IP=$(grep "|  eth0  | True |" console.out | grep -v '/64' | cut -d'|' -f4 | tr -d ' ') || true
      done
      echo "${NAME},${IP}" >> ${BASEDIR}/hosts.out
      ssh-keygen -R ${IP} &> /dev/null
    fi
popd > /dev/null

printf '{"hostname":"%s","ip_address":"%s"}' "${NAME}" "${IP}"

exit 0
