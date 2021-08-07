#!/bin/sh
#
# soundcheck's tuning kit - pCP - sKit-custom-squeezlite.sh
# custom squeezelite binary build tool for piCorePlayer
# supporting RPi3 and RPi4 and related CM modules
#
# Latest Update: Aug-07-2021
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
VERSION=1.3
sKit_VERSION=1.5

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
    echo -e "\t   sKit - custom squeezelite builder ($VERSION)"
    echo -e "\t            (c) soundcheck"
    echo
    echo -e "\t           welcome $(id -un)@$(hostname)"
    line
}


DONE() {

    line
    sync
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
      sudo reboot
      exit 1

   fi
}


############################################
check_pcp() {

    if ! uname -a | grep -q -i pcp; then 
    
        out "No piCorePlayer system"
       
    fi
}


license() {

	if [[ ! -f $license_accept_flag ]]; then

		line
		echo "
    soundcheck's tuning kit ($fname)
    
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


		while true; do

			read -t 120 -r -p "    Confirm terms? (y/n)  : " yn
			case $yn in

				[Yy]* ) touch $license_accept_flag; break;;
				    * ) DONE;exit;;

			esac

		done
		clear
	fi
}


env_set() {

    TCE=/mnt/mmcblk0p2/tce 
    TCEO=$TCE/optional
    ONB=$TCE/onboot.lst
    sKitbase=$TCE/sKit
    LOGDIR=$sKitbase/log
    LOG=$LOGDIR/$fname.log
    pcpcfg=/usr/local/etc/pcp/pcp.cfg
    BOOT_MNT=/mnt/mmcblk0p1
    BOOT_DEV=/dev/mmcblk0p1
    REPO_PCP1="https://repo.picoreplayer.org/repo"
    REPO_PCP2="http://picoreplayer.sourceforge.net/tcz_repo"
    REPO_SL="https://github.com/klslz/squeezelite.git"
    EXT_BA="sKit-extensions-backup.tar.gz"
    EXTENSIONS="\
compiletc
git
libasound-dev
pcp-libogg-dev
pcp-libflac-dev
pcp-libvorbis-dev
pcp-libmad-dev
pcp-libmpg123-dev
pcp-libalac-dev
pcp-libfaad2-dev
pcp-libsoxr-dev" 
    BASE=/tmp/squeezelite
    ISOLCPUS="3"
}


set_log() {

    echo -e "\tsetting up log"
    echo >$LOG
}


save_config() {

    sudo filetool.sh -b >/dev/null
}


select_ext_repo() {

    echo -e "\tselect repository"
    echo
    echo -e "\t   1 = pCP master  (default)"
    echo -e "\t   2 = pCP mirror"
    echo
    read -t 15 -r -p "	   ?  " x
    x=${x:-1}
    echo
    echo -e "\trepository"

    case "$x" in
    
        1) REPO_PCP=$REPO_PCP1; echo -e "\t   master >> $REPO_PCP"; TIMEOUT=300;;
        2) REPO_PCP=$REPO_PCP2; echo -e "\t   mirror >> $REPO_PCP"; TIMEOUT=600;;
        *) REPO_PCP=$REPO_PCP1; echo -e "\t   master >> $REPO_PCP"; TIMEOUT=300;;
 
    esac
}


check_space() {

    space=$(/bin/df -m /mnt/mmcblk0p2 | tail -1 | awk '{print $4}')
    total=$(/bin/df -m /mnt/mmcblk0p2 | tail -1 | awk '{print $2}')

    echo -e "\tverifying space requirements"
    if [[ "$space" -lt "100" ]] && [[ ! -f "$TCEO/compiletc.tcz" ]]; then

        out "Not enough space (${space} of ${total}MB) on device, add at least 100MB!"

    fi
}


backup_extensions() {

    if [[ ! -f $sKitbase/$EXT_BA ]]; then

        echo -e "\tbacking up pre-installation extensions"
        cd $TCE
        tar czf $EXT_BA onboot.lst ./optional
        mv $EXT_BA $sKitbase

    fi
}



verify_extension() {

    if [[ ! -f "$TCEO/${1}.tcz" ]]; then

        echo -e "\t  >> download failed - $1 "
        return 1
      
    else
   
        return 0

    fi
}


menu() {

    echo
    echo -e "\tselect squeezelite variant"
    echo
    echo -e "\t  1  = standard   - minimal"
    echo -e "\t  2  = standard   - DSD & SRC"
    echo -e "\t  3  = soundcheck - minimal (default)"
    echo -e "\t  4  = soundcheck - DSD & SRC"
    echo -e "\t  5  = soundcheck - DSD & SRC (MP)"
    echo
    echo -e "\t  6  = remove custom installation"
    echo -e "\t  *  = cancel"
    echo
    read -t 20 -r -p "	  ? : " x
    x=${x:-3}
    echo
    line

    clear
    header

    case $x in
 
      1)
        VARIANT="standard - minimal"
        VID="sKit-stmi"
        INSTALL master minimal
        ;;
      2)
        VARIANT="standard - DSD & SRC"
        VID="sKit-stds"
        INSTALL master dsdsrc
        ;;
      3)
        VARIANT="soundcheck - minimal"
        VID="sKit-scmi"
        INSTALL squeezelite-sc minimal
        ;;
      4)
        VARIANT="soundcheck - DSD & SRC"
        VID="sKit-scds"
        INSTALL squeezelite-sc dsdsrc
        ;;
      5)
        VARIANT="soundcheck - DSD & SRC (MultiProcessor)"
        VID="sKit-scdsm"
        INSTALL squeezelite-sc dsdsrc-mp
        ;;
      6)
        REMOVE
        ;;
      *)
        echo -e "\tcanceled"
        REBOOT=false
       ;;

    esac
}


download_extensions() {

    echo -e "\tdownloading extensions (~3min master, ~5min mirror - for initial DL)"
    start=$(date +%s)
    for ext in $EXTENSIONS; do

        timeout $TIMEOUT pcp-load -r $REPO_PCP -w "$ext" >>$LOG 2>&1
        if [[ $? -ne 0 ]] || grep -q -i "FAILED" $LOG; then

            FAILED=true
            break

        fi

    done

    end=$(date +%s)
    total=$((end-start))
    duration=$(printf '%dm:%ds\n' $(($total%3600/60)) $(($total%60)))
 
                        
    if [[ "$FAILED" == "true" ]]; then

        echo
        echo -e "\t${RED}ERROR: serious issue while downloading extensions${NC}"
        echo -e "\t${RED}ERROR: prior status will be restored${NC}"
        echo -e "\t${RED}ERROR: please try once more later or use a different repo server${NC}"
        echo -e "\t${RED}ERROR: you could also have look @ ${NC}"
        echo -e "\t${RED}ERROR:   >> $LOG${NC}"
        grep -i "FAILED" $LOG | while IFS= read i; do 

                                  echo -e "\t${RED}ERROR:   >> $i${NC}\n" 

                                done
        echo
        restore_extensions
        REBOOT=true
        DONE
        reboot_system
        exit 1
    fi

   echo -e "\t   DL-duration: $duration"
}


load_extensions() {

    echo -e "\tloading extensions (temporary)"
    echo "$EXTENSIONS" | while IFS= read -r ext; do

                            pcp-load -s -l -i "$ext" >>$LOG 2>&1

                         done 
}


download_squeezelite() {

    echo -e "\tdownloading squeezelite sources"
    if [[ -d "$BASE" ]]; then
    
        rm -rf $BASE
    
    fi
    timeout 240 git clone --quiet "$REPO_SL" $BASE >>$LOG 2>&1 || out "downloading sources"
}


install_squeezelite() {

    cd $BASE

    git checkout squeezelite-sc >$LOG 2>&1 || out "git checkout sc branch"
    # we need to get the makefiles from the sc branch for master
    cp Makefile.sc* /tmp

    if [[ "$1" == "master" ]]; then
   
        git checkout master >$LOG 2>&1 || out "git checkout master branch"

    fi
    #define CUSTOM_VERSION
    sed -i "/^#define CUSTOM_VERSION/d" $BASE/squeezelite.h
    sed -i "/#define MICRO_VERSION/a #define CUSTOM_VERSION -$VID" $BASE/squeezelite.h

    echo -e "\tbuilding"
    make -C $BASE -f /tmp/Makefile.sc-rpi-ux-$variant >$LOG 2>&1 || out "compiling binary"
    strip -x $BASE/squeezelite
    echo -e "\tinstalling"
    sudo install --mode=755 -o root -g root $BASE/squeezelite $TCE/squeezelite-custom || out "installing binary"
}


verify_squeezelite() {

    echo -e "\tverifying binary"

    if $TCE/squeezelite-custom -? >/dev/null 2>&1; then

        VERSION=$($TCE/squeezelite-custom -? | grep "^Squeezelite" |\
                    awk '{print $2}' | sed -e 's/v//' -e 's/,//')
        echo
        echo -e "\t   ${GREEN}squeezelite $VERSION${NC}"
        echo

    else

        out "new binary not working"

    fi
}


activate_squeezelite() {

    echo -e "\tactivating binary"
    if [[ ! -f $TCE/squeezelite ]]; then

        ln -s $TCE/squeezelite-custom $TCE/squeezelite

    fi
    sed -i 's/SQBINARY="default"/SQBINARY="custom"/' $pcpcfg
}


mount_boot() {

    echo -e "\tmounting boot partition"
    if [[ ! -d $BOOT_MNT ]]; then 
    
       sudo mkdir -p $BOOT_MNT

    fi
    if grep -q "$BOOT_DEV" /proc/mounts; then
    
       sudo umount "$BOOT_DEV" 2>$LOG || out "umounting boot"
       
    fi
    sudo mount $BOOT_DEV $BOOT_MNT 2>$LOG || out "mounting boot"
    sleep 1
}


set_isolcpus() {

    echo -e "\tconfiguring cpu isolation"
    sed -i "s/^CPUISOL=.*/CPUISOL=\"$ISOLCPUS\"/g" $pcpcfg
    if grep -q "isolcpus" $BOOT_MNT/cmdline.txt; then
   
        sudo sed -i "s/isolcpus[=][^ ]* /isolcpus=$ISOLCPUS /g" $BOOT_MNT/cmdline.txt
   
    else
   
        sudo sed -i "s/$/ isolcpus=$ISOLCPUS /g" $BOOT_MNT/cmdline.txt
      
    fi
    
    sudo sed -i 's/  */ /g' $BOOT_MNT/cmdline.txt
}


set_affinity() {

    echo -e "\tconfiguring CPU affinities"
    sed -i -e 's/^SQLAFFINITY=.*/SQLAFFINITY="1,2"/g' \
           -e 's/^SQLOUTAFFINITY=.*/SQLOUTAFFINITY=""/g' $pcpcfg

    if ! cat $pcpcfg | grep "OTHER" | grep -q "\-A"; then 

        sed -i 's/^OTHER="/OTHER="-A /g' $pcpcfg

    fi
}


INSTALL() {

    echo -e "\tbuilding variant"
    echo
    echo -e "\t  ${YELLOW} $VARIANT${NC}"
    echo
    branch=$1
    variant=$2
    set_log
    check_space
    backup_extensions
    select_ext_repo
    download_extensions
    load_extensions
    download_squeezelite
    install_squeezelite $branch
    verify_squeezelite
    activate_squeezelite
    if echo "$VARIANT" | grep -q "soundcheck"; then
        mount_boot
        set_isolcpus
        set_affinity
    fi
    save_config
    REBOOT=true
}

##########################################################
###removal

remove_squeezelite() {

    echo -e "\tremoving custom squeezelite binary"
    if [[ -f "$TCE/squeezelite-custom" ]]; then
   
        sudo rm $TCE/squeezelite*
        sed -i 's/SQBINARY="custom"/SQBINARY="default"/' $pcpcfg

    else

        echo -e "\t  >> no custom binary on system"

    fi
}


remove_squeezelite_custom_settings() {

    echo -e "\tremoving squeezelite custom settings"
    sed -i 's/^OTHER=.*/OTHER=""/g' $pcpcfg
}


restore_extensions() {

    if [[ -f "$sKitbase/$EXT_BA" ]]; then

        echo -e "\trestoring pre-installation extensions"
        cd $TCE
        rm -rf onboot.lst ./optional
        mv $sKitbase/$EXT_BA .
        tar xzf $EXT_BA
        chmod 775 ./optional
        chmod 664 onboot.lst ./optional/*
        rm $TCE/$EXT_BA

    fi
}


disable_isolcpus() {

    echo -e "\tdisabling cpu isolation"
    sudo sed  -i 's/isolcpus[=][^ ]*//g' $BOOT_MNT/cmdline.txt
    sed -i "s/^CPUISOL=.*/CPUISOL=\"\"/g" $pcpcfg
}


disable_affinity() {

    echo -e "\tdisabling affinity settings"
    sed -i -e 's/^SQLAFFINITY=.*/SQLAFFINITY=""/g' \
           -e 's/^SQLOUTAFFINITY=.*/SQLOUTAFFINITY=""/g' $pcpcfg
}


REMOVE() {

    remove_squeezelite
    remove_squeezelite_custom_settings
    restore_extensions
    mount_boot
    disable_isolcpus
    disable_affinity
    save_config
    REBOOT=true
}


###main#######################################
colors
license

header

check_pcp
env_set
menu

DONE
reboot_system
exit 0
##############################################
