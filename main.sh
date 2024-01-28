#! /bin/bash
DRIVER=545

echo 'Package: *' > /etc/apt/preferences.d/0-a
echo 'Pin: release c=main' >> /etc/apt/preferences.d/0-a
echo 'Pin-Priority: 400' >> /etc/apt/preferences.d/0-a
echo 'Package: *' > /etc/apt/preferences.d/0-b
echo 'Pin: release c=ubuntu' >> /etc/apt/preferences.d/0-b
echo 'Pin-Priority: 400' >> /etc/apt/preferences.d/0-b
apt update -y
echo "$(apt show nvidia-driver-$DRIVER 2>&1 | grep -v "does not have a stable" | grep Version: | head -n1 | cut -f2 -d":" | cut -f1,2,3 -d"." | cut -f1 -d"-" | tr -d ' ')" > ./linux-nvidia-modules/DRIVER
echo "$(apt show kernel-pika 2>&1 | grep -v "does not have a stable" | grep Depends: | head -n1 | cut -f2 -d":" | cut -f1 -d"," | cut -f3,4 -d"-" | tr -d ' ')" > ./linux-nvidia-modules/KERNEL
echo "$(apt show nvidia-kernel-source-$DRIVER 2>&1 | grep -v "does not have a stable" | grep Version: | head -n1 | cut -f2 -d":" | tr -d ' ')" > ./linux-nvidia-modules/DRIVER_VERSION
echo "$(apt show nvidia-driver-$DRIVER 2>&1 | grep -v "does not have a stable" | grep Depends: | head -n1 | cut -f2 -d":" | cut -f1 -d"," | cut -f3,4 -d"-" | tr -d ' ')"  > ./linux-nvidia-modules/DRIVER_PIKA

cd ./linux-nvidia-modules

VERSION="$(cat ./DRIVER)-$(cat ./KERNEL)-100pika5"

if echo $VERSION | grep $(cat ./DRIVER_PIKA)
then
  echo "Driver up to date"
  exit 0
fi

echo -e "Source: linux-nvidia-modules\nSection: graphics\nPriority: optional\nMaintainer: Ward Nakchbandi <hotrod.master@hotmail.com>\nStandards-Version: 4.6.1\nBuild-Depends: debhelper-compat (= 13), linux-image-$(cat ./KERNEL), linux-headers-$(cat ./KERNEL), dkms, fakeroot\nRules-Requires-Root: no\n\nPackage: linux-modules-nvidia-$DRIVER-$(cat ./KERNEL)\nArchitecture: linux-any\nDepends: linux-image-$(cat ./KERNEL), linux-headers-$(cat ./KERNEL), $(apt-cache show nvidia-dkms-$DRIVER | grep Depends: | head -n1 | cut -f2 -d":")\nConflicts: nvidia-6.5.0-pikaos-module-535, nvidia-$(cat ./KERNEL)-module-$DRIVER, "$(apt list 2>/dev/null | cut -d'/' -f1 | grep linux-modules-nvidia | grep $(cat ./KERNEL) | grep -v  linux-modules-nvidia-$DRIVER-$(cat ./KERNEL) | sed ':a;N;$!ba;s/\n/, /g')", nvidia-dkms-$DRIVER (= $(cat DRIVER_VERSION))\nProvides: linux-modules-nvidia-$(cat ./KERNEL), nvidia-dkms-$DRIVER (= $(cat DRIVER_VERSION))\nReplaces: nvidia-dkms-$DRIVER (= $(cat DRIVER_VERSION))\nDescription: Prebuilt Nvidia module for PikaOS kernel\n\nPackage: nvidia-pika-kernel-module-$DRIVER\nArchitecture: linux-any\nDepends: linux-modules-nvidia-$DRIVER-$(cat ./KERNEL) $(echo '(= ${binary:Version})')\nDescription: DKMS NVIDIA PLACEHOLDER" > ./debian/control
echo -e "usr" > ./debian/linux-modules-nvidia-$DRIVER-$(cat ./KERNEL).install

echo "cp -vf /usr/lib/pika/nvidia-$(cat ./DRIVER)-$(cat ./KERNEL)/blacklist-pika-nouveau.conf /etc/modprobe.d/blacklist-pika-nouveau.conf" >> ./debian/postinst
echo "cp -vf /usr/lib/pika/nvidia-$(cat ./DRIVER)-$(cat ./KERNEL)/pika-nvidia.conf /etc/modules-load.d/pika-nvidia.conf" >> ./debian/postinst

echo -e "DRIVER=$(cat ./DRIVER)\nKERNEL=$(cat ./KERNEL)\nVERSION=$(cat ./DRIVER_VERSION)\nMK_WORKDIR=$(env | grep -w "PWD" | cut -c5-)\nCARCH=x86_64" > ./Makefile
cat ./Makefiletmp >> ./Makefile

DEBIAN_FRONTEND=noninteractive

# Get build deps
apt-get build-dep ./ -y
apt download nvidia-kernel-source-$DRIVER -y
dpkg-deb -x ./nvidia-kernel-source-$DRIVER*.deb /
apt download nvidia-dkms-$DRIVER -y
dpkg-deb -x ./nvidia-dkms-$DRIVER*.deb /

# Build package
dpkg-buildpackage --no-sign
echo 'DKMS MAKEFILE LOG:'
cat ./nvidia/$(cat ./DRIVER)/$(cat ./KERNEL)/x86_64/log/make.log || cat ./nvidia/$(cat ./DRIVER)/build/make.log
# Move the debs to output
cd ../
mkdir -p ./output
mv ./*.deb ./output/
