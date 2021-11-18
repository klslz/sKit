#!/bin/sh
#
# soundcheck's tuning kit - pCP - sKit-custom-squeezlite.sh
# custom squeezelite binary build tool for piCorePlayer
# supporting RPi3 and RPi4 and related CM modules
#
# Latest Update: Nov-18-2021
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
VERSION="1.4.2-beta"
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

    echo
    echo -e "\tprogram aborted:"
    echo -e "\t${RED}ERROR: $@${NC}"
    DONE
    exit 1
}


line() {

    printf "${RED}%*s${NC}\n" 80 "" | tr ' ' _
    echo
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
    LOG=$LOGDIR/$fname-$(date +%d%b%Y-%H%M).log
    DOWNLOAD_DIR="/tmp/ext"
    TARGET_DIR="$TCEO"
    pcpcfg=/usr/local/etc/pcp/pcp.cfg
    BOOT_MNT=/mnt/mmcblk0p1
    BOOT_DEV=/dev/mmcblk0p1
    ARCH="$(uname -m)"
    SITE1="https://repo.picoreplayer.org"
    REPO1="${SITE1}/repo/13.x/$ARCH/tcz"
    SITE2="http://picoreplayer.sourceforge.net"
    REPO2="${SITE2}/tcz_repo/13.x/$ARCH/tcz"
    REPO_SL="https://github.com/klslz/squeezelite.git"
    EXT_BA="sKit-extensions-backup.tar.gz"
    EXTENSIONS="
binutils.tcz
binutils.tcz.dep
binutils.tcz.dep.pcp
binutils.tcz.info
binutils.tcz.md5.txt
binutils.tcz.tree
bison.tcz
bison.tcz.dep.pcp
bison.tcz.info
bison.tcz.md5.txt
bzip2-lib.tcz
bzip2-lib.tcz.dep.pcp
bzip2-lib.tcz.info
bzip2-lib.tcz.md5.txt
curl.tcz
curl.tcz.dep
curl.tcz.dep.pcp
curl.tcz.info
curl.tcz.md5.txt
curl.tcz.tree
diffutils.tcz
diffutils.tcz.dep.pcp
diffutils.tcz.info
diffutils.tcz.md5.txt
e2fsprogs_base-dev.tcz
e2fsprogs_base-dev.tcz.dep.pcp
e2fsprogs_base-dev.tcz.info
e2fsprogs_base-dev.tcz.md5.txt
expat2.tcz
expat2.tcz.dep.pcp
expat2.tcz.info
expat2.tcz.md5.txt
file.tcz
file.tcz.dep.pcp
file.tcz.info
file.tcz.md5.txt
findutils.tcz
findutils.tcz.dep.pcp
findutils.tcz.info
findutils.tcz.md5.txt
flex.tcz
flex.tcz.dep.pcp
flex.tcz.info
flex.tcz.md5.txt
gamin.tcz
gamin.tcz.dep.pcp
gamin.tcz.info
gamin.tcz.md5.txt
gawk.tcz
gawk.tcz.dep
gawk.tcz.dep.pcp
gawk.tcz.info
gawk.tcz.md5.txt
gawk.tcz.tree
gcc_base-dev.tcz
gcc_base-dev.tcz.dep.pcp
gcc_base-dev.tcz.info
gcc_base-dev.tcz.md5.txt
gcc_libs-dev.tcz
gcc_libs-dev.tcz.dep
gcc_libs-dev.tcz.dep.pcp
gcc_libs-dev.tcz.info
gcc_libs-dev.tcz.md5.txt
gcc_libs-dev.tcz.tree
gcc_libs.tcz
gcc_libs.tcz.dep.pcp
gcc_libs.tcz.info
gcc_libs.tcz.md5.txt
gcc.tcz
gcc.tcz.dep.pcp
gcc.tcz.info
gcc.tcz.md5.txt
git.tcz
git.tcz.dep
git.tcz.dep.pcp
git.tcz.info
git.tcz.md5.txt
git.tcz.tree
glib2.tcz
glib2.tcz.dep
glib2.tcz.dep.pcp
glib2.tcz.info
glib2.tcz.md5.txt
glib2.tcz.tree
glibc_add_lib.tcz
glibc_add_lib.tcz.dep.pcp
glibc_add_lib.tcz.info
glibc_add_lib.tcz.md5.txt
glibc_apps.tcz
glibc_apps.tcz.dep.pcp
glibc_apps.tcz.info
glibc_apps.tcz.md5.txt
glibc_base-dev.tcz
glibc_base-dev.tcz.dep.pcp
glibc_base-dev.tcz.info
glibc_base-dev.tcz.md5.txt
glibc_gconv.tcz
glibc_gconv.tcz.dep.pcp
glibc_gconv.tcz.info
glibc_gconv.tcz.md5.txt
gmp.tcz
gmp.tcz.dep.pcp
gmp.tcz.info
gmp.tcz.md5.txt
grep.tcz
grep.tcz.dep
grep.tcz.dep.pcp
grep.tcz.info
grep.tcz.md5.txt
grep.tcz.tree
isl.tcz
isl.tcz.dep
isl.tcz.dep.pcp
isl.tcz.info
isl.tcz.md5.txt
isl.tcz.tree
libasound-dev.tcz
libasound-dev.tcz.dep
libasound-dev.tcz.dep.pcp
libasound-dev.tcz.info
libasound-dev.tcz.md5.txt
libasound-dev.tcz.tree
libelf.tcz
libelf.tcz.dep.pcp
libelf.tcz.info
libelf.tcz.md5.txt
libffi_base-dev.tcz
libffi_base-dev.tcz.dep.pcp
libffi_base-dev.tcz.info
libffi_base-dev.tcz.md5.txt
linux-5.10.y_api_headers.tcz
linux-5.10.y_api_headers.tcz.dep.pcp
linux-5.10.y_api_headers.tcz.info
linux-5.10.y_api_headers.tcz.md5.txt
m4.tcz
m4.tcz.dep.pcp
m4.tcz.info
m4.tcz.md5.txt
make.tcz
make.tcz.dep.pcp
make.tcz.info
make.tcz.md5.txt
mpc.tcz
mpc.tcz.dep
mpc.tcz.dep.pcp
mpc.tcz.info
mpc.tcz.md5.txt
mpc.tcz.tree
mpfr.tcz
mpfr.tcz.dep
mpfr.tcz.dep.pcp
mpfr.tcz.info
mpfr.tcz.md5.txt
mpfr.tcz.tree
patch.tcz
patch.tcz.dep.pcp
patch.tcz.info
patch.tcz.md5.txt
pcp-libalac-dev.tcz
pcp-libalac-dev.tcz.dep
pcp-libalac-dev.tcz.dep.pcp
pcp-libalac-dev.tcz.info
pcp-libalac-dev.tcz.md5.txt
pcp-libalac-dev.tcz.tree
pcp-libfaad2-dev.tcz
pcp-libfaad2-dev.tcz.dep
pcp-libfaad2-dev.tcz.dep.pcp
pcp-libfaad2-dev.tcz.info
pcp-libfaad2-dev.tcz.md5.txt
pcp-libfaad2-dev.tcz.tree
pcp-libflac-dev.tcz
pcp-libflac-dev.tcz.dep
pcp-libflac-dev.tcz.dep.pcp
pcp-libflac-dev.tcz.info
pcp-libflac-dev.tcz.md5.txt
pcp-libflac-dev.tcz.tree
pcp-libmad-dev.tcz
pcp-libmad-dev.tcz.dep
pcp-libmad-dev.tcz.dep.pcp
pcp-libmad-dev.tcz.info
pcp-libmad-dev.tcz.md5.txt
pcp-libmad-dev.tcz.tree
pcp-libmpg123-dev.tcz
pcp-libmpg123-dev.tcz.dep
pcp-libmpg123-dev.tcz.dep.pcp
pcp-libmpg123-dev.tcz.info
pcp-libmpg123-dev.tcz.md5.txt
pcp-libmpg123-dev.tcz.tree
pcp-libogg-dev.tcz
pcp-libogg-dev.tcz.dep
pcp-libogg-dev.tcz.dep.pcp
pcp-libogg-dev.tcz.info
pcp-libogg-dev.tcz.md5.txt
pcp-libogg-dev.tcz.tree
pcp-libsoxr-dev.tcz
pcp-libsoxr-dev.tcz.dep
pcp-libsoxr-dev.tcz.dep.pcp
pcp-libsoxr-dev.tcz.info
pcp-libsoxr-dev.tcz.md5.txt
pcp-libsoxr-dev.tcz.tree
pcp-libvorbis-dev.tcz
pcp-libvorbis-dev.tcz.dep
pcp-libvorbis-dev.tcz.dep.pcp
pcp-libvorbis-dev.tcz.info
pcp-libvorbis-dev.tcz.md5.txt
pcp-libvorbis-dev.tcz.tree
pcre.tcz
pcre.tcz.dep
pcre.tcz.dep.pcp
pcre.tcz.info
pcre.tcz.md5.txt
pcre.tcz.tree
pkg-config.tcz
pkg-config.tcz.dep
pkg-config.tcz.dep.pcp
pkg-config.tcz.info
pkg-config.tcz.md5.txt
pkg-config.tcz.tree
sed.tcz
sed.tcz.dep.pcp
sed.tcz.info
sed.tcz.md5.txt
util-linux_base-dev.tcz
util-linux_base-dev.tcz.dep.pcp
util-linux_base-dev.tcz.info
util-linux_base-dev.tcz.md5.txt
zlib_base-dev.tcz
zlib_base-dev.tcz.dep.pcp
zlib_base-dev.tcz.info
zlib_base-dev.tcz.md5.txt"
 
    EXTENSIONS_LOAD="gcc_libs
gcc
gcc_base-dev
gcc_libs-dev
glibc_base-dev
glibc_add_lib
glibc_apps
glibc_gconv
isl
mpc
linux-5.10.y_api_headers
binutils
make
sed
grep
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

	test -d "$DOWNLOAD_DIR" || mkdir -p "$DOWNLOAD_DIR"
	rm ${DOWNLOAD_DIR}/*tcz* 2>/dev/null
}


set_log() {

    PCP_REV="$(grep -R "piCorePlayer" /var/tmp/footer.html | awk '{print $2}')"
    ARCH="$(uname -m)"
    MEMORY="$(free -m | grep Mem)"
    echo -e "\tsetting up log"
    echo >$LOG
    echo "*** sKit-custom-squeezelite: $VERSION" >>$LOG
    echo "*** pCP version: $PCP_REV" >>$LOG
    echo "*** Arch: $ARCH" >>$LOG
    echo "*** $MEMORY" >>$LOG 
    echo "**************************************************************" >>$LOG
    echo >>$LOG
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

    case "$x" in
    
        1) REPO=$REPO1 ; TIMEOUT=400;;
        2) REPO=$REPO2 ; TIMEOUT=600;;
        *) REPO=$REPO1 ; TIMEOUT=400;;
 
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
        cp -f $EXT_BA $sKitbase

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


    echo -e "\textensions download"
    echo
    echo -e "\t  repo: $REPO"
    echo
    start=$(date +%s)

	test -f /tmp/skit-dl.failed && rm /tmp/skit-dl.failed
	touch   /tmp/skit-dl.failed

	for ex in $EXTENSIONS; do

		if [[ ! -f $TARGET_DIR/$ex ]]; then 
			if [[ ! -f $DOWNLOAD_DIR/$ex ]]; then

				printf "\t%-18s%-38s" "downloading:" "$ex"

				DOWNLOAD_INITIATED=true 

				wget -P "$DOWNLOAD_DIR" ${REPO}/$ex >>$LOG 2>&1

				if [ $? -eq 0 ]; then

					stat="DOWNLOADED"
					DOWNLOAD_SUCCESS=true

				else

					stat="FAILED"
					echo "$ex" >> /tmp/skit-dl.failed
				fi

				if [[ "$stat" == "DOWNLOADED" ]]; then
					printf "${GREEN}%-15s${NC}\n" "$stat"
				else
					printf "${RED}%-15s${NC}\n" "$stat"
				fi

			fi
		fi


	done

    end=$(date +%s)
    total=$((end-start))
    duration=$(printf '%dm:%ds\n' $(($total%3600/60)) $(($total%60)))

	if [[ "$DOWNLOAD_INITIATED" == "true" ]]; then

			echo
			echo -e "\tdownload-duration: $duration"

	else

			echo
			echo -e "\tall required extentions already installed"

	fi
}


verify_extensions() {

	echo -e "\tverifiying extensions download"

	for i in 1 2 3 4; do

        if [[ -s "/tmp/skit-dl.failed" ]]; then

            echo
            echo -e "${RED}\tERROR: extensions download (partially) failed >> ${YELLOW}${i}. RETRY ${NC}"
            echo
            sleep 5
            download_extensions

        fi

	done

	if [[ -s "/tmp/skit-dl.failed" ]]; then

		echo -e "\t${RED}ERROR:   serious extensions download issue encountered{NC}"
		echo -e "\t${RED}         so far nothing has been changed${NC}"
		echo -e "\t${RED}         try later or choose different repo after reboot${NC}"

		sleep 5
		REBOOT=true
		reboot_system

	fi

	echo
    echo -e "\textensions download successfully finished"

	line 

	echo -e "\textensions integrity check"
	echo

	if [[ "$(ls -1 "$DOWNLOAD_DIR"/*tcz 2>/dev/null | wc -l )" == "0" ]]; then
	
		out "tcz packages for integrity check missing"
	
	fi

	for j in "$DOWNLOAD_DIR"/*.tcz; do


		md5_act="$(md5sum $j | awk '{print $1}' )"
		md5_orig="$(cat ${j}.md5.txt | awk '{print $1}')"

		printf "\t%-18s%-38s" "integrity check:" "$(basename $j)" 

		if [[ "$md5_orig" == "$md5_act" ]]; then

			stat=PASSED

		else

			stat=FAILED
			FAILED=1

		fi

		if [[ "$stat" == "PASSED" ]]; then

			printf "${GREEN}%-15s${NC}\n" "$stat"

		else

			printf "${RED}%-15s${NC}\n" "$stat"

		fi

		echo "*** integrity check for: $j *** $stat *** $md5_orig * $md5_act" >>$LOG

	done

	if [[ "$FAILED" == "1" ]]; then

		echo
		echo -e "\t${RED}ERROR:   extension integrity issue detected${NC}"
		echo -e "\t${RED}         so far nothing has been changed${NC}"
		echo -e "\t${RED}         try later or choose different repo after reboot${NC}"
		sleep 5
		REBOOT=true
		reboot_system

	else

		echo
		echo -e "\tsaving extensions"
		mv -f $DOWNLOAD_DIR/* $TARGET_DIR

	fi
}


load_extensions() {

    echo -e "\tloading extensions"
    echo "$EXTENSIONS_LOAD" | while IFS= read -r ext; do

                            pcp-load -s -l -i "$ext" >>$LOG 2>&1

                         done 
}


download_squeezelite() {

    echo -e "\tdownloading squeezelite sources"
    if [[ -d "$BASE" ]]; then
    
        rm -rf $BASE
    
    fi
    timeout 240 git clone --quiet "$REPO_SL" $BASE >>$LOG 2>&1 || out "downloading squeezelite sources - rerun the program"
}


install_squeezelite() {

    cd $BASE

    git checkout squeezelite-sc >>$LOG 2>&1 || out "git checkout sc branch"
    # we need to get the makefiles from the sc branch for master
    cp Makefile.sc* /tmp

    if [[ "$1" == "master" ]]; then
   
        git checkout master >>$LOG 2>&1 || out "git checkout master branch"

    fi
    
    #get git commit id as attachment to version string
    GIT_COMMIT_ID=$(git -C $BASE rev-parse --short HEAD)
    
    #define CUSTOM_VERSION
    sed -i "/^#define CUSTOM_VERSION/d" $BASE/squeezelite.h
    sed -i "/#define MICRO_VERSION/a #define CUSTOM_VERSION -$VID-$GIT_COMMIT_ID" $BASE/squeezelite.h

    echo -e "\tbuilding"
    make -C $BASE -f /tmp/Makefile.sc-rpi-ux-$variant >>$LOG 2>&1 || out "compiling binary"
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
    
       sudo umount "$BOOT_DEV" 2>>$LOG || out "umounting boot"
       
    fi
    sudo mount $BOOT_DEV $BOOT_MNT 2>>$LOG || out "mounting boot"
    sleep 1
}


set_isolcpus() {

    echo -e "\tconfiguring CPU isolation"
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
    line
    download_extensions
    line
    if [[ "$DOWNLOAD_SUCCESS" == "true" ]]; then
		verify_extensions
	fi
	load_extensions
    line
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
