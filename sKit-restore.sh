#!/bin/sh
#
# soundcheck's tuning kit - pCP - sKit-restore-image.sh
# restores backups while is pCP booted
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
VERSION=1.1-beta1
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
    echo
    line
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
    echo -e "\t     sKit - image restore ($VERSION)"
    echo -e "\t       (c) soundcheck"
    echo
    echo -e "\t      welcome $(id -un)@$(hostname)"
    line
}


halt_system() {

    echo -e "\thalting system now"
    line
    sudo halt
    exit 0
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
    ROOT_DEV=/mnt/mmcblk0p2
    BOOT_MNT=/mnt/mmcblk0p1
    ROOT_MNT=/mnt/mmcblk0p2
    PCP_DEV=/dev/mmcblk0
    BASE=/tmp
    HN=$(hostname)
    procs='httpd udhcpc pcpmdnsd squeezelite'

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


save_config() {

    sudo filetool.sh -b >/dev/null
    sync
}


umount_partitions() {

    echo -e "\tun-mounting partitions"
    if grep -q "mmcblk0p1" /proc/mounts; then 

        sudo umount -l /mnt/mmcblk0p1 2>$LOG

    fi
    if grep -q "mmcblk0p2" /proc/mounts; then 

        sudo umount -l /mnt/mmcblk0p2 2>$LOG

    fi
    sleep 1
}
 

find_image() {

    echo -e "\tsearching image"
    IMAGE="$(find $BASE -name "*pCP*img.gz" -print | grep $HN | sort | tail -1 )"
    if [[ -z "$IMAGE" ]]; then 

        out "no backup image found"

    fi
    echo -e "\t  >> $IMAGE"
}


stop_procs() {


    echo -e "\tstopping processes"
    for i in $procs; do

        sudo pkill -f $i >/dev/null 2>&1
        sleep 1

    done

    echo -e "\tclearing caches"
    sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
}


restore_image() {

    echo
    echo -e "\trestore image"
    echo
    echo -e "\t${RED}WARNING: all data will now be overwritten!!"
    echo
    while true; do

        read -t 120 -r -p "        confirm to restore? (y/n): " yn
        case $yn in

            [Yy]* ) restore=true;  break;;
            [Nn]* ) restore=false; break;;
                * ) echo -e "\t  please answer (y)es or (n)o!!!";;

         esac

    done
    echo -e "\t ${NC}"

    if [[ "$restore" == "true" ]]; then

        set_log
        save_config
        stop_procs
        umount_partitions
        sleep 2
        echo -e "\texecuting restore"
        sudo gunzip -c $IMAGE | dd of=$PCP_DEV bs=1M >/dev/null 2>&1 || out "problems restoring image"
        sync
        echo
        echo -e "\t${GREEN}image successfully restored${NC}"
        echo
        halt_system

    else
    
        echo -e "\timage restore cancelled"

    fi
}


###main#######################################
colors
license

header

check_pcp
env_set
find_image
restore_image

line
exit 0
##############################################
