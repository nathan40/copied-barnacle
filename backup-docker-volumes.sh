#!/bin/bash
#########################################################################
#Name: backup-docker-volumes.sh
#Subscription: This Script backups docker volumes to a backup directory
##by A. Laub
#andreas[-at-]laub-home.de
#
#License:
#This program is free software: you can redistribute it and/or modify it
#under the terms of the GNU General Public License as published by the
#Free Software Foundation, either version 3 of the License, or (at your option)
#any later version.
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
#or FITNESS FOR A PARTICULAR PURPOSE.
#
# https://github.com/alaub81/backup_docker_scripts
#
# HEAVILY MODIFIED BY nathan40 (wally40[-at-]gmail.com) for use with rclone
#########################################################################
# SET VARIABLES FOR RCLONE AND REST OF SCRIPT
# CHANGE RCLONE PROVIDER TO THE NAME SET UP WITHIN RCLONE EX G-DRIVE, BOX, MEGA
rcloneprovider=provider
# LOCAL BACKUP FOLDER RCLONE WILL MOUNT TO
backupdir=/backup
# CREATES A SERVER SCRTUCTURE WITHIN REMOTE REPOSITORY EXAMPLE: ORACLE/SERVER1/
machinefolder=folder/path/
# CREATES LOCAL AND REMOTE FOLDERS TO BE CALLED IN THE SCRIPT
localfolder=$backupdir/$rcloneprovider
localmount=/cloud/$rcloneprovider
localcloud=/cloud/$rcloneprovider/$machinefolder
remotefolder=$backupdir/$machinefolder

# How many Days old should a backup be available?
localdays=0
clouddays=36

# Timestamp definition for the backupfiles (example: $(date +"%Y%m%d%H%M") = 20200124-2034)
TIMESTAMP=$(date +"%Y%m%d")

# Check local folders are created
if [ ! -d $localfolder ]; then
     mkdir -p $localfolder
else
     echo "Local Folder exists"
fi
if [ ! -d $localmount ]; then
     mkdir -p $localmount
else
     echo "Local Mount Folder exists"
fi
# RCLONE - MUST COMLETE RCLONE CONFIG FIRST
echo -e "rclone is mounting to $rcloneprovider"
rclone mount $rcloneprovider:$backupdir $localmount --allow-non-empty --allow-other --daemon

# Set the language
export LANG="en_US.UTF-8"
# Load the Pathes
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Which Volumes you want to backup? Volume names separated by space
#VOLUME="volume_name1"
# THE EXAMPLE BELOW WILL BACK UP ALL AVAILABLE VOLUMES
#VOLUME=$(docker volume ls  -q)
# you can filter all Volumes with grep (include only) or grep -v (exclude) or a combination
# Listing volume_name1, etc will exclude the volume from backing up
VOLUME=$(docker volume ls -q | grep -v -e "volume_name1" -e "Volume_Name2")

#### Do the stuff ###
echo -e "Prepping cloud storage:"
# RCLONE - MUST COMLETE RCLONE CONFIG FIRST
rclone delete $rcloneprovider:$remotefolder/ --min-age $clouddays"d"
echo -e "Backing up volumes:"
for i in $VOLUME; do
        echo -e "     $i";
        docker run --rm \
        -v $localfolder:/backup \
        -v $i:/data:ro \
        -e TIMESTAMP=$TIMESTAMP \
        -e i=$i ${MEMORYLIMIT} \
        --name volumebackup \
        alpine sh -c "cd /data && /bin/tar -czf /backup/$i-$TIMESTAMP.tar.gz ."
        #debian:stretch-slim bash -c "cd /data && /bin/tar -czf /backup/$i-$TIMESTAMP.tar.gz ."
done

echo -e "$TIMESTAMP Local Backup completed"

echo -e "Copying to $rcloneprovider"
# RCLONE - MUST COMLETE RCLONE CONFIG FIRST
rclone copy --progress $localfolder $rcloneprovider:$remotefolder

echo -e "Cleaning up local backup folder"
 if [ $localdays == 0 ]; then
	find $localfolder -name "*.tar.gz" -delete
	else
	find $localfolder -name "*.tar.gz" -daystart -mtime -$localdays -delete
	fi

echo -e "###############################################"
echo -e "#  BACKUP COMPLETE - SMART, VERY SMART!       #"
echo -e "###############################################"
