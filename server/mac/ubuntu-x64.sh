#!/usr/bin/env bash

set -euo pipefail
### Get params
NAME=${1}
CPUS=${2}
MEM=${3}
DATADISKSIZE=${4:-0}

### Global vars
BASEDIR=$(pwd)
VMDIR="vms/${NAME}"
BASEIMG_FILENAME="${HOME}/Downloads/ubuntu-20.04-server-cloudimg-amd64.img"
# CDROM=""
CDROM="-cdrom ci.iso"

[ -d "${VMDIR}" ] || mkdir -p "${VMDIR}"

DISK1="${NAME}-disk1.img"
DISK2="${NAME}-disk2.img"
DISK3="${NAME}-disk3.img"
DISK4="${NAME}-disk4.img" ## DF only
SWAP="${NAME}-swap.img"
SWAPSIZE=$(expr ${MEM} / 5 + 1)
SSH_PUB_KEY=$(<~/.ssh/id_rsa.pub)
IDX1=$(echo $((0x$(echo ${NAME} | md5sum | cut -f 1 -d " " | cut -c 1-4))) | cut -c 1-2)
IDX2=$(echo $((0x$(echo ${NAME} | md5sum | cut -f 1 -d " " | cut -c 1-4))) | cut -c 3-4)

# $(<./user-data.caml)
INIT_USER=$(eval "cat <<EOF
#cloud-config
preserve_hostname: False
hostname: ${NAME}
fqdn: ${NAME}.local
users:
  - name: ${USER}
    gecos: Admin User
    home: /home/${USER}
    shell: /bin/bash
    groups: [wheel, adm, systemd-journal]
    sudo: 
      - ALL=(ALL) NOPASSWD:ALL
    lock_passwd: false
    ssh_authorized_keys: 
      - ${SSH_PUB_KEY}
chpasswd:
  list: |
    ${USER}:qwer1234
    ubuntu:qwer1234
  expire: False
runcmd:
  # - mkswap /dev/vdb
  # - echo "/dev/vdb   swap    swap    sw  0   0" >> /etc/fstab
  # - swapon -a
EOF
" 2> /dev/null)
INIT_META=$(eval "cat <<EOF
instance-id: ${NAME}
hostname: ${NAME}
EOF
" 2> /dev/null)

# DRIVE_OPTIONS="l2-cache-size=8M,aio=threads"
DRIVE_OPTIONS="l2-cache-size=8M,cache=none,aio=threads"

pushd "${VMDIR}" > /dev/null
  DATADISKS=""
  FIRST_RUN=$([ -f "${DISK1}" ] ; echo $?)
  if [[ "${FIRST_RUN}" == "1" ]]; then
    echo "Initializing ${NAME}"
    # CDROM="-cdrom ci.iso"
    echo "${INIT_USER}" > user-data
    echo "${INIT_META}" > meta-data
    rm -f ci.iso
    hdiutil makehybrid -o ci.iso -hfs -joliet -iso -default-volume-name cidata . &> /dev/null
    # cp "${BASEIMG_FILENAME}" "${DISK1}"
    qemu-img create -o cluster_size=1M -f qcow2 -F qcow2 -b "${BASEIMG_FILENAME}" "${DISK1}" &> /dev/null
    qemu-img create -f raw "${SWAP}" "${SWAPSIZE}G" &> /dev/null
    qemu-img resize "${DISK1}" 500G &> /dev/null
    if [[ "${DATADISKSIZE}" != "0" ]]; then
        qemu-img create -f qcow2 -o cluster_size=1M "${DISK2}" "${DATADISKSIZE}G" &> /dev/null
        qemu-img create -f qcow2 -o cluster_size=1M "${DISK3}" "${DATADISKSIZE}G" &> /dev/null
        if [ "${NAME}" == "df" ]; then
          qemu-img create -f qcow2 -o cluster_size=1M "${DISK4}" "${DATADISKSIZE}G" &> /dev/null
        fi
    fi
  fi
  if [[ "${DATADISKSIZE}" != "0" ]]; then
    DATADISKS="-drive file=${DISK2},if=none,id=disk2,${DRIVE_OPTIONS} -device virtio-blk,drive=disk2,iothread=io1 -drive file=${DISK3},if=none,id=disk3,${DRIVE_OPTIONS} -device virtio-blk,drive=disk3,iothread=io1"
    if [ "${NAME}" == "df" ]; then
      DATADISKS="${DATADISKS} -drive file=${DISK4},if=none,id=disk4,${DRIVE_OPTIONS} -device virtio-blk,drive=disk4,iothread=io1"
    fi
  fi

  echo "Starting ${NAME}"
    # -M q35 -cpu max \
  # sudo qemu-system-x86_64 \
  nohup sudo qemu-system-x86_64 \
    -accel tcg,thread=multi \
    -smp "${CPUS}" \
    -m "${MEM}G" \
    -object iothread,id=io1 -device virtio-rng-pci \
    -netdev vmnet-macos,id=vnet0,mode=bridged -device virtio-net-pci,netdev=vnet0,mac=52:54:00:12:${IDX1}:${IDX2} \
    -drive file="${DISK1}",if=none,id="disk1,${DRIVE_OPTIONS}" -device virtio-blk,drive=disk1,bootindex=1,iothread=io1 \
    -drive file="${SWAP}",if=none,id=swap -device virtio-blk,drive=swap ${DATADISKS} \
    ${CDROM} -nographic -monitor none -serial file:console.out & # | tee console.out &
    # -nographic -monitor none ${CDROM} -serial mon:stdio

    echo -n "Booting ${NAME} (wait 60s) "
    for i in {1..30}; do
      sleep 2
      echo -n "."
    done
    echo
    if [[ "${FIRST_RUN}" == "1" ]]; then
      echo -n "Wait for network on ${NAME} "
      IP=""
      while [ "${IP}" == "" ]; do
        sleep 2
        IP=$(grep "|  ens3  | True |" console.out | grep -v '::' | cut -d'|' -f4 | tr -d ' ') || true
        echo -n "."
      done
      # echo " => ${IP}"
      echo "${NAME},${IP}" >> ${BASEDIR}/hosts.out
      ssh-keygen -R ${IP} &> /dev/null
    fi
popd > /dev/null

exit 0
