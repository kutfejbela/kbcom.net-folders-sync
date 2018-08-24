#!/bin/bash

filesystem_check_folder()
{
 if [ ! -x "$CONFIG_ROOTFOLDER_BACKUP" ]
 then
  error_showexit 10
 fi

 if [ ! -d "$CONFIG_ROOTFOLDER_BACKUP" ]
 then
  error_showexit 11
 fi
}

filesystem_create_datedfolders()
{
 local LOCAL_DATETIME_NOW

 LOCAL_DATETIME_NOW=$(/bin/date +%Y%m%d%H%M%S)

 if [ "${#LOCAL_DATETIME_NOW}" -ne 14 ]
 then
  error_showexit 12
 fi

 GLOBAL_ROOTFOLDER_BACKUP="$CONFIG_ROOTFOLDER_BACKUP/${LOCAL_DATETIME_NOW:0:6}/${LOCAL_DATETIME_NOW:0:8}/$LOCAL_DATETIME_NOW"

 /bin/mkdir -p "$GLOBAL_ROOTFOLDER_BACKUP"

 if [ "$?" -ne 0 ]
 then
  error_showexit 13
 fi
}

filesystem_copy_attributes()
{
 # Copy folder entry attributes
 local LOCAL_FOLDER_COPYFROM="$1"
 local LOCAL_FOLDERENTRY_COPYFROM="$2"
 local LOCAL_FOLDER_COPYTO="$3"

 /bin/touch --reference="$LOCAL_FOLDER_COPYFROM/$LOCAL_FOLDERENTRY_COPYFROM" "$LOCAL_FOLDER_COPYTO/$LOCAL_FOLDERENTRY_COPYFROM"

 if [ "$?" -ne 0 ]
 then
  error_show 20
 fi

 /bin/chmod --reference="$LOCAL_FOLDER_COPYFROM/$LOCAL_FOLDERENTRY_COPYFROM" "$LOCAL_FOLDER_COPYTO/$LOCAL_FOLDERENTRY_COPYFROM"

 if [ "$?" -ne 0 ]
 then
  error_show 21
 fi

 /bin/chown --reference="$LOCAL_FOLDER_COPYFROM/$LOCAL_FOLDERENTRY_COPYFROM" "$LOCAL_FOLDER_COPYTO/$LOCAL_FOLDERENTRY_COPYFROM"

 if [ "$?" -ne 0 ]
 then
  error_show 22
 fi

 /usr/bin/getfacl -p "$LOCAL_FOLDER_COPYFROM/$LOCAL_FOLDERENTRY_COPYFROM" | /usr/bin/setfacl --set-file=- "$LOCAL_FOLDER_COPYTO/$LOCAL_FOLDERENTRY_COPYFROM"

 if [ "$?" -ne 0 ]
 then
  error_show 23
 fi
}

filesystem_copy_folder()
{
 # Copy folder (create and copy attributes)
 local LOCAL_FOLDER_COPYFROM="$1"
 local LOCAL_FOLDERNAME_COPYFROM="$2"
 local LOCAL_FOLDER_COPYTO="$3"

 /bin/mkdir "$LOCAL_FOLDER_COPYTO/$LOCAL_FOLDERNAME_COPYFROM"

 if [ "$?" -ne 0 ]
 then
  error_showexit 24
 fi

 filesystem_copy_attributes "$LOCAL_FOLDER_COPYFROM/$LOCAL_FOLDERNAME_COPYFROM" "$LOCAL_FOLDER_COPYTO/$LOCAL_FOLDERNAME_COPYFROM"
}

filesystem_copy_file()
{
 # Copy file with ctime
 local LOCAL_FOLDER_COPYFROM="$1"
 local LOCAL_FILENAME_COPYFROM="$2"
 local LOCAL_FOLDER_COPYTO="$3"

 local LOCAL_CTIME_COPYFROM

 LOCAL_CTIME_COPYFROM=$(/usr/bin/stat -c "%Z" "$LOCAL_FOLDER_COPYFROM/$LOCAL_FILENAME_COPYFROM")

 /bin/cp -av "$LOCAL_FOLDER_COPYFROM/$LOCAL_FILENAME_COPYFROM" "$LOCAL_FOLDER_COPYTO"

 if [ "$?" -ne 0 ]
 then
  error_show 25
 fi

 /usr/bin/setfattr -n "user.kbcom.net:ctime" -v "$LOCAL_CTIME_COPYFROM" "$LOCAL_FOLDER_COPYTO/$LOCAL_FILENAME_COPYFROM"

 if [ "$?" -ne 0 ]
 then
  error_show 26
 fi
}

filesystem_copy_tree()
{
 # New tree creation
 local LOCAL_FOLDER_COPYFROM="$1"
 local LOCAL_FOLDERNAME_COPYFROM="$2"
 local LOCAL_FOLDER_COPYTO="$3"

 local LOCAL_ENTRYARRAY_SOURCEFOLDER
 local LOCAL_ENTRY_SOURCEFOLDER

 filesystem_copy_folder "$LOCAL_FOLDER_COPYFROM" "$LOCAL_FOLDERNAME_COPYFROM" "$LOCAL_FOLDER_COPYTO"

 cd "$LOCAL_FOLDER_COPYFROM/$LOCAL_FOLDERNAME_COPYFROM"

 if [ "$?" -ne 0 ]
 then
  error_show 27
 fi

 LOCAL_ENTRYARRAY_COPYFROM=(*)

 if [ "$?" -ne 0 ]
 then
  error_show 27
 fi

 IFS=$'\n'
 for LOCAL_ENTRY_COPYFROM in ${LOCAL_ENTRYARRAY_COPYFROM[@]}
 do
  # If folder empty
  if [ "$LOCAL_ENTRY_COPYFROM" == "*" ]
  then
   break
  fi

  if [ -d "$LOCAL_FOLDER_COPYFROM/$LOCAL_ENTRY_COPYFROM" ]
  then
   filesystem_copytree "$LOCAL_FOLDER_COPYFROM" "$LOCAL_ENTRY_COPYFROM" "$LOCAL_FOLDER_COPYTO"
  else
   filesystem_copyfile "$LOCAL_FOLDER_COPYFROM" "$LOCAL_ENTRY_COPYFROM" "$LOCAL_FOLDER_COPYTO"
  fi
 done
}

filesystem_move_filetree()
{
 # Move a tree
 local LOCAL_FOLDER_MOVEFROM="$1"
 local LOCAL_FOLDERENTRYNAME_MOVEFROM="$2"
 local LOCAL_FOLDER_MOVETO="$3"

 /bin/mv "$LOCAL_FOLDER_MOVEFROM/$LOCAL_FOLDERENTRYNAME_MOVEFROM" "$LOCAL_FOLDER_MOVETO"

 if [ $? -ne 0 ]
 then
  error_showexit 31
 fi
}

filsystem_copy_parentfolders()
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
