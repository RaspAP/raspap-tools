#!/bin/bash
# install Realtek wlan drivers 
sudo apt install git dkms build-essential raspberrypi-kernel-headers bc
git clone https://github.com/aircrack-ng/rtl8812au.git
git clone https://github.com/cilynx/rtl88x2bu.git

# to avoid compiler error from __DATE__ macros -> comment these lines
find . -name "*.c" -exec grep -li __date__ {} \; | xargs sed -i '/^[^\/]/ s/\(.*__DATE__.*$\)/\/\/\ \1/'

cd rtl8812au
sed -i 's/CONFIG_PLATFORM_I386_PC = y/CONFIG_PLATFORM_I386_PC = n/g' Makefile
sed -i 's/CONFIG_PLATFORM_ARM_RPI = n/CONFIG_PLATFORM_ARM_RPI = y/g' Makefile
sudo make dkms_install

cd ~/
cd rtl88x2bu
sed -i 's/I386_PC = y/I386_PC = n/' Makefile
sed -i 's/ARM_RPI = n/ARM_RPI = y/' Makefile
VER=$(sed -n 's/\PACKAGE_VERSION="\(.*\)"/\1/p' dkms.conf)
sudo rsync -rqhP ./ /usr/src/rtl88x2bu-${VER}
sudo dkms add -m rtl88x2bu -v ${VER}
sudo dkms build -m rtl88x2bu -v ${VER}
sudo dkms install -m rtl88x2bu -v ${VER}
sudo modprobe 88x2bu

