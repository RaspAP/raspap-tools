#!/bin/bash
#
# Install RaspAP + additional Wireless drivers + minimize write access to sd-card
# ===============================================================================
# - Write Raspberry Pi OS to a SD-card
# 	o Do not forget to enable ssh access and set the user/password
#   o Set the WIFI parameters, if you want to access the Pi this way
# - start the Raspberry PI with the SD-Card and login via ssh
# - download this script: "wget https://raw.githubusercontent.com/RaspAP/raspap-tools/main/install_raspap_ram_wlan.sh"
# - chmod +x install_raspap_ram_wlan.sh
# - ./install_raspap_ram_wlan.sh
#
# zbchristian 2024
#

RED="\e[31m\e[1m"
GREEN="\e[32m\e[1m"
DEF="\e[0m"

function _echo() {
    txt=$1;col="$GREEN"
    [ $# == 2 ] && txt=$2 && col=$1
    echo -e "${col}$txt${DEF}"
}

function _RAMVersion() {
  wget -q https://raw.githubusercontent.com/RaspAP/raspap-tools/main/raspian_min_write.sh -O /tmp/raspian_min_write.sh
  source /tmp/raspian_min_write.sh
}

function _installWifiDrivers() {
# As of January 2022, fars-robotics.net is no longer updating the modules
#  wget -q https://raw.githubusercontent.com/RaspAP/raspap-tools/main/install_wlan_driver_modules.sh -O /tmp/install_wifi_drivers.sh

# install drivers from source via DKMS
  wget -q https://raw.githubusercontent.com/RaspAP/raspap-tools/main/install_wlan_drivers.sh -O /tmp/install_wifi_drivers.sh
  source /tmp/install_wifi_drivers.sh
}

_echo "\n\nInstall RaspAP, additional Wifi drivers and configure a nearly RAM only system"

read -p "Do you want to install the standard version of RaspAP (raspap/raspap-webgui) (Y/n) :" raspapsel < /dev/tty
raspapopts=""
if [ ! -z $raspapsel ] && [[ $raspapsel =~ [Nn] ]]; then
    read -p "Enter the installation options for RaspAP :" raspapopts < /dev/tty
fi

read -p "Install RaspAP with all features ( N: features can be selected ) (Y/n):" raspapyes < /dev/tty

read -p "Move log files and caches to RAM (Y/n):" ramversion < /dev/tty

read -p "Install additional drivers for Wifi adapters (e.g. Realtek) (Y/n):" wifidrivers < /dev/tty

#_echo "Update system ..."
#sudo apt update && sudo apt -y upgrade
sudo apt --yes install curl wget

if [ -z $ramversion ] || [[ $ramversion =~ [Yy] ]]; then
   _echo "Modify system to minimize write access to sd-card"
   _RAMVersion
fi

if [ -z $wifidrivers ] || [[ $wifidrivers =~ [Yy] ]]; then
   _echo "Install additional Wifi drivers ..."
   _installWifiDrivers
fi

# unblock wlan for raspis with build in wireless
sudo rfkill unblock wlan
_echo "\nYou should run 'sudo raspi-config' and set the 'WLAN coutry' in the localisation options, if not set already OS installation\n"

wget -q https://install.raspap.com -O install_raspap.sh
chmod +x install_raspap.sh
if [ -z $raspapyes ] || [[ $raspapyes =~ [Yy] ]]; then
   _echo "Start installation of RaspAP (all features)"
   ./install_raspap.sh --yes $raspapopts
#    curl -sL https://install.raspap.com | sudo bash -s -- --yes $raspapopts
else
   _echo "Start installation of RaspAP"
   ./install_raspap.sh $raspapopts
#    curl -sL https://install.raspap.com | sudo bash -s -- $raspapopts
fi

_echo "The system should be rebooted now"

q