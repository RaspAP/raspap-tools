#!/bin/bash
# RASPBERRY PI: limit the sd-card write operation to a minimum by moving temporary and log files to RAM
# - Write access can be checked with "iotop -aoP"
# - Remaining access originates mainly from the ext4 journal update (process jbd2)  
#
# tested with Raspian lite Buster 
# zbchristian 2020

function _dirs2tmpfs() {
  for dir in "${dirs[@]}"; do
    echo "Move $dir to RAM"
    if ! grep -q " $dir " /etc/fstab; then
      echo "tmpfs $dir tmpfs  nosuid,nodev 0 0" | sudo tee -a /etc/fstab
    fi
  done 
}

RED="\e[31m\e[1m"
GREEN="\e[32m\e[1m"
DEF="\e[0m"

echo -e "${GREEN}\n\nModify System to minimize the Write Access to the SD-Card${DEF}\n"

echo -e "${GREEN}Remove some packages ...${DEF}"

sudo apt -y remove --purge triggerhappy dphys-swapfile logrotate 
sudo apt -y autoremove --purge

echo -e "${GREEN}Disable services ...${DEF}"

sudo systemctl unmask bootlogd.service
sudo systemctl disable bootlogs
sudo systemctl disable console-setup
sudo systemctl disable apt-daily.service apt-daily.timer apt-daily-upgrade.timer apt-daily-upgrade.service

echo -e "${GREEN}Install new logger ...${DEF}"
sudo apt-get -y install busybox-syslogd
sudo dpkg --purge rsyslog

echo -e "${GREEN}Modify boot options to switch off swap and file system check ...${DEF}"
# disable swap 
if ! grep -q "noswap" /boot/cmdline.txt; then
 sudo sed -i '1 s/$/ fsck.mode=skip noswap/' /boot/cmdline.txt
fi

echo -e "${GREEN}Add tmpfs entries to /etc/fstab ...${DEF}"
# move directories to RAM
dirs=( "/tmp" "/var/log" "/var/tmp" "/var/lib/misc" "/var/cache")
# special dirs used by vnstat and php
dirs+=( "/var/lib/vnstat" "/var/php/sessions" )
_dirs2tmpfs

echo -e "${RED}You should reboot now ...${DEF}"

