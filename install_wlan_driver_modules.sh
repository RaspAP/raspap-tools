#!/bin/bash
#
# Install wlan driver for device(s) from http://downloads.fars-robotics.net/
# The WLAN USB device has to be connected one after the other
#

RED="\e[31m"
GREEN="\e[32m"
DEF="\e[0m"

function _echo() {
    txt=$1;col="$GREEN"
	[ $# == 2 ] && txt=$2 && col=$1
    echo -e "${col}$txt${DEF}"
}

_echo "\n\nInstall driver for connected WLAN adapter\n"
_echo "Utilizing the Raspberry Pi wifi driver installer by MrEngman - http://downloads.fars-robotics.net/\n"
echo -e "You will be prompted to connect the device(s) one by one.\n"

sudo wget http://downloads.fars-robotics.net/wifi-drivers/install-wifi -O /usr/local/sbin/install-wifi.sh
sudo chmod +x /usr/local/sbin/install-wifi.sh

while :; do
  echo -ne "${GN}Connect a wlan device and press RETURN ( Q to quit) ${DEF}"
  read OK < /dev/tty
  if [ ! -z $OK ] && [[ $OK =~ [Qq] ]]; then
     _echo "  Installation done - exit"
     break
  fi
  check=$(sudo /usr/local/sbin/install-wifi.sh -c )
#  echo $check
  found=$( echo $check | grep -oP unrecognised )
#  echo "found $found"
  if [ -z $found ]; then
	device=$( echo "$check" | sed -rn 's/.*wifi module is.*ID(.*)$/\1/p' )
	driver=$( echo "$check" | sed -rn 's/And it uses the (.*)\s.*$/\1/p')
	_echo "Install driver $driver for $device ..."
    sudo /usr/local/sbin/install-wifi.sh $driver
  else
	_echo "RD" "No device connected or not recognized. Driver might already be installed."
	echo "Connected USB devices are: "
	lsusb
  fi
done
