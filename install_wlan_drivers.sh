#!/bin/bash
#
# Compile and install usb wlan drivers on a Raspberry Pi
# The WLAN USB device has to be connected one after the other
#
# Parameters: none          - ask to attach device
#             driver-name   - install that specified driver only
#             anything else - return list of drivers
#
# 2022 zbchristian

# list of drivers. For each driver a function _NAME has to exist
drivers=( rtl8814au rtl8812au rtl88x2bu rtl8821cu )

# check for memory < 1GB and limit processes
 isMem=$(cat /proc/meminfo | sed -rn 's/Memtotal:\s*([0-9]*).*/\1/ip')
[ "$isMem" -lt $((1024*1024)) ] && maxProc=2 || maxProc=8

RED="\e[31m\e[1m"
GREEN="\e[32m\e[1m"
DEF="\e[0m"

function _echo() {
    txt=$1;col="$GREEN"
    [ $# == 2 ] && txt=$2 && col=$1
    echo -e "${col}$txt${DEF}"
}

function _askUser() {
    # check for existing driver
    mod=$(lsmod | grep -io "$1" | head -1)
    if [ ! -z "$mod" ]; then
       _echo "$RED" "NOTE: driver ( $mod ) is already installed for this device"
    fi
    echo -ne "Install the driver "$2"? (y/N)${DEF}"
    read RE < /dev/tty
    if [ ! -z $RE ] && [[ $RE =~ [yY] ]]; then return 1; fi
    return 0
}

function _configCompile() {
    # check architecture (32 or 64bit)
    bits=$(getconf LONG_BIT)
    # to avoid compiler error from __DATE__ macros -> comment these lines
    find . -name "*.c" -exec grep -li __date__ {} \; | xargs sed -i '/^[^\/]/ s/\(.*__DATE__.*$\)/\/\/\ \1/'
    # compile on raspberry pi
    sed -i 's/CONFIG_PLATFORM_I386_PC = y/CONFIG_PLATFORM_I386_PC = n/g' Makefile
    if [ "$bits" -eq "64" ]; then
       sed -i 's/CONFIG_PLATFORM_ARM64_RPI = n/CONFIG_PLATFORM_ARM64_RPI = y/g' Makefile
    else
       sed -i 's/CONFIG_PLATFORM_ARM_RPI = n/CONFIG_PLATFORM_ARM_RPI = y/g' Makefile
    fi
}
	
}

function _installFromDKMSconf() {
    if [ ! -f dkms.conf ]; then 
        echo "DKMS install failed - missing dkms.conf"
        return 1
    fi
    
    # check if multi core compile is set
    if ! grep -oP "MAKE.*-j.*KVER=" dkms.conf; then
       np=`nproc`
       [ "$np" -gt "$maxProc" ] && np="$maxProc"
       sed  -i "s/KVER=/-j$np KVER=/" dkms.conf;
    elif [ "$maxProc" -lt $(nproc) ]; then
	   sed -i "s/-j[^ \s]*/-j$maxProc/" dkms.conf
	fi

    VER=$(sed -n 's/PACKAGE_VERSION="\(.*\)"/\1/p' dkms.conf)
    NAM=$(sed -n 's/PACKAGE_NAME="\(.*\)"/\1/p' dkms.conf)
    MOD=$(sed -n 's/BUILT_MODULE_NAME.*="\(.*\)"/\1/p' dkms.conf)
    if [ -z $VER ] || [ -z $MOD ]; then return 1; fi
    sudo rsync --exclude=.git -rqhP ./ /usr/src/${NAM}-${VER}
    sudo dkms add -m ${NAM} -v ${VER}
    sudo dkms build -m ${NAM} -v ${VER}
    sudo dkms install -m ${NAM} -v ${VER}
    sudo modprobe ${MOD}
    echo "DKMS install done"
    return 0
}

function _rtl8814au() {
    drv="${FUNCNAME:1}"
    [ $# == 1 ] && install=0 || install=1

    # vid:pid from fars-robotics.net
    vidpid='rtl8814au'
    vidpid+='|0846:9054'
    vidpid+='|0b05:1817'
    vidpid+='|0bda:8813'
    vidpid+='|2357:0106'

    if [ $install == 0 ] || cat .lsusb | grep -iE "$vidpid" > /dev/null; then
        repo="aircrack-ng/rtl8814au.git"
        echo "Found device/install driver $drv ... compile and install from Github repository $repo"
        if _askUser '88[x1][x4]au' "$drv"; then return 1; fi
        _echo "$RED" "--- Please give feedback about success and problems with this driver ---"
        git clone https://github.com/$repo "$drv"
        cd "$drv"
        _configCompile
        sudo make dkms_install
        echo "done"
        return 0
    fi
    return 1
    
}

function _rtl8821cu() {
    drv="${FUNCNAME:1}"
    [ $# == 1 ] && install=0 || install=1

    # vid:pid from fars-robotics.net
    vidpid='rtl8821cu'
    vidpid+='|2001:331D'
    vidpid+='|0BDA:2006|0BDA:8811|0BDA:C811|0BDA:C82B|0BDA:C82A|0BDA:C820|0BDA:C821|0BDA:B820|0BDA:B82B'

    if [ $install == 0 ] || cat .lsusb | grep -iE "$vidpid" > /dev/null; then
        repo="morrownr/8821cu-20210118.git"
        echo "Found device/install driver $drv ... compile and install from Github repository $repo"
        if _askUser '8821cu' "$drv"; then return 1; fi
        _echo "$RED" "--- Please give feedback about success and problems with this driver ---"
        git clone https://github.com/$repo "$drv"
        cd "$drv"
        _configCompile
        _installFromDKMSconf
        return 0
    fi
    return 1
}

function _rtl8812au() {
    drv="${FUNCNAME:1}"
    [ $# == 1 ] && install=0 || install=1
    
    # vid:pid from fars-robotics.net
    vidpid='rtl881[124]au'
    vidpid+='|0846:9054'
    vidpid+='|20F4:809B|20F4:809A'
    vidpid+='|7392:A833|7392:A834|7392:A822|7392:A813|7392:A812|7392:A811'
    vidpid+='|056E:400D|056E:400B|056E:400F|056E:400E|056E:4007'
    vidpid+='|0B05:1853|0B05:1852|0B05:1817|0B05:17D2'
    vidpid+='|2001:331A|2001:3318|2001:3314|2001:3316|2001:3315|2001:3313|2001:330E'
    vidpid+='|0BDA:8813|0BDA:881C|0BDA:881B|0BDA:881A|0BDA:8812'
    vidpid+='|2357:0120|2357:0122|2357:011F|2357:011E|2357:0106|2357:0122'
    vidpid+='|2357:010F|2357:010E|2357:0115|2357:010D|2357:0103|2357:0101'
    vidpid+='|3823:6249'
    vidpid+='|0411:029B|0411:0242|0411:025D'
    vidpid+='|2019:AB32|2019:AB30'
    vidpid+='|0E66:0023|0E66:0022'
    vidpid+='|04BB:0953|04BB:0952'
    vidpid+='|0BDA:0823|0BDA:0820|0BDA:A811|0BDA:8822|0BDA:0821|0BDA:0811'
    vidpid+='|2604:0012'
    vidpid+='|148F:9097'
    vidpid+='|050D:1109|050D:1106'
    vidpid+='|20F4:805B'
    vidpid+='|13B1:003F'
    vidpid+='|0846:9052|0846:9051'
    vidpid+='|07B8:8812'
    vidpid+='|1740:0100'
    vidpid+='|1058:0632'
    vidpid+='|0586:3426'
    vidpid+='|0409:0408'
    vidpid+='|0789:016E'
    vidpid+='|0DF6:0074'

    if [ $install == 0 ] || cat .lsusb | grep -iE "$vidpid" > /dev/null; then
        repo="aircrack-ng/rtl8812au.git"
        echo "Found device/install driver $drv ... compile and install from Github repository $repo"
        if _askUser '88[x1][x124]au' "$drv"; then return 1; fi
        git clone https://github.com/$repo "$drv"
        cd "$drv"
        _configCompile
        sudo make dkms_install
        echo "done"
        return 0
    fi
    return 1
}

function _rtl88x2bu() {
    drv="${FUNCNAME:1}"
    [ $# == 1 ] && install=0 || install=1

    # vid:pid from fars-robotics.net
    vidpid='rtl88[12]2bu'
    vidpid+='|13B1:0043'
    vidpid+='|2001:331E|2001:331C'
    vidpid+='|0846:9055'
    vidpid+='|20F4:808A'
    vidpid+='|0E66:0025'
    vidpid+='|2357:012D|2357:0138|2357:0115'
    vidpid+='|0B05:1841|0B05:184C|0B05:1812'
    vidpid+='|7392:C822|7392:B822'
    vidpid+='|0BDA:B812|0BDA:B82C'

    if [ $install == 0 ] || cat .lsusb | grep -iE "$vidpid" > /dev/null; then
        repo="cilynx/rtl88x2bu.git"
        echo "Found device/install driver $drv ... compile and install from Github repository $repo"
        if _askUser '88[x12][x2]bu' "$drv"; then return 1; fi
        git clone https://github.com/$repo "$drv"
        cd "$drv"
        _configCompile
        _installFromDKMSconf
        return 0
    fi
    return 1
}

# -----------------------------------------------------------------------------------

_echo "\n\n\nCompile and install driver for WLAN adapter\n"

fstat=/tmp/$(basename "$0").stat
if [ ! -f $fstat ]; then
    echo "Install essential packages to compile the drivers"
    sudo apt --yes install git dkms build-essential raspberrypi-kernel-headers bc
    touch /tmp/$(basename "$0").stat
fi

if [ $# == 1 ]; then
    if [[ "${drivers[@]}" =~ "$1" ]] && declare -F "_$1" > /dev/null; then
        _$1 "install"
        exit
    else
        _echo "$RED" "No method to install driver $1 found ..."
        echo "To install a single driver, pass one of the following: ${drivers[*]}"
        exit
    fi
fi

echo -e "You will be prompted to connect the device(s) one by one.\n"

mkdir /tmp/wlan-drivers

while :; do
    cd /tmp/wlan-drivers
    echo -ne "${GREEN}Connect a single wlan device and press RETURN ( Q to quit) ${DEF}"
    read OK < /dev/tty
    if [ ! -z $OK ] && [[ $OK =~ [Qq] ]]; then
        _echo "  Thats it ..."
        break
    fi
    lsusb > .lsusb
    ret=1
    # loop over list of drivers
    for drv in "${drivers[@]}"
    do
        if declare -F "_$drv" > /dev/null; then 
            if _$drv ; then ret=0; break; fi
        fi
    done 
    if [ $ret == 0 ]; then continue; fi
    _echo "$RED" "No device connected or not recognized. Driver might already be installed."
    echo "Connected USB devices are: "
    cat .lsusb
    echo -e "\nList of drivers handled by this script: ${drivers[*]} \n"
done
