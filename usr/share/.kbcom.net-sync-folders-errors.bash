#!/bin/bash

declare -a GLOBAL_CODES_ERROR

GLOBAL_MESSAGE_ERRORSTOP="Stop syncing!"

# Check errors
GLOBAL_CODES_ERROR[10]="Folder does not exist"
GLOBAL_CODES_ERROR[11]="Entry is not a folder"
GLOBAL_CODES_ERROR[12]="Entry is empty"
GLOBAL_CODES_ERROR[13]="Error generating dated folders name (cannot get system time)"
GLOBAL_CODES_ERROR[14]="Error when creating a dated folders"

# Copy errors
GLOBAL_CODES_ERROR[20]="Error when sync(copy) a folder entry attributes (time)"
GLOBAL_CODES_ERROR[21]="Error when sync(copy) a folder entry attributes (mode)"
GLOBAL_CODES_ERROR[22]="Error when sync(copy) a folder entry attributes (owner)"
GLOBAL_CODES_ERROR[23]="Error when sync(copy) a folder entry attributes (acl)"
GLOBAL_CODES_ERROR[24]="Error when sync(copy) a folder (cannot create folder)"
GLOBAL_CODES_ERROR[25]="Error when sync(copy) a file"
GLOBAL_CODES_ERROR[26]="Cannot sync(copy) ctime of a file"
GLOBAL_CODES_ERROR[27]="Cannot locate source folder (may be wanished)"

# Move errors
GLOBAL_CODES_ERROR[31]="Error when backup(move) a file/tree"

error_show()
{
 local LOCAL_CODE_ERROR="$1"

 echo "${GLOBAL_CODES_ERROR[$LOCAL_CODE_ERROR]}!"

 if [ "$CONFIG_EXITONERROR" == "yes" ]
 then
  echo "$GLOBAL_MESSAGE_ERRORSTOP"
  exit $LOCAL_CODE_ERROR
 fi
}

error_showexit()
{
 local LOCAL_CODE_ERROR="$1"

 echo "${GLOBAL_CODES_ERROR[$LOCAL_CODE_ERROR]}!"
 echo "$GLOBAL_MESSAGE_ERRORSTOP"
 exit $LOCAL_CODE_ERROR
}
