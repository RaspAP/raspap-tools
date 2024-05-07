#!/bin/bash
#

RED="\e[31m\e[1m"
GREEN="\e[32m\e[1m"
DEF="\e[0m"

function _echo() {
    txt=$1;col="$GREEN"
    [ $# == 2 ] && txt=$2 && col=$1
    echo -e "${col}$txt${DEF}"
}

_echo "$RED" "\n\n WLAN modules from MrEngman - http://downloads.fars-robotics.net are no longer available \n\n"
_echo "\n Use instead the script install_wlan_driver.sh \n\n"
