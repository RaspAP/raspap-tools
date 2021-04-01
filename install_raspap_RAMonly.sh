#!/bin/bash
#
# Install RaspAP + additional Wireless drivers + minimize write access to sd-card
#
# start as user pi
#
# Options: 
#  --repo   : RaspAP github repository - default raspap/raspap-webgui 
#  --branch : branch of repository - default master 
#

RD=`tput setaf 1; tput bold`
GN=`tput setaf 2; tput bold`
DEF=`tput sgr0`

function _RAMVersion() {
  wget -q https://raw.githubusercontent.com/zbchristian/raspap-tools/main/create_RAM_version.sh -O /tmp/create_RAM_version.sh
  source /tmp/create_RAM_version.sh
}

function _installWifiDrivers() {
  wget -q https://raw.githubusercontent.com/zbchristian/raspap-tools/main/install_wifi_drivers.sh -O /tmp/install_wifi_drivers.sh
  source /tmp/install_wifi_drivers.sh
}

function _echo() {
    echo -e "${GN}$1${DEF}"
}

repo="raspap/raspap-webgui"
branch="master"

while :; do
  case "${1-}" in
      -r|--repo|--repository) repo="$2" 
      shift
      ;;
      -b|--branch) branch="$2" 
      shift
      ;;
	  *)
      break
     ;;
  esac
  shift
done

_echo "\n\nInstall RaspAP and additional Wifi drivers and configure a nearly RAM only system"
echo -e "\nRepository: $repo"
echo -e "\nBranch: $branch \n\n"

read -p "Install RaspAP with all features ( N: features can be selected ) (Y/n):" raspapyes < /dev/tty

read -p "Move log files and caches to RAM (Y/n):" ramversion < /dev/tty

read -p "Install additional drivers for Wifi adapters (e.g. Realtek) (Y/n):" wifidrivers < /dev/tty

_echo "Update system ..."
sudo apt update && sudo apt -y upgrade
sudo apt --yes install curl wget

if [ -z $ramversion ] || [[ $ramversion =~ [Yy] ]]; then
   _echo "Modify system to minimize write access to sd-card"
   _RAMVersion
fi

if [ -z $wifidrivers ] || [[ $wifidrivers =~ [Yy] ]]; then
   _echo "Install additional Wifi drivers - this might take a long time ..."
   _installWifiDrivers
fi

# unblock wlan for raspis with build in wireless
sudo rfkill unblock wlan
_echo "You should run 'sudo raspi-config' and set the 'WLAN coutry' in the localisation options"


if [ -z $raspapyes ] || [[ $raspapyes =~ [Yy] ]]; then
   _echo "Start installation of RaspAP (all features)"
   curl -sL https://install.raspap.com | sudo bash -s -- --yes --repo --branch
else
   _echo "Start installation of RaspAP"
   curl -sL https://install.raspap.com | sudo bash -s -- --repo $repo --branch $branch
fi

_echo "The system should be rebooted now"

