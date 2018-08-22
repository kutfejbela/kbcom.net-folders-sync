#!/bin/bash

filesystem_checkfolder()
{
 if [ ! -x "$CONFIG_ROOTFOLDER_BACKUP" ]
 then
  error_showexit 30
 fi

 if [ ! -d "$CONFIG_ROOTFOLDER_BACKUP" ]
 then
  error_showexit 31
 fi
}

filesystem_createdatedfolder()
{
 local LOCAL_DATETIME_NOW

 LOCAL_DATETIME_NOW=$(/bin/date +%Y%m%d%H%M%S)

 if [ "${#LOCAL_DATETIME_NOW}" -ne 14 ]
 then
  error_showexit 32
 fi

 GLOBAL_ROOTFOLDER_BACKUP="$CONFIG_ROOTFOLDER_BACKUP/${LOCAL_DATETIME_NOW:0:6}/${LOCAL_DATETIME_NOW:0:8}/$LOCAL_DATETIME_NOW"

 /bin/mkdir -p "$GLOBAL_ROOTFOLDER_BACKUP"

 if [ "$?" -ne 0 ]
 then
  error_showexit 33
 fi
}

filesystem_copyfolderattributes()
{
 # Copy folder attributes
 local LOCAL_FOLDER_COPYFROM="$1"
 local LOCAL_FOLDER_COPYTO="$2"

 /bin/touch --reference="$LOCAL_FOLDER_COPYFROM" "$LOCAL_FOLDER_COPYTO"

 if [ "$?" -ne 0 ]
 then
  error_show 40
 fi

 /bin/chmod --reference="$LOCAL_FOLDER_COPYFROM" "$LOCAL_FOLDER_COPYTO"

 if [ "$?" -ne 0 ]
 then
  error_show 40
 fi

 /bin/chown --reference="$LOCAL_FOLDER_COPYFROM" "$LOCAL_FOLDER_COPYTO"

 if [ "$?" -ne 0 ]
 then
  error_show 40
 fi

 /usr/bin/getfacl -p "$LOCAL_FOLDER_COPYFROM" | /usr/bin/setfacl --set-file=- "$LOCAL_FOLDER_COPYTO"

 if [ "$?" -ne 0 ]
 then
  error_show 40
 fi
}

filesystem_copyfile()
{
 # New file creation
 local LOCAL_FOLDER_COPYFROM="$1"
 local LOCAL_FILENAME_COPYFROM="$2"
 local LOCAL_FOLDER_COPYTO="$3"

 local LOCAL_CTIME_COPYFROM

 LOCAL_CTIME_COPYFROM=$(/usr/bin/stat -c "%Z" "$LOCAL_FOLDER_COPYFROM/$LOCAL_FILENAME_COPYFROM")

 /bin/cp -av "$LOCAL_FOLDER_COPYFROM/$LOCAL_FILENAME_COPYFROM" "$LOCAL_FOLDER_COPYTO"

 if [ "$?" -ne 0 ]
 then
  error_show 40
 fi

 /usr/bin/setfattr -n "user.kbcom.net:ctime" -v "$LOCAL_CTIME_COPYFROM" "$LOCAL_FOLDER_COPYTO/$LOCAL_FILENAME_COPYFROM"

 if [ "$?" -ne 0 ]
 then
  error_show 41
 fi
}

filesystem_movefile()
{
 # Move a file
 local LOCAL_FOLDER_MOVEFROM="$1"
 local LOCAL_FILENAME_MOVEFROM="$2"
 local LOCAL_FOLDER_MOVETO="$3"

 /bin/mv "$LOCAL_FOLDER_MOVEFROM/$LOCAL_FILENAME_MOVEFROM" "$LOCAL_FOLDER_MOVETO"

 if [ $? -ne 0 ]
 then
  error_showexit 34
 fi
}

filesystem_movetree()
{
 # Move a tree
 local LOCAL_FOLDER_MOVEFROM="$1"
 local LOCAL_FOLDERNAME_MOVEFROM="$2"
 local LOCAL_FOLDER_MOVETO="$3"

 /bin/mv "$LOCAL_FOLDER_MOVEFROM/$LOCAL_FOLDERNAME_MOVEFROM" "$LOCAL_FOLDER_MOVETO"

 if [ $? -ne 0 ]
 then
  error_showexit 34
 fi
}

backup_copy_parentfolders()
{
# check not vanished
 local LOCAL_ROOTFOLDER_COPYFROM="$CONFIG_ROOTFOLDER_DESTINATION"
 local LOCAL_SUBFOLDER_COPYFROM="$1"
 local LOCAL_ROOTFOLDER_COPYTO="$GLOBAL_ROOTFOLDER_BACKUP"

 local LOCAL_SUBFOLDER_COPYREST
 local LOCAL_SUBFOLDER_COPYNEXT
 local LOCAL_SUBFOLDER_COPYNOW

 if [ -x "${LOCAL_ROOTFOLDER_COPYTO}${LOCAL_SUBFOLDER_COPYFROM}" ]
 then
  if [ ! -d "${LOCAL_ROOTFOLDER_COPYTO}${LOCAL_SUBFOLDER_COPYFROM}" ]
  then
    error_showexit 36
  else
   return
  fi
 fi

 LOCAL_SUBFOLDER_COPYREST="$LOCAL_SUBFOLDER_COPYFROM"
 LOCAL_SUBFOLDER_COPYNEXT=${LOCAL_SUBFOLDER_COPYREST%/*}
 LOCAL_SUBFOLDER_COPYNOW=""


 while [ "$LOCAL_SUBFOLDER_COPYNEXT" != "" ]
 do
  LOCAL_SUBFOLDER_COPYNOW="${LOCAL_SUBFOLDER_COPYNOW}${LOCAL_SUBFOLDER_COPYNEXT}"

  /bin/mkdir "$LOCAL_ROOTFOLDER_COPYTO/$LOCAL_SUBFOLDER_COPYNOW"
  filesystem_copyfolderattributes "$LOCAL_ROOTFOLDER_COPYFROM/$LOCAL_SUBFOLDER_COPYNOW" "$LOCAL_ROOTFOLDER_COPYTO/$LOCAL_SUBFOLDER_COPYNOW"

  LOCAL_SUBFOLDER_COPYREST="${LOCAL_SUBFOLDER_COPYREST:${#LOCAL_SUBFOLDER_COPYNEXT}}"
  LOCAL_SUBFOLDER_COPYNEXT=${LOCAL_SUBFOLDER_COPYREST%/*}
 done

 /bin/mkdir "${LOCAL_ROOTFOLDER_COPYTO}${LOCAL_SUBFOLDER_COPYFROM}"
 filesystem_copyfolderattributes "${LOCAL_ROOTFOLDER_COPYFROM}${LOCAL_SUBFOLDER_COPYFROM}" "${LOCAL_ROOTFOLDER_COPYTO}${LOCAL_SUBFOLDER_COPYFROM}"
}

filesystem_copytree()
{
 # New tree creation
 local LOCAL_FOLDER_COPYFROM="$1"
 local LOCAL_FOLDER_COPYTO="$2"

 local LOCAL_ENTRYARRAY_SOURCEFOLDER
 local LOCAL_ENTRY_SOURCEFOLDER

 cd "$LOCAL_FOLDER_COPYFROM"
 LOCAL_ENTRYARRAY_SOURCEFOLDER=(*)

 IFS=$'\n'
 for LOCAL_ENTRY_SOURCEFOLDER in ${LOCAL_ENTRYARRAY_SOURCEFOLDER[@]}
 do
  # If folder empty
  if [ "$LOCAL_ENTRY_SOURCEFOLDER" == "*" ]
  then
   break
  fi

  if [ -d "$LOCAL_FOLDER_COPYFROM/$LOCAL_ENTRY_SOURCEFOLDER" ]
  then
   /bin/mkdir "$LOCAL_FOLDER_COPYTO/$LOCAL_ENTRY_SOURCEFOLDER"
   filesystem_copyfolderattributes "$LOCAL_FOLDER_COPYFROM/$LOCAL_ENTRY_SOURCEFOLDER" "$LOCAL_FOLDER_COPYTO/$LOCAL_ENTRY_SOURCEFOLDER"
   filesystem_copytree "$LOCAL_FOLDER_COPYFROM/$LOCAL_ENTRY_SOURCEFOLDER" "$LOCAL_FOLDER_COPYTO/$LOCAL_ENTRY_SOURCEFOLDER"
  else
   filesystem_copyfile "$LOCAL_FOLDER_COPYFROM" "$LOCAL_ENTRY_SOURCEFOLDER" "$LOCAL_FOLDER_COPYTO"
  fi
 done
}
