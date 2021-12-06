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
BASEIMG_FILENAME="${HOME}/Downloads/CentOS-7-aarch64-GenericCloud-2009-orig.qcow2"

[ -d "${VMDIR}" ] || mkdir -p "${VMDIR}"

if [[ ! -f  "${VMDIR}/ca-key.pem" ]]; then
   openssl genrsa -out "${VMDIR}/ca-key.pem" 2048 &> /dev/null
   openssl req -x509 \
      -new -nodes \
      -key "${VMDIR}/ca-key.pem" \
      -subj "/C=US/ST=CA/O=MyOrg, Inc./CN=mydomain.com" \
      -sha256 -days 1024 \
      -out "${VMDIR}/ca-cert.pem" &> /dev/null
fi

DISK1="${NAME}-disk1.img"
DISK2="${NAME}-disk2.img"
DISK3="${NAME}-disk3.img"
SSH_PUB_KEY=$(<~/.ssh/id_rsa.pub)
IDX1=$(echo $((0x$(echo ${NAME} | md5sum | cut -f 1 -d " " | cut -c 1-4))) | cut -c 1-2)
IDX2=$(echo $((0x$(echo ${NAME} | md5sum | cut -f 1 -d " " | cut -c 1-4))) | cut -c 3-4)

# $(<./${USERDATA_TEMPLATE})
# repo_update: true
# repo_upgrade: all

INIT_USER=$(eval "cat <<EOF
#cloud-config
preserve_hostname: False
hostname: ${NAME}
fqdn: ${NAME}.local
ssh_authorized_keys:
  - ${SSH_PUB_KEY}
chpasswd:
  list: |
    centos:qwer1234
  expire: False
runcmd:
  - [ yum, -y, remove, cloud-init ]
  - echo "ip_resolve=4" >> /etc/yum.conf
EOF
" 2> /dev/null)
INIT_META=$(eval "cat <<EOF
instance-id: ${NAME}
hostname: ${NAME}
EOF
" 2> /dev/null)

pushd "${VMDIR}" > /dev/null
  DATADISKS=""
  if [ ! -f "${DISK1}" ]; then
    echo "${INIT_USER}" > user-data
    echo "${INIT_META}" > meta-data
    rm -f ci.iso
    hdiutil makehybrid -o ci.iso -hfs -joliet -iso -default-volume-name cidata . &> /dev/null
    cp "${BASEIMG_FILENAME}" "${DISK1}"
    # qemu-img create -f qcow2 -b "${BASEIMG_FILENAME}" "${DISK1}" &> /dev/null
    qemu-img resize "${DISK1}" 512G &> /dev/null
    if [[ "${DATADISKSIZE}" != "0" ]]; then
        qemu-img create -f qcow2 "${DISK2}" "${DATADISKSIZE}G" &> /dev/null
        qemu-img create -f qcow2 "${DISK3}" "${DATADISKSIZE}G" &> /dev/null
    fi
    cp -f "${BASEDIR}/pflash1.img" .
  fi 
  if [[ "${DATADISKSIZE}" != "0" ]]; then
    DATADISKS="-drive file=${DISK2},if=none,id=disk2 -device virtio-blk,drive=disk2 -drive file=${DISK3},if=none,id=disk3 -device virtio-blk,drive=disk3"
  fi
    # -M virt,accel=hvf,highmem=off,dump-guest-core=off,vmport=on \
  sudo qemu-system-aarch64 \
    -M virt,accel=tcg,gic-version=3,highmem=off \
    -smp "${CPUS}" \
    -cpu max \
    -m "${MEM}G" \
    -drive file="${DISK1}",if=none,id=disk1,cache=writeback -device virtio-blk,drive=disk1,bootindex=1 ${DATADISKS} \
    -netdev vmnet-macos,id=vnet0,mode=bridged -device virtio-net-pci,netdev=vnet0,mac=52:54:00:12:${IDX1}:${IDX2} \
    -drive id=cdrom0,if=none,format=raw,readonly=yes,file="ci.iso" \
    -device virtio-scsi-pci,id=scsi0 \
    -device scsi-cd,bus=scsi0.0,drive=cdrom0 \
    -drive if=pflash,format=raw,file="${BASEDIR}/pflash0.img",readonly=yes \
    -drive if=pflash,format=raw,file=pflash1.img \
    -nographic 
    
    # IP=""
    # while [ "${IP}" == "" ]; do
    #   sleep 1
    #   IP=$(grep "enp0s1 | True" nohup.out | grep -v '::' | cut -d'|' -f4 | tr -d ' ')
    # done
    # echo ${NAME}: ${IP}
popd > /dev/null

exit 0
