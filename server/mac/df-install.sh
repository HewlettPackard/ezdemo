#!/usr/bin/env bash

set -euo pipefail

curl -# -o /tmp/mapr-setup.sh "https://package.mapr.hpe.com/releases/installer/mapr-setup.sh"
chmod +x /tmp/mapr-setup.sh

### 
echo "vm.swappiness=1
net.ipv4.tcp_retries2=5" | sudo tee -a /etc/sysctl.conf
echo never | sudo tee /sys/kernel/mm/transparent_hugepage/enabled
echo "
soft memlock unlimited
hard memlock unlimited
mapr - nofile 65536
mapr - nproc 64000
mapr - memlock unlimited
mapr - core unlimited
mapr - nice -10
" | sudo tee -a /etc/security/limits.conf

sudo sed -i 's/defaults/defaults,nodiratime,noatime/g' /etc/fstab
echo "
blockdev --setra 8192 /dev/vdc
blockdev --setra 8192 /dev/vdd
blockdev --setra 8192 /dev/vde
for f in /sys/block/vdc /sys/block/vdd /sys/block/vde; do
  echo Disk $f configured as SSD
  echo deadline > $f/queue/scheduler
  echo 4096 > $f/queue/read_ahead_kb
  echo 32 > $f/queue/nr_requests
  echo 2 > $f/queue/nomerges
  echo 2 > $f/queue/rq_affinity
  # echo 1024 > $f/device/queue_depth
done
" | sudo tee -a /etc/rc.d/rc.local
sudo chmod +x /etc/rc.d/rc.local
# echo deadline | sudo tee /sys/block/vdc/queue/scheduler
# echo deadline | sudo tee /sys/block/vdd/queue/scheduler
# echo deadline | sudo tee /sys/block/vde/queue/scheduler

sudo sed -i 's/console=ttyS0"/console=ttyS0 elevator=deadline"/' /etc/default/grub
sudo grub2-mkconfig -o /boot/grub2/grub.cfg 
sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
sudo tuned-adm profile network-latency
# sudo rpm --import https://package.mapr.hpe.com/releases/pub/maprgpg.key

# [maprtech]
# name=MapR
# baseurl=https://package.mapr.com/releases/v6.2.0/redhat/
# enabled=1
# gpgcheck=1
# protect=1
# [maprecosystem]
# name=MapR
# baseurl=https://package.mapr.com/releases/MEP/MEP-8.0/redhat
# enabled=1
# gpgcheck=1
# protect=1

sudo yum install -y openssl11-libs java-11-openjdk-devel
# sudo yum install -y mapr-fileserver mapr-cldb mapr-zookeeper mapr-mastgateway mapr-webserver mapr-apiserver mapr-gateway mapr-loopbacknfs

# vi /opt/mapr/conf/env_override.sh
# JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk/

echo "/dev/vdc
/dev/vdd
/dev/vde" > /tmp/disks.txt

sudo /tmp/mapr-setup.sh -y

# /opt/mapr/server/configure.sh --isvm -C 192.168.1.70 -Z 192.168.1.70 -disk-opts FW3 -F /tmp/disks.txt -noDB 
