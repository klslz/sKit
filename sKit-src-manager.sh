#!/bin/sh
#
# soundcheck's tuning kit - pCP - sKit-src-manager.sh
# provides sample rate converter presets
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
VERSION=1.1
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
	echo -e "\t     sKit - SRC manager ($VERSION)"
	echo -e "\t       (c) soundcheck"
	echo
	echo -e "\t      welcome $(id -un)@$(hostname)"
	line
}


cleanup() {

	if [[ -d "$BASE" ]]; then 

		rm -rf "$BASE"

	fi
	sync
}


DONE() {

	cleanup
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
    pcpcfg=/usr/local/etc/pcp/pcp.cfg

    #filter presets
    F1="soundcheck's ultimate"
    f1="v:1A:1:32:95.4:104.6:46"
    F2="soundcheck's linear straight"
    f2="v:1A:1:28:95.4:100:50"
    F3="soundcheck's min-phase special"
    f3="v:1A:1:28:90.7:109.3:0"
    F4="sox default"
    f4="::1:20:91.4:100:50"
    F5="SRC off"
    f5=""
}


set_log() {

    echo -e "\tsetup log"
    echo >$LOG
}


set_src() {

   if [[ "$1" != "cancel" ]]; then

       sed -i "s/UPSAMPLE=.*/UPSAMPLE=\"$1\"/g" $pcpcfg
       sudo filetool.sh -b >/dev/null 2>&1
       REBOOT=true

   else
   
       REBOOT=false

   fi
}


menu() {

    echo
    echo -e "\tselect samplerate converter preset"
    echo
    echo -e "\t  1  = $F1"
    echo -e "\t  2  = $F2"
    echo -e "\t  3  = $F3"
    echo -e "\t  4  = $F4"
    echo
    echo -e "\t  5  = $F5 (default)"
    echo -e "\t  *  = cancel"
    echo
    read -t 20 -r -p "	  ? : " x
    x=${x:-5}

    case $x in
 
        1) preset="$f1";PRESET="$F1";;
        2) preset="$f2";PRESET="$F2";;
        3) preset="$f3";PRESET="$F3";;
        4) preset="$f4";PRESET="$F4";;
        5) preset="$f5";PRESET="$F5";;
        *) preset="cancel";PRESET="cancel";;

    esac
    clear
    header
    echo
    echo -e "\tenabling samplerate converter preset:"
    echo
    echo -e "${YELLOW}\t   $PRESET${NC}"
    echo
    set_src "$preset"
}


check_pcp() {

    if ! uname -a | grep -q -i pcp; then 
    
       out "No piCorePlayer system"
       
    fi
}


###main#######################################
colors
license

header

check_pcp
env_set
set_log
menu
sync

DONE
reboot_system
exit 0
##############################################
