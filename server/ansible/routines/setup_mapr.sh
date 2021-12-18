#!/usr/bin/env bash
 
yum install -y perl java-11-openjdk java-11-openjdk-devel wget curl

hostnamectl set-hostname df-demo.local
 
mep=mep8.1_2021_12_09
distrib=distrib_2021_12_12
release=20211212032616
 
echo $mep
echo $distrib
echo $release
 
groupadd -g 5000 mapr
useradd -u 5000 -g 5000 -d /home/mapr -s /bin/bash mapr
echo 'mapr:mapr' | chpasswd
usermod -a -G wheel mapr
 
mkdir /mapr
 
rpm --import https://package.mapr.hpe.com/releases/pub/maprgpg.key
 
# concerning the rpm names – they are not aligned in the build release
 
yum install -y /opal/$mep/mapr-librdkafka-0.11.3.202110181609-1.x86_64.rpm
yum install -y /opal/$mep/mapr-hadoop-util-2.7.6.200.202112091535-1.x86_64.rpm
yum install -y /opal/$distrib/mapr-client-7.0.0.0.$release.GA-1.x86_64.rpm
yum install -y /opal/$distrib/mapr-core-internal-7.0.0.0.$release.GA-1.x86_64.rpm
yum install -y /opal/$distrib/mapr-core-7.0.0.0.$release.GA-1.x86_64.rpm
yum install -y /opal/$distrib/mapr-fileserver-7.0.0.0.$release.GA-1.x86_64.rpm
yum install -y /opal/$distrib/mapr-cldb-7.0.0.0.$release.GA-1.x86_64.rpm
yum install -y /opal/$distrib/mapr-zk-internal-7.0.0.0.$release.GA-1.x86_64.rpm
yum install -y /opal/$distrib/mapr-zookeeper-7.0.0.0.$release.GA-1.x86_64.rpm
yum install -y /opal/$distrib/mapr-s3server-7.0.0.0.$release.GA-1.x86_64.rpm
yum install -y /opal/$distrib/mapr-apiserver-7.0.0.0.20211211191036-1.noarch.rpm
yum install -y /opal/$distrib/mapr-webserver-7.0.0.0.20211211191036-1.noarch.rpm
yum install -y /opal/$distrib/mapr-loopbacknfs-7.0.0.0.$release.GA-1.x86_64.rpm
#yum install -y /opal/$distrib/mapr-nfs-7.0.0.0.$release.GA-1.x86_64.rpm
 
# to create flat file storage
# mkdir /data

# dd if=/dev/zero of=/data/storagefile bs=1G count=20

# echo “/data/storagefile” > /tmp/disks.txt 
echo "/dev/vdc" > /tmp/disks.txt
echo "/dev/vdd" >> /tmp/disks.txt
 
/opt/mapr/server/configure.sh -Z ${HOSTNAME} -C ${HOSTNAME}:7222 -N dfdemo.mapr.io -F /tmp/disks.txt  -unsecure
 #For mep components
/opt/mapr/server/configure.sh -R
 #register demo licence
# maprcli license add -license LatestDemoLicense-M7.txt -is_file true
 