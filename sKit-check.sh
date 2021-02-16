#!/bin/sh
#
# soundcheck's tuning kit - pCP - sKit-checker.sh
# checks the tuning status 
# for RPi3 and RPi4 and related CM modules
#
# Latest Update: Feb-16-2021
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
VERSION=1.1
sKit_VERSION=1.1

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
    echo -e "\t      sKit - check ($VERSION)"
    echo -e "\t       (c) soundcheck"
    echo
    echo -e "\t      welcome $(id -un)@$(hostname)"
    line
}


DONE() {

    line
}


###################################
check_pcp() {

    if ! uname -a | grep -q -i pcp; then 
    
       out "No piCorePlayer system"
       
    fi
}


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
    CMDLINE=$BOOT_MNT/cmdline.txt
    pcpcfg=/usr/local/etc/pcp/pcp.cfg
    REPO_sKit="https://raw.githubusercontent.com/klslz/tuningkitpcp/master"
}


set_log() {

    echo >$LOG
}

GREEN() {
    echo -e "\t${GREEN}$@${NC}"
}

RED() {
    echo -e "\t${RED}$@${NC}"
}

YELLOW() {
    echo -e "\t${YELLOW}$@${NC}"
}


mount_boot() {

    if [[ ! -d $BOOT_MNT ]]; then 

        sudo mkdir -p $BOOT_MNT

    fi
    if grep -q "$BOOT_DEV" /proc/mounts; then
    
        sudo umount -f "$BOOT_DEV"

    fi
    sudo mount $BOOT_DEV $BOOT_MNT || out "mounting boot"
    sleep 1
}


check_leds() {

    echo -en "\tLEDs\t\t\t"
    grep -q -i "act_led_activelow=off" $CONFIG && GREEN "disabled" || RED "enabled" 

}


check_isolcpus() {

    echo -en "\tisolcpus\t\t"
    grep -q -i 'isolcpus=2,3' $CMDLINE && GREEN "enabled" || RED "disabled" 
}


check_internalaudio() {

    echo -en "\tinternal audio\t\t"
    grep -q -i "#dtparam=audio" $CONFIG && GREEN "disabled" || RED "enabled" 
}


check_hdmi() {

    echo -en "\thdmi\t\t\t"
    sudo tvservice -s | grep -q -i "off" && GREEN "disabled" || RED "enabled"

}


check_bluetooth() {

    echo -en "\tbluetooth\t\t"
    grep -q -i "dtoverlay=disable-bt" $CONFIG && GREEN "disabled" || RED "enabled" 

}


check_skitweaks() {

    echo -en "\tsKit-tweaks\t\t"
    grep -i "sKit-tweaks" $pcpcfg | grep -q '="%' $pcpcfg && RED "disabled" || GREEN "enabled" 
}


check_temperature() {

   temp=$(sudo sudo vcgencmd measure_temp | cut -f 2 -d "=" | cut -f 1 -d "'")
   echo -en "\tCPU temperature\t\t"
   if [[ "$(echo $temp'>'50.0 | bc -l)" == "0" ]]; then
        GREEN "$temp"
   elif [[ "$(echo $temp'>'55.0 | bc -l)" == "0" ]]; then
        YELLOW "$temp"
   else
        RED "$temp"
   fi
}


check_cpuclock() {

    echo -en "\tCPU clock\t\t"
    cpu_clock=$(( $(sudo vcgencmd measure_clock arm | cut -d '=' -f 2) / 1000000 ))
    if [[ "$cpu_clock" == "1500" ]]; then
        GREEN "$cpu_clock"
    else
        YELLOW "$cpu_clock"
    fi
}


check_forcecpu() {

    echo -en "\tforced CPU clock\t"
    grep -q -i "force_turbo=1" $CONFIG && GREEN "enabled" || RED "disabled" 
}


check_governor() {

    echo -en "\tCPU governor\t\t"
    gov="$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"
    if [[ "$gov" == "performance" ]]; then
        GREEN "$gov"
    else
        RED "$gov"
    fi
}

check_custom_squeezelite() {

    echo -en "\tcustom squeezelite\t"
    /mnt/mmcblk0p2/tce/squeezelite-custom -? | grep -q "sKit" && GREEN "enabled" || RED "disabled" 
}


check_affinity_squeezelite() {

    echo -en "\tSL-custom affinity\t"
    grep "SQLAFFINITY" $pcpcfg | grep -q "2" && GREEN "enabled" || RED "disabled"
    echo -en "\tSL-custom-out affinity\t"
    grep "OTHER" $pcpcfg | grep -q "\-A" && GREEN "enabled" || RED "disabled"
}


check_rambuffer_squeezelite() {

    echo -en "\tSL-custom ramplayback\t"
    RAMBUFFER=$(grep BUFFER_SIZE $pcpcfg | cut -f 2 -d ":" |sed 's/"//')

    [[ $RAMBUFFER -lt 50000 ]]     && RED "too low @$RAMBUFFER"
    [[ $RAMBUFFER -gt 50000 && $RAMBUFFER -lt 200000 ]] && YELLOW "not bad @$RAMBUFFER"
    [[ $RAMBUFFER -gt 200000 ]] && GREEN "great"
}


check_alsa_params() {

    echo -en "\tSL-custom alsa params\t"
    alsa_params="$(grep "ALSA_PARAMS"  $pcpcfg | cut -f 2 -d '"')"
    if [[ "$alsa_params" == "::::" ]]; then
        RED "not set"
    elif [[ "$alsa_params" == "120:4::1:" || "$alsa_params" == "65536:4::1:" ]]; then 
        GREEN "OK"
    else 
        YELLOW "please check values"
    fi
}


check_priority() {

    echo -en "\tSL-custom-out priority\t"
    PRIORITY=$(grep "PRIORITY" $pcpcfg | cut -f 2 -d '"' |sed 's/"//')
    [[ $PRIORITY -gt 45 && $PRIORITY -lt 50 ]] && GREEN "OK" || RED "please check"  
}


check_netif() {

    echo -en "\tnetwork interface\t"
    netif=$(route | grep default | awk '{print $8}')
    if [[ "$netif" == "wlan0" ]]; then
        YELLOW "$netif"
    else
        GREEN "$netif"
    fi
}


check_sKitrev() {

    echo
    echo -en "\tsKit status\t\t"
    skm="sKit-manager.sh"
    tskm="/tmp/$skm"
    lskm="$sKitbase/bin/$skm"
    wget -q "$REPO_sKit/$skm" -O "$tskm" 
    sKit_reporev=$(grep "sKit_VERSION=" $tskm | cut -f 2 -d "=")
    sKit_actrev=$(grep "sKit_VERSION=" $lskm | cut -f 2 -d "=")
    [[ "$sKit_actrev" == "$sKit_reporev" ]] && GREEN "up-2-date" || RED "update available"
}


check_bootloader() {

   act_bl=$(sudo vcgencmd bootloader_version | head -1)
}

###main#######################################
colors
license

header

check_pcp
env_set
set_log
mount_boot

check_temperature
check_governor
check_cpuclock
check_forcecpu
check_isolcpus
check_hdmi
check_bluetooth
check_internalaudio
check_netif

check_leds
check_skitweaks
check_custom_squeezelite
check_affinity_squeezelite
check_rambuffer_squeezelite
check_alsa_params
check_priority

check_bootloader
check_sKitrev

DONE
exit 0
##############################################
