#!/bin/bash

rm -f /etc/yum.repos.d/sensingtech.repo
mkdir -p /etc/yum.repos.d/repo
mv -f /etc/yum.repos.d/*.repo /etc/yum.repos.d/repo
echo "[sensingtech]" > /etc/yum.repos.d/sensingtech.repo
echo "name=sensingtech" >> /etc/yum.repos.d/sensingtech.repo
echo "baseurl=file://$PWD" >> /etc/yum.repos.d/sensingtech.repo
echo "enabled=1" >> /etc/yum.repos.d/sensingtech.repo
echo "gpgcheck=0" >> /etc/yum.repos.d/sensingtech.repo
yum clean all
yum install ./*.rpm
createrepo -v $PWD
yum makecache
yum -y install gcc gcc-c++ kernel-devel
echo "will install cuda"
chmod +x cuda_8.0.61_375.26_linux.run
./cuda_8.0.61_375.26_linux.run --silent --driver --toolkit --verbose --no-opengl-libs --override
yum -y install net-tools ntp ruby rubygems libXrandr gtk2 libjpeg-turbo libpng gdb unzip apr libXv libglvnd  psmisc libquadmath telnet-server telnet compat-libtiff3 libpng12 openssl-devel libcurl-devel --skip-broken
sh ./NVIDIA-Linux-x86_64-390.59.run -s --no-install-libglvnd
echo "will export library"

grep -q "export LD_LIBRARY_PATH=" /etc/profile
if [[ ! $? -eq 0 ]]; then
   echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/local/cuda/lib64:." >> /etc/profile
fi

source /etc/profile

nvidia-smi
echo "INSTALL DEPENDS DONE!!!"
