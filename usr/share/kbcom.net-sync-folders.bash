#!/bin/bash

### Include functions

GLOBAL_FOLDER_SCRIPT=$(/usr/bin/dirname "$0")

if [ ${GLOBAL_FOLDER_SCRIPT:0:1} == "." ]
then
 GLOBAL_FOLDER_SCRIPT="$(/bin/pwd)${GLOBAL_FOLDER_SCRIPT:1}"
elif [ ${GLOBAL_FOLDER_SCRIPT:0:1} != "/" ]
then
 GLOBAL_FOLDER_SCRIPT="$(/bin/pwd)/$GLOBAL_FOLDER_SCRIPT"
fi

source "$GLOBAL_FOLDER_SCRIPT/.kbcom.net-sync-folders.bash"


### Begining of execution

CONFIG_ROOTFOLDER_BACKUP="/opt/.probe/backup"
CONFIG_ROOTFOLDER_SOURCE="/opt/.probe/source"
CONFIG_ROOTFOLDER_DESTINATION="/opt/.probe/destination"

GLOBAL_ROOTFOLDER_BACKUP=""

backup_checkcreate_backupfolder

echo "..............$GLOBAL_ROOTFOLDER_BACKUP"

#check létezik és nem üres
scan_folder "$CONFIG_ROOTFOLDER_SOURCE" "$CONFIG_ROOTFOLDER_DESTINATION"
