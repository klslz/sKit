#!/bin/sh
#
# soundcheck's tuning kit - pCP - sKit-led-manager.sh
# enables and disables LEDs on piCorePlayer
# for RPi3 and RPi4 and related CM modules
#
# Latest Update: Apr-26-2021
#
#
# Copyright © 2021 - Klaus Schulz
# All rights reserved
# 
# This program is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License 
# as published by the Free Software Foundation, 
# either version 3 of the License, or (at your option) 
# any later version.
#
# This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied warranty 
# of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
# See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License 
# along with this program. 
#
# If not, see http://www.gnu.org/licenses
#
########################################################################
VERSION=1.2
sKit_VERSION=1.4

fname="${0##*/}"
opts="$@"

###functions############################################################
colors() {

    RED='\033[0;31m'
    GREEN="\033[0;32m"
    YELLOW="\033[0;33m" 
    NC='\033[0m'
}


out() {

    echo -e "\tprogram aborted"
    echo -e "\t${RED}ERROR: $@ ${NC}"
    DONE
    exit 1
}


line() {

    echo -e "${RED}_______________________________________________________________${NC}\n"
}


checkroot() {

    (( EUID != 0 )) && out "root privileges required"
}


header() {

    line
    echo -e "\t     sKit - LED manager ($VERSION)"
    echo -e "\t       (c) soundcheck"
    echo
    echo -e "\t      welcome $(id -un)@$(hostname)"
    line
}


DONE() {

    line
}


countdown() {

    counter=$1
    while [[ "$counter" -gt 0 ]]; do


        echo -ne -e "\t>> $counter \r"
        let counter--
        sleep 1

    done
    echo -e "\t>> 0"
    line
}


reboot_system() {

   if [[ "$REBOOT" == "true" ]]; then

        echo -e "\trebooting system in"
        countdown 10
        sync
        sudo reboot

   fi
}

###################################

license() {

    line
    echo "
    soundcheck's tuning kit (${fname})
    
    Copyright © 2021 - Klaus Schulz (aka soundcheck)
    All rights reserved

    This program is free software: you can redistribute it and/or
    modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation,
    either version 3 of the License, or (at your option) 
    any later version.
    
    This program is distributed in the hope that it will be useful, 
    but WITHOUT ANY WARRANTY; without even the implied warranty 
    of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
    See the GNU General Public License for more details.
    You should have received a copy of the GNU General Public License 
    along with this program. 

    If not, see http://www.gnu.org/licenses
    "
    line
    while true; do

        read -t 120 -r -p "    Confirm terms? (y/n)  : " yn
        case $yn in

            [Yy]* ) break;;
            [Nn]* ) DONE;exit;;
                * ) echo -e "\tPlease answer yes or no.";;

         esac

    done
    clear
}


env_set() {

    TCE=/mnt/mmcblk0p2/tce 
    sKitbase=$TCE/sKit
    LOGDIR=$sKitbase/log
    LOG=$LOGDIR/$fname.log
    BOOT_DEV=/dev/mmcblk0p1 
    BOOT_MNT=/mnt/mmcblk0p1
    CONFIG=$BOOT_MNT/config.txt
}


set_log() {

    echo -e "\tsetup log"
    echo >$LOG
}


check_pcp() {

    if ! uname -a | grep -q -i pcp; then 
    
       out "No piCorePlayer system"
       
    fi
}


mount_boot() {

    echo -e "\tmounting boot partition"
    if [[ ! -d $BOOT_MNT ]]; then 

        sudo mkdir -p $BOOT_MNT

    fi
    if grep -q "$BOOT_DEV" /proc/mounts; then
    
        sudo umount -f "$BOOT_DEV"

    fi
    sudo mount $BOOT_DEV $BOOT_MNT || out "mounting boot"
    sleep 1
}
 

leds_off() {

    echo -e "\tdisabling LEDs"
    sudo sed -i 's/#---End-Custom.*/\###BOF sKit\
dtoverlay=act-led\
##disable ACT LED\
dtparam=act_led_trigger=none\
dtparam=act_led_activelow=off\
##disable the PWR LED\
dtparam=pwr_led_trigger=none\
dtparam=pwr_led_activelow=off\
##disable ethernet port LEDs\
dtparam=eth_led0=4\
dtparam=eth_led1=4\
###EOF sKit\
#---End-Custom----------------------------------------/g' $CONFIG
}


leds_on() {

    echo -e "\tenabling LEDs"
    sudo sed -i "/BOF sKit/,/EOF sKit/d" $CONFIG
}


toggle_leds() {

    echo -e "\tverifying LED stat"
    if grep -q "LED" $CONFIG; then
   
        echo -e "\t   currently disabled"
        leds_on

    else

       echo -e "\t   currently enabled"
       leds_off
    fi
}

###main#######################################
colors
license

header

check_pcp
env_set
set_log
mount_boot
toggle_leds
sync
REBOOT=true

DONE
reboot_system
exit 0
##############################################
