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
BASEIMG_FILENAME="${HOME}/Downloads/ubuntu-20.04-server-cloudimg-arm64.img"
# NETOPTS=""
# PORT=$(shuf -i 2000-2999 -n 1) # random port between 2000-2999 inclusive

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

# if [ "${NAME}" == "gw" ]; then
#   NETOPTS=",hostfwd=tcp::${PORT}-:22"
# fi

DISK1="${NAME}-disk1.img"
DISK2="${NAME}-disk2.img"
DISK3="${NAME}-disk3.img"
SSH_PUB_KEY=$(<~/.ssh/id_rsa.pub)

PASS='$6$nqZiIASVBA.iF$9nubU0ImWVrv4XhtEq9XhSh9UYNFQ7yC9Lf7A.uheSlJ3cgI5d9ltkUwRq.X8lAwoQuLAMem6v.gJNGYwk5XA0'

INIT_USER=$(eval "cat <<EOF
$(<./user-data.uaml)
EOF
" 2> /dev/null)
INIT_META=$(eval "cat <<EOF
instance-id: ${NAME}
local-hostname: ${NAME}
EOF
" 2> /dev/null)

pushd "${VMDIR}" > /dev/null
  DATADISKS=""
  if [ ! -f "${DISK1}" ]; then
    echo "${INIT_USER}" > user-data
    echo "${INIT_META}" > meta-data
    rm -f ci.iso
    cp -f "${BASEDIR}/pflash1.img" .
    hdiutil makehybrid -o ci.iso -hfs -joliet -iso -default-volume-name cidata . &> /dev/null
    qemu-img create -f qcow2 -F qcow2 -b "${BASEIMG_FILENAME}" "${DISK1}" &> /dev/null
    qemu-img resize "${DISK1}" 512G &> /dev/null
    if [[ "${DATADISKSIZE}" != "0" ]]; then
        qemu-img create -f qcow2 "${DISK2}" "${DATADISKSIZE}G" &> /dev/null
        qemu-img create -f qcow2 "${DISK3}" "${DATADISKSIZE}G" &> /dev/null
    fi
  fi 
  if [[ "${DATADISKSIZE}" != "0" ]]; then
    DATADISKS="-drive file=${DISK2},if=none,id=disk2 -device virtio-blk,drive=disk2 -drive file=${DISK3},if=none,id=disk3 -device virtio-blk,drive=disk3"
  fi
  nohup sudo qemu-system-aarch64 \
    -M virt,accel=hvf,highmem=off \
    -smp "${CPUS}" \
    -cpu max \
    -m "${MEM}G" \
    -netdev vmnet-macos,id=vnet0,mode=bridged -device e1000,netdev=vnet0 \
    -drive if=pflash,format=raw,file="${BASEDIR}/pflash0.img",readonly=yes \
    -drive if=pflash,format=raw,file=pflash1.img \
    -drive file="${DISK1}",if=none,id=disk1,cache=writeback -device virtio-blk,drive=disk1 ${DATADISKS} \
    -drive id=cdrom0,if=none,format=raw,readonly=yes,file="ci.iso" \
    -device virtio-scsi-pci,id=scsi0 \
    -device scsi-cd,bus=scsi0.0,drive=cdrom0 -display none -nographic & 

    sleep 3
    
    IP=""
    while [ "${IP}" == "" ]; do
      IP=$(grep "enp0s1 | True" nohup.out | grep -v '::' | cut -d'|' -f4 | tr -d ' ')
    done
    echo ${NAME}: ${IP}
popd > /dev/null

exit 0
  # wget https://ezmeral-platform-releases.s3.amazonaws.com/5.3.6/3060/hpe-cp-rhel-release-5.3.6-3060.bin
  # ./hpe-cp-rhel-release-5.3.6-3060.bin --skipeula --default-password admin123 --ssl-cert /home/centos/ca-cert.pem --ssl-priv-key /home/centos/ca-key.pem

  # sudo qemu-system-aarch64 -nographic -machine virt,gic-version=max -m 32G -cpu max -smp 4 \
  #   -netdev vmnet-macos,id=vnet0,mode=host -device e1000,netdev=vnet0 \
  #   -drive file="${DISK0}",if=none,id=drive0,cache=writeback -device virtio-blk,drive=drive0,bootindex=0 \
  #   -drive file="${DISK1}",if=none,id=drive1,cache=writeback -device virtio-blk,drive=drive1,bootindex=1 \
  #   -drive file="${DISK2}",if=none,id=drive2,cache=writeback -device virtio-blk,drive=drive2,bootindex=2 \
  #   -drive file=ci.iso,format=raw \
  #   -drive file="${BASEDIR}/pflash0.img",format=raw,if=pflash -drive file="${BASEDIR}/pflash1.img",format=raw,if=pflash 

    # -netdev user,id=vnet"${NETOPTS}" -device virtio-net-pci,netdev=vnet \
