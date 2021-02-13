#!/bin/sh
#
# soundcheck's tuning kit - pCP  - sKit-manager.sh
# 
# for RPi3 and RPi4 and related CM modules
#
# Latest Update: Feb-14-2021
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
VERSION=1.0

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
    echo -e "\t      sKit - manager ($VERSION)"
    echo -e "\t         (c) soundcheck"
    echo
    echo -e "\t       welcome $(id -un)@$(hostname)"
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

            [Yy]* ) break;;
            [Nn]* ) DONE;exit;;
                * ) echo -e "\tPlease answer yes or no.";;

         esac

    done
    clear
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
    REPO_sKit="https://raw.githubusercontent.com/klslz/tuningkitpcp/main"
    TIMEOUT=120

    sKit="sKit-manager.sh sKit-custom-squeezelite.sh sKit-led-manager.sh sKit-tweaks sKit-src-manager.sh"

    EXTENSIONS="procps-ng" 
}


set_sKitbase() {

    echo -e "\tsetup sKit base"
    if [[ ! -d "$sKitbase" ]]; then
    
         sudo mkdir -p "$BIN_BASE"
         sudo mkdir -p "$LOG_BASE"
         sudo chown -R $OWNER_BASE "$sKitbase"
         sudo chmod -R $PERM_BASE  "$sKitbase"

    fi
}


set_ashrc() {

    echo -e "\tadding changes to environment"
    if ! grep -q "sKit" /home/tc/.ashrc; then
        cat >>/home/tc/.ashrc <<'EOF'

###BOF sKit
alias  lr="ls -ltr"
alias psp="ps -Leo rtprio,pri,psr,pid,tid,comm,cmd"

if [ -n "$SSH_CONNECTION" ]; then
   sudo pkill "sKit-tweaks" >/dev/null 2>&1
   sudo pkill "sleep" >/dev/null 2>&1
fi
###EOF sKit
EOF

    fi
}


set_profile() {

    echo -e "\tsetup sKit profile"
    sudo tee /etc/profile.d/sKit-profile.sh >/dev/null <<'EOF'
#!/bin/sh
#sKit enviroment
export PATH=$PATH:/mnt/mmcblk0p2/tce/sKit/bin
EOF
    sudo chmod 755 /etc/profile.d/sKit-profile.sh
    sudo echo "etc/profile.d/sKit-profile.sh" >> $ftlst
}


remove_profile() {

    echo -e "\tremoving sKit profile"
    sudo rm /etc/profile.d/sKit-profile.sh
    sudo sed -i "/sKit-profile/d " $ftlst
}


remove_sKit() {

    echo -e "\tremoving sKit"
    rm -rf "$sKitbase"
    sed -i "/###BOF sKit/,/###EOF sKit/d" /home/tc/.ashrc
    REBOOT=true
}


check_install() {

    if [[ -d "$sKitbase" ]]; then

        return 0

    else 

        return 1

    fi
}


enable_sKit_tweaks() {

    echo -e "\tenabling sKit-tweaks"
    sed -i 's|^USER_COMMAND_1=.*|USER_COMMAND_1="%23sleep 20;sKit-tweaks"|g' $pcpcfg
    sudo ln -s /mnt/mmcblk0p2/tce/sKit/bin/sKit-tweaks /usr/local/bin
    sudo echo "usr/local/bin/sKit-tweaks" >> $ftlst
}


disable_sKit_tweaks() {

    echo -e "\tdisabling sKit-tweaks"
    sed -i 's/^USER_COMMAND_1=.*/USER_COMMAND_1=""/g' $pcpcfg
    sudo rm "/usr/local/bin/sKit-tweaks"
    sudo sed -i "/sKit-tweaks/d " $ftlst
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


download_extensions() {

    echo -e "\tdownloading extensions"
    start=$(date +%s)
    for ext in $EXTENSIONS; do

        timeout $TIMEOUT pcp-load -r $REPO_PCP -wi "$ext" >>$LOG 2>&1
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



install_sKit() {

    echo -e "\tsKit $1"

    for i in $sKit; do

        if [[ -f "$BIN_BASE/$i" ]]; then 

            sudo rm "$BIN_BASE/$i"

        fi
        sudo wget "$REPO_sKit/$i" -P $BIN_BASE >>$LOG 2>&1

    done

    sudo chmod "$PERM_BASE"  $BIN_BASE/* 
    sudo chown "$OWNER_BASE" $BIN_BASE/* 
}


menu() {

    echo
    echo -e "\tsKit manager"
    echo
    echo -e "\t  1  = install"
    echo -e "\t  2  = update"
    echo
    echo -e "\t  3  = remove"
    echo -e "\t  *  = cancel"
    echo
    read -t 20 -r -p "	  ? : " var
    echo
    line

    clear
    header

    case $var in
 
     1)
        if ! check_install; then
        
            set_sKitbase
            set_log
            install_sKit installation
            download_extensions
            enable_sKit_tweaks
            set_ashrc
            set_profile
            
            REBOOT=true

        else
        
              echo -e "\tsKit already installed"

        fi
        ;;
     2)
        if check_install; then

            set_log
            install_sKit update
            REBOOT=true

        else

            echo -e "\tsKit not yet installed"

        fi
        ;;
     3)
        if check_install; then

            disable_sKit_tweaks
            remove_sKit
            remove_profile

        else

            echo -e "\tsKit not yet installed"

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
