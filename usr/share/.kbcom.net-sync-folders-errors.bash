#!/bin/bash

declare -a GLOBAL_CODES_ERROR

GLOBAL_CODES_ERROR[10]="Source folder does not exist"
GLOBAL_CODES_ERROR[11]="Source folder is not a folder"
GLOBAL_CODES_ERROR[20]="Destination folder does not exist"
GLOBAL_CODES_ERROR[21]="Destination folder is not a folder"
GLOBAL_CODES_ERROR[30]="Backup folder does not exist"
GLOBAL_CODES_ERROR[31]="Backup folder is not a folder"
GLOBAL_CODES_ERROR[32]="Error generating backup subfolder name (cannot get system time)"
GLOBAL_CODES_ERROR[33]="Error when creating the backup subfolder"
GLOBAL_CODES_ERROR[34]="Error when backup(move) a file"
GLOBAL_CODES_ERROR[35]="Error when backup(move) a tree"
GLOBAL_CODES_ERROR[36]="Backup destination does exists and it is not a folder"
GLOBAL_CODES_ERROR[40]="Error when sync(copy) a folder attributes"
GLOBAL_CODES_ERROR[40]="Error when sync(copy) a file"
GLOBAL_CODES_ERROR[41]="Cannot sync(copy) ctime of a file"

error_show()
{
 local LOCAL_CODE_ERROR="$1"

 echo "${GLOBAL_CODES_ERROR[$LOCAL_CODE_ERROR]}!"

 if [ "$CONFIG_EXITONERROR" == "yes" ]
 then
  echo "Stop syncing!"
  exit $LOCAL_CODE_ERROR
 fi
}

error_showexit()
{
 local LOCAL_CODE_ERROR="$1"

 echo "${GLOBAL_CODES_ERROR[$LOCAL_CODE_ERROR]}!"
 echo "Stop syncing!"
 exit $LOCAL_CODE_ERROR
}
