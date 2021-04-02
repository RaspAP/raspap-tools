#!/bin/bash
# RASPBERRY PI: limit the sd-card write operation to a minimum by moving temporary and log files to RAM
# - Write access can be checked with "iotop -aoP"
# - Remaining access originates mainly from the ext4 journal update (process jbd2)  
#
# tested with Raspian lite Buster 
# CZ 2020

echo "Update system ..."
sudo apt update && sudo apt -y upgrade

echo "Remove some packages ..."

sudo apt -y remove --purge triggerhappy dphys-swapfile logrotate 
sudo apt -y autoremove --purge

echo "Disable services ..."

sudo systemctl disable bootlogs
sudo systemctl disable console-setup
sudo systemctl disable apt-daily.service apt-daily.timer apt-daily-upgrade.timer apt-daily-upgrade.service

echo "Install new logger ..."
sudo apt-get -y install busybox-syslogd
sudo dpkg --purge rsyslog

echo "Modify boot options to switch off swap and file system check ..."
# disable swap 
if ! grep -q "noswap" /boot/cmdline.txt; then
 sudo sed -i '1 s/$/ fsck.mode=skip noswap/' /boot/cmdline.txt
fi

echo "Add tmpfs entries to /etc/fstab ..."
# move directories to RAM
dirs=( "/tmp" "/var/log" "/var/tmp" "/var/lib/misc" "/var/cache")
# special dirs used by vnstat and php
dirs+=( "/var/lib/vnstat" "/var/php/sessions" )

for dir in "${dirs[@]}"; do
  if ! grep -q " $dir " /etc/fstab; then
    echo "tmpfs $dir tmpfs  nosuid,nodev 0 0" | sudo tee -a /etc/fstab
  fi
done 

echo "Add commands ro and rw to .bashrc ..."
echo "alias rw='sudo mount / -o remount,rw;  sudo mount /boot -o remount,rw'" >> .bashrc
echo "alias ro='sudo mount / -o remount,ro; sudo mount /boot -o remount,ro'" >> .bashrc

# FOR A REAL READ-ONLY SYSTEM, UNCOMMENT THE LAST 4 LINES OF THIS BLOCK
# THIS WILL MOUNT THE FILE SYSTEM AS read-only
# - makes only sense, when the RaspAP configuration is stable and shoudl not be changed 
# - MIGHT NOT WORK WITH SOME SYSTEMD SERVICES, CHECK LOGS!!!
#if ! grep -q ",ro" /etc/fstab; then
#  sudo sed -i -r 's/\/boot(.*)defaults/\/boot\1defaults,ro/' /etc/fstab
#  sudo sudo sed -i -r 's/\/ (.*)defaults/\/ \1defaults,ro/' /etc/fstab
#fi

echo "You should reboot now ..."

