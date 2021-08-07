#!/bin/sh
#
# soundcheck's tuning kit - pCP  - sKit-manager.sh
# 
# for RPi4 and related CM modules
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
VERSION=1.6
sKit_VERSION=1.5

fname="${0##*/}"
opts="$@"
license_accept_flag=/mnt/mmcblk0p2/tce/.sKit-license-accepted.flag

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
    echo -e "\t      sKit ($sKit_VERSION) - manager ($VERSION)"
    echo -e "\t            (c) soundcheck"
    echo
    echo -e "\t         welcome $(id -un)@$(hostname)"
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

###############################

license() {

	if [[ ! -f $license_accept_flag ]]; then
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


check_pcp() {

    if ! uname -a | grep -q -i pcp; then 
    
       out "No piCorePlayer system"
       
    fi
}


save_config() {

    sudo filetool.sh -b >/dev/null
    sync
}


env_set() {

    TCE=/mnt/mmcblk0p2/tce 
    TCEO=$TCE/optional
    ONB=$TCE/onboot.lst

    sKitbase=$TCE/sKit

    LOGDIR=$sKitbase/log
    LOG=$LOGDIR/$fname.log

    pcpcfg=/usr/local/etc/pcp/pcp.cfg
    ftlst=/opt/.filetool.lst


    BIN_BASE="$sKitbase/bin"
    LOG_BASE="$sKitbase/log"
    PERM_BASE="755"
    OWNER_BASE="tc.staff"
   
    REPO_PCP1="https://repo.picoreplayer.org/repo"
    REPO_PCP2="http://picoreplayer.sourceforge.net/tcz_repo"
    REPO_PCP="$REPO_PCP1"
    REPO_sKit="https://raw.githubusercontent.com/klslz/sKit/master"
    TIMEOUT=120

    sKit="sKit-manager.sh sKit-custom-squeezelite.sh sKit-led-manager.sh sKit-tweaks sKit-src-manager.sh sKit-restore.sh sKit-check.sh"

    EXTENSIONS="procps-ng rpi-vc"

    BOOT_DEV=/dev/mmcblk0p1 
    BOOT_MNT=/mnt/mmcblk0p1
    CONFIG=$BOOT_MNT/config.txt
    
    EXT_BA="sKit-extensions-backup.tar.gz"
}


check_sKit_install() {

    if [[ -d "$sKitbase" ]]; then

        return 0

    else 

        return 1

    fi
}


set_sKit_log() {

    #echo -e "\tsetup sKit log"
    echo >$LOG
}


check_space() {

    space=$(/bin/df -m /mnt/mmcblk0p2 | tail -1 | awk '{print $4}')
    total=$(/bin/df -m /mnt/mmcblk0p2 | tail -1 | awk '{print $2}')

    echo -e "\tverifying space requirements"
    if [[ "$space" -lt "100" ]] && [[ ! -f "$TCEO/compiletc.tcz" ]]; then

        out "Not enough space (${space} of ${total}MB) on device, add at least 100MB!"

    fi
}



set_sKit_base() {

    echo -e "\tsetting up sKit base"
    if [[ ! -d "$sKitbase" ]]; then
    
         sudo mkdir -p "$BIN_BASE"
         sudo mkdir -p "$LOG_BASE"
         sudo chown -R $OWNER_BASE "$sKitbase"
         sudo chmod -R $PERM_BASE  "$sKitbase"

    fi
}


set_sKit_ashrc() {

    echo -e "\tadding changes to shell environment"
    if ! grep -q "sKit" /home/tc/.ashrc; then
        cat >>/home/tc/.ashrc <<'EOF'

###BOF sKit
alias lr="ls -ltr"
alias cs="cd  /mnt/mmcblk0p2/tce/sKit"
alias psp="ps -Leo rtprio,pri,psr,pid,tid,comm,cmd"

if [ -n "$SSH_CONNECTION" ]; then
   sudo pkill "sKit-tweaks" >/dev/null 2>&1
   sudo pkill "sleep" >/dev/null 2>&1
fi
###EOF sKit
EOF

    fi
}


set_sKit_profile() {

    echo -e "\tadding sKit shell environment profile"
    sudo tee /etc/profile.d/sKit-profile.sh >/dev/null <<'EOF'
#!/bin/sh
#sKit enviroment
export PATH=$PATH:/mnt/mmcblk0p2/tce/sKit/bin
EOF
    sudo chmod 755 /etc/profile.d/sKit-profile.sh
    sudo echo "etc/profile.d/sKit-profile.sh" >> $ftlst
}




enable_sKit_tweaks_mod() {

    echo -e "\tenable sKit-tweaks mod"
    sed -i 's|^USER_COMMAND_1=.*|USER_COMMAND_1="sleep 20;sKit-tweaks"|g' $pcpcfg
    sudo ln -s /mnt/mmcblk0p2/tce/sKit/bin/sKit-tweaks /usr/local/bin
    sudo echo "usr/local/bin/sKit-tweaks" >> $ftlst
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
    
        1) REPO_PCP=$REPO_PCP1; echo -e "\t   master >> $REPO"; TIMEOUT=300;;
        2) REPO_PCP=$REPO_PCP2; echo -e "\t   mirror >> $REPO"; TIMEOUT=600;;
        *) REPO_PCP=$REPO_PCP1; echo -e "\t   master >> $REPO"; TIMEOUT=300;;
 
    esac
}


install_sKit_extensions() {

    echo -e "\tinstalling sKit related extensions"
    start=$(date +%s)
    for ext in $EXTENSIONS; do

        timeout $TIMEOUT pcp-load -r $REPO_PCP -wi "$ext" >>$LOG 2>&1
        if [[ $? -ne 0 ]] || grep -q -i "FAILED" $LOG; then

            FAILED=true
            break

        fi

    done

                        
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
}


backup_extensions() {

    if [[ ! -f $sKitbase/$EXT_BA ]]; then

        echo -e "\tbacking up pre-installation extensions"
        cd $TCE
        tar czf $EXT_BA onboot.lst ./optional >>$LOG 2>&1
        if [ $? -eq 0 ]; then
           mv $EXT_BA $sKitbase
        else
           echo -e "  >> problem finishing backup - have a look @ $LOG"
        fi

    fi
}


sKit_package() {

    echo -e "\tsKit package $1"

    for i in $sKit; do

        if [[ -f "$BIN_BASE/$i" ]]; then 

            sudo rm "$BIN_BASE/$i"

        fi
        sudo wget "$REPO_sKit/$i" -P $BIN_BASE >>$LOG 2>&1

    done

    sudo chmod "$PERM_BASE"  $BIN_BASE/* 
    sudo chown "$OWNER_BASE" $BIN_BASE/* 
}


enable_governor_mod() {

    echo -e "\tconfiguring CPU governor"
    echo -e "\t  >> performance"
    sed -i 's/CPUGOVERNOR.*/CPUGOVERNOR="performance"/g' $pcpcfg
}


enable_hdmi_mod() {

    echo -e "\tdisabling HDMI power"
    sed -i 's/HDMIPOWER.*/HDMIPOWER="off"/g' $pcpcfg
}


enable_webcontrols_mod() {

    echo -e "\tdisabling LMS and SL web-controls"
    sed -i 's/LMSCONTROLS.*/LMSCONTROLS="no"/g' $pcpcfg
    sed -i 's/PLAYERTABS.*/PLAYERTABS="no"/g' $pcpcfg
}


####################################################################
### removal

mount_boot() {

    echo -e "\tmounting boot partition"
    echo
    if [[ ! -d $BOOT_MNT ]]; then 

        sudo mkdir -p $BOOT_MNT

    fi
    if grep -q "$BOOT_DEV" /proc/mounts; then
    
        sudo umount -f "$BOOT_DEV"

    fi
    sudo mount $BOOT_DEV $BOOT_MNT || out "mounting boot"
    sleep 1
}
 

remove_profile() {

    echo -e "\tremoving sKit shell profile"
    sudo rm /etc/profile.d/sKit-profile.sh
    sudo sed -i "/sKit-profile/d " $ftlst
}


remove_sKit_base() {

    echo -e "\tremoving sKit base"
    rm -rf "$sKitbase"
    sed -i "/###BOF sKit/,/###EOF sKit/d" /home/tc/.ashrc
    REBOOT=true
}


remove_sKit_tweaks_mod() {

    echo -e "\tremoving sKit-tweaks mod"
    sed -i 's/^USER_COMMAND_1=.*/USER_COMMAND_1=""/g' $pcpcfg
    sudo rm "/usr/local/bin/sKit-tweaks"
    sudo sed -i "/sKit-tweaks/d " $ftlst
}


remove_led_mod() {

    echo -e "\tremoving LEDs mod"
    if grep -q "LED" $CONFIG; then

       sudo sed -i "/BOF sKit/,/EOF sKit/d" $CONFIG
    
    fi
}


remove_custom_squeezelite() {

    echo -e "\tremoving custom-squeezelite binary"
    if [[ -f "$TCE/squeezelite-custom" ]]; then
   
        sudo rm $TCE/squeezelite*
        sed -i 's/SQBINARY="custom"/SQBINARY="default"/' $pcpcfg

    fi
}


remove_custom_squeezelite_settings() {

    echo -e "\tremoving custom-squeezelite settings"
    sed -i 's/^OTHER=.*/OTHER=""/g' $pcpcfg
}


restore_extensions() {

    echo -e "\trestoring pre-sKit extensions"

    if [[ -f $sKitbase/$EXT_BA ]]; then

        cd $TCE
        sudo rm -rf onboot.lst ./optional
        mv $sKitbase/$EXT_BA .
        tar xzf $EXT_BA
        chmod 775 ./optional
        chmod 664 onboot.lst ./optional/*
        rm $TCE/$EXT_BA

    else

        echo -e "\t  >> no pre-sKit-extensions backup found!"

    fi
}


remove_isolcpus_mod() {

    echo -e "\tremoving cpu isolation mod"
    sudo sed  -i 's/isolcpus[=][^ ]*//g' $BOOT_MNT/cmdline.txt
    sed -i "s/^CPUISOL=.*/CPUISOL=\"\"/g" $pcpcfg
}


remove_affinity_mod() {

    echo -e "\tremoving affinity mod"
    sed -i -e 's/^SQLAFFINITY=.*/SQLAFFINITY=""/g' \
           -e 's/^SQLOUTAFFINITY=.*/SQLOUTAFFINITY=""/g' $pcpcfg
}


remove_governor_mod() {

    echo -e "\tremoving CPU governor mod"
    sed -i 's/CPUGOVERNOR.*/CPUGOVERNOR="ondemand"/g' $pcpcfg
}


remove_hdmi_mod() {

    echo -e "\tremoving HDMI power mod"
    sed -i 's/HDMIPOWER.*/HDMIPOWER="on"/g' $pcpcfg
}


remove_webcontrols_mod() {

    echo -e "\tremoving LMS and SL web-controls mod"
    sed -i 's/LMSCONTROLS.*/LMSCONTROLS="yes"/g' $pcpcfg
    sed -i 's/PLAYERTABS.*/PLAYERTABS="yes"/g' $pcpcfg
}


remove_license_accept_flag() {
	
	rm $license_accept_flag
}


##########################################################

menu() {

    echo
    echo -e "\t  1  = install sKit"
    echo -e "\t  2  = update  sKit package"
    echo
    echo -e "\t  3  = remove  sKit"
    echo -e "\t  *  = cancel"
    echo
    read -t 20 -r -p "	  ? : " var
    echo
    line

    clear
    header

    case $var in
 
     1)
        if ! check_sKit_install; then
        
            check_space
            mount_boot
            set_sKit_base
            set_sKit_log
            sKit_package installation
            backup_extensions
            install_sKit_extensions
            set_sKit_ashrc
            set_sKit_profile
            enable_sKit_tweaks_mod
            enable_governor_mod
            enable_hdmi_mod
            enable_webcontrols_mod
            REBOOT=true

        else
        
              echo -e "\tsKit is already installed"

        fi
        ;;
     2)
        if check_sKit_install; then

            set_sKit_log
            sKit_package update
            REBOOT=true

        else

            echo -e "\tsKit not yet installed"
            REBOOT=false

        fi
        ;;
     3)
        if check_sKit_install; then

            mount_boot
            remove_sKit_tweaks_mod
            remove_led_mod
            remove_custom_squeezelite
            remove_custom_squeezelite_settings
            remove_isolcpus_mod
            remove_affinity_mod
            remove_governor_mod
            remove_hdmi_mod
            remove_webcontrols_mod
            remove_profile
            restore_extensions
            remove_sKit_base
			remove_license_accept_flag
            REBOOT=true

        else

            echo -e "\tsKit not yet installed"
            REBOOT=false

        fi
        ;;
     *)
        REBOOT=false
        ;;

   esac
   
}

###main#######################################
colors
license

header

check_pcp
env_set
menu

save_config
DONE
reboot_system
exit 0
##############################################
