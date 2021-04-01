#!/bin/bash
# Install Realtek wlan drivers
# - these drivers cover a lot of commonly used Realtek chip sets used in Wifi USB devices
# - on older single core Raspis the compilation can take a long time (hours)!
# - the drivers are installed using DKMS and will automatically be recompiled after a kernel update
#   which again might take a long time
#
# CZ 2020

echo "Install essential packages to compile the drivers"
sudo apt --yes install git dkms build-essential raspberrypi-kernel-headers bc

echo "Get the driver packages from Github"
git clone https://github.com/aircrack-ng/rtl8812au.git
git clone https://github.com/cilynx/rtl88x2bu.git

# to avoid compiler error from __DATE__ macros -> comment these lines
find . -name "*.c" -exec grep -li __date__ {} \; | xargs sed -i '/^[^\/]/ s/\(.*__DATE__.*$\)/\/\/\ \1/'

echo "Compile the 8812au driver ..."
cd rtl8812au
sed -i 's/CONFIG_PLATFORM_I386_PC = y/CONFIG_PLATFORM_I386_PC = n/g' Makefile
sed -i 's/CONFIG_PLATFORM_ARM_RPI = n/CONFIG_PLATFORM_ARM_RPI = y/g' Makefile
sudo make dkms_install

cd ~/

echo "Compile the 88x2bu driver ..."
cd rtl88x2bu
sed -i 's/I386_PC = y/I386_PC = n/' Makefile
sed -i 's/ARM_RPI = n/ARM_RPI = y/' Makefile
VER=$(sed -n 's/\PACKAGE_VERSION="\(.*\)"/\1/p' dkms.conf)
sudo rsync -rqhP ./ /usr/src/rtl88x2bu-${VER}
sudo dkms add -m rtl88x2bu -v ${VER}
sudo dkms build -m rtl88x2bu -v ${VER}
sudo dkms install -m rtl88x2bu -v ${VER}
sudo modprobe 88x2bu

echo "Thats it ..."
