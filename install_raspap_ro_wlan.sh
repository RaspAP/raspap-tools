#!/bin/bash
#
# Install RaspAP + additional Wireless drivers + minimize write access to sd-card
# ===============================================================================
# - Write Raspian lite to a SD-card
# - Create a file with name "ssh" (no extension) on the partition called "boot", to allow for SSH access
# - start the Raspberry PI with the SD-Card and login via ssh (default user: pi, password: raspberry)
# - download this script: "wget https://raw.githubusercontent.com/zbchristian/raspap-tools/main/install_ro_wlan.sh"
# - chmod +x install_raspap_ro_wlan.sh
# - ./install_raspap_ro_wlan.sh
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
  wget -q https://raw.githubusercontent.com/zbchristian/raspap-tools/main/raspian_readonly.sh -O /tmp/raspian_readonly.sh
  source /tmp/raspian_readonly.sh
}

function _installWifiDrivers() {
  wget -q https://raw.githubusercontent.com/zbchristian/raspap-tools/main/install_wlan_driver_modules.sh -O /tmp/install_wifi_drivers.sh
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
_echo "\nYou should run 'sudo raspi-config' and set the 'WLAN coutry' in the localisation options\n"

if [ -z $raspapyes ] || [[ $raspapyes =~ [Yy] ]]; then
   _echo "Start installation of RaspAP (all features)"
    curl -sL https://install.raspap.com | sudo bash -s -- --yes $raspapopts
else
   _echo "Start installation of RaspAP"
    curl -sL https://install.raspap.com | sudo bash -s -- $raspapopts
fi

_echo "The system should be rebooted now"
