#!/bin/bash
# RASPBERRY PI: limit the sd-card write operation to a minimum by moving temporary and log files to RAM
# - Write access can be checked with "iotop -aoP"
# - Remaining access originates mainly from the ext4 journal update (process jbd2)  
#
# Option: -ro  : enable the option to mount /boot and / as read-only 
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

[ $# == 1 ] && isRO=true || isRO=false 


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


if [ $isRO = true ];  then
	# MOUNT THE FILE SYSTEMS AS read-only
	# - makes only sense, when the Raspian configuration is stable and will not be changed 
	# - MIGHT NOT WORK WITH SOME SYSTEMD SERVICES, CHECK LOGS!!!
	echo -e "${RED}"
	echo    "Mounting the root filesystem as read-only might render your system unusable!" 
	echo    "This makes only sense for a completely configured and stable system." 
	read -p "Mount /boot and the root system as Read-Only ? (y/N) :" mountRO < /dev/tty
	echo -e "${DEF}"
	if [ ! -z $mountRO ] && [[ $mountRO =~ [Yy] ]]; then
		if ! grep -q ",ro" /etc/fstab; then
			sudo sed -i -r 's/\/boot(.*)defaults/\/boot\1defaults,ro/' /etc/fstab
			sudo sed -i -r 's/\/ (.*)defaults/\/ \1defaults,ro/' /etc/fstab
		fi
		echo -e "${GREEN}Move more directorie(s) to RAM ...${DEF}"
		dirs=( "/var/lib/dhcp" "/var/lib/dhcpcd5" )
		_dirs2tmpfs
		echo -e "${GREEN}Install NTP and disable systemd-timesyncd ...${DEF}"
		sudo apt -y install ntp
		sudo systemctl disable systemd-timesyncd
		sudo systemctl enable ntp
		echo -e "${GREEN}Move resolv.conf to /run ...${DEF}"
		sudo cp /etc/resolv.conf /run/resolv.conf
		sudo ln -sf /run/resolv.conf /etc/resolv.conf
		echo -e "${GREEN}Add the commands for a quick remount of the root system to .bashrc ${DEF}"
		echo -e "${GREEN}Command: rw - remount filesystem as read and writeable${DEF}"
		echo -e "${GREEN}         ro - remount filesystem as read-only${DEF}"
		echo "alias rw='sudo mount / -o remount,rw;  sudo mount /boot -o remount,rw'" >> .bashrc
		echo "alias ro='sudo mount / -o remount,ro; sudo mount /boot -o remount,ro'" >> .bashrc
	fi
else
	echo -e "${GREEN}To obtain a real READ-ONLY system, configure the system and rerun this script with option -ro:${DEF} `basename $0 ` -ro "
fi


echo -e "${RED}You should reboot now ...${DEF}"

