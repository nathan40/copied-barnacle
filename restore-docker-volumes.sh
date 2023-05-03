#!/bin/bash
#########################################################################
# Name: restore-docker-volumes.sh
# Subscription: This Script restores docker volumes to a server
#
# License:
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation, either version 3 of the License, or (at your option)
# any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.
# Based on:
# https://github.com/alaub81/backup_docker_scripts
#
# HEAVILY MODIFIED BY wally40 (wally40[-at-]gmail.com) for use with rclone
#########################################################################
# TEXT COLORS
# https://www.shellhacks.com/bash-colors/
#txtwarning='\e[1;33;1;31m' # Yellow text on red background (NOT WORKING)
txtwarning='\e[1;31m' # Bold Red text
txtstandout='\e[0;36m' # Cyan text
txtnormal='\e[0m' # Remove TXT Formatting

# WILL NEED TO BE MODIFIED TO YOUR OWN SETUP
clear -x 
echo -e "${txtnormal}#########################################################################"
echo -e "# DOCKER VOLUME RESTORE                                                 #"
echo -e "#                                                                       #"
echo -e "#        Select the original host:                                      #"
echo -e "#            1. Google                                                  #"
echo -e "#            2. HomeLab (GUINEA)                                        #"
echo -e "#            3. HomeLab (PIG)                                           #"
echo -e "#            4. Oracle                                                  #"
echo -e "#                                                                       #"
echo -e "#########################################################################"
echo -e " "
read -p "SELECT THE ORIGINAL HOST NUMBER: " host
if [ $host == 1 ]; then
	machinefolder=google/docker-volumes/
fi
if [ $host == 2 ]; then
	machinefolder=lab/guinea/
fi
if [ $host == 3 ]; then
	machinefolder=lab/pig/
fi
if [ $host == 4 ]; then
	machinefolder=oracle/docker-volumes/
fi

# SET VARIABLES FOR RCLONE AND REST OF SCRIPT
# CHANGE RCLONE PROVIDER TO THE NAME SET UP WITHIN RCLONE EX G-DRIVE, BOX, MEGA
rcloneprovider=provider
# LOCAL BACKUP FOLDER RCLONE WILL COPY FROM
backupdir=/backup

localmount=/cloud/$rcloneprovider
localcloud=/cloud/$rcloneprovider/$machinefolder
remotefolder=$backupdir/$machinefolder
extension=.tar.gz
manualrestore=y
# DO NOT CHANGE THIS VARIABLE, it is meant to be false
fullfilepath=/crap/link.sh

# CHECKS THAT THE VARIABLES HAVE BEEN CHANGED FROM DEFAULTS
if [ $rcloneprovider == "provider" ]; then
	echo -e "${txtwarning}SCRIPT WILL FAIL UNTIL PROVIDER VARIABLE IS SET${txtnormal}"
	echo -e "Going to sleep"
	sleep 60000
fi

# RCLONE - MUST COMLETE RCLONE CONFIG FIRST
echo -e "rclone is mounting to $rcloneprovider"
rclone mount $rcloneprovider:$backupdir $localmount --allow-non-empty --allow-other --daemon

clear -x
# SELECT THE FILE YOU WISH TO RESTORE FROM
while [ ! -f $fullfilepath ]; do
	find $localcloud -type f -printf "%f\n"
		echo -e " "
	read -p "Enter the volume NAME to restore: " restorevolume
	find $localcloud -name "$restorevolume*"
		echo -e " "
	read -p "Enter the assiociated DATE you wish to restore: " restoredate
	restorefile=$restorevolume-$restoredate.tar.gz
	fullfilepath=$localcloud$restorefile
	if [ ! -f $fullfilepath ]; then
		clear -x
		echo -e "${txtwarning}PLEASE CHECK YOUR ENTRIES. $restorefile DOES NOT EXIST${txtnormal}"
		echo -e " "
	fi
done

echo -e "$fullfilepath"
# CHECK THAT THERE IS A CREATED VOLUME THAT MATCHES
#volumeavailable=false
createdvolumes=$(docker volume ls -q)
echo -e "looking to match $restorevolume"
echo -e "${txtstandout}Available volumes${txtnormal}"
matchfound=n
for each in $createdvolumes; do
	echo -e "$each"
		if [ $each == $restorevolume ]; then
			echo -e "FOUND A MATCH - $each"
			matchfound=y
		fi
done

if [ $matchfound == n ]; then
	echo -e "${txtwarning}No matching volume found.${txtnormal}"
fi
read -p "Would you like to manually specify the restore parameters? (Y/N) " manualrestore
if [ $manualrestore == y ]; then
	read -p "Please enter the EXACT name of the volume to restore to: " restorevolume
	read -p "Please enter the EXACT name of the file to restore from (Include date format without extensions): " restorefilename
	restorefile=$restorefilename.tar.gz
fi

# RESTORE DOCKER VOLUME
echo -e "Restoring volume data: $restorevolume"
docker run --rm \
	-v $localcloud:/backup \
	-v $restorevolume:/data \
	alpine sh -c "cd /data && /bin/tar -xzvf /backup/$restorefile"

echo -e "###############################################"
echo -e "#  RESTORE COMPLETE - SMART, VERY SMART!      #"
echo -e "###############################################"