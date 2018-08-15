declare -a GLOBAL_CODES_ERROR

GLOBAL_CODES_ERROR[10]="Source folder does not exist"
GLOBAL_CODES_ERROR[11]="Source folder is not a folder"
GLOBAL_CODES_ERROR[20]="Destination folder does not exist"
GLOBAL_CODES_ERROR[21]="Destination folder is not a folder"
GLOBAL_CODES_ERROR[30]="Backup folder does not exist"
GLOBAL_CODES_ERROR[31]="Backup folder is not a folder"

### Make backup root
### Copy subfolder
### Build vanish check

error_show()
{
 local LOCAL_CODE_ERROR="$1"

 echo "$GLOBAL_CODES_ERROR[$LOCAL_CODE_ERROR]"

 if [ "$CONFIG_EXITONERROR" == "yes" ]
 then
  exit $LOCAL_CODE_ERROR
 fi
}

error_showexit()
{
 local LOCAL_CODE_ERROR="$1"

 echo "$GLOBAL_CODES_ERROR[$LOCAL_CODE_ERROR]"
 exit $LOCAL_CODE_ERROR
}

backup_checkcreate_backupfolder()
{
 local LOCAL_ROOTFOLDER_BACKUP="$1"
 local LOCAL_SUBFOLDER_BACKUP="$2"

 if [ -x "$LOCAL_ROOTFOLDER_BACKUP" ]
 then
  error_showexit 30
 fi

 if [ -d "$LOCAL_ROOTFOLDER_BACKUP" ]
 then
  error_showexit 31
 fi

 /bin/mkdir -p "$LOCAL_ROOTFOLDER_BACKUP/$LOCAL_SUBFOLDER_BACKUP"
}

backup_copy_parentfolders()
{
# separate folders from string
# check not vanished
# create folders and copy folders attribute
 local LOCAL_ROOTFOLDER_SOURCE="$1"
 local LOCAL_FILE_SOURCE="$2"
 local LOCAL_FOLDER_BACKUP="$3"

ls -l
}

backup_move_file()
{
# Backup file
 local LOCAL_ROOTFOLDER_SOURCE="$1"
 local LOCAL_FILE_SOURCE="$2"
 local LOCAL_FOLDER_DESTINATION="$3"

 /bin/mv "$LOCAL_FOLDER_SOURCE" "$LOCAL_FOLDER_DESTINATION"
}

backup_move_tree()
{
# Backup tree
 local LOCAL_ROOTFOLDER_SOURCE="$1"
 local LOCAL_FOLDER_SOURCE="$2"
 local LOCAL_ROOTFOLDER_DESTINATION="$3"

 /bin/mv "$LOCAL_FOLDER_SOURCE" "$LOCAL_FOLDER_DESTINATION"
}

sync_copy_folderattribute()
{
# Copy folder attributes
 local LOCAL_FOLDER_SOURCE="$1"
 local LOCAL_FOLDER_DESTINATION="$2"

 /bin/touch --reference="$LOCAL_FOLDER_SOURCE" "$LOCAL_FOLDER_DESTINATION"
 /bin/chmod --reference="$LOCAL_FOLDER_SOURCE" "$LOCAL_FOLDER_DESTINATION"
 /bin/chown --reference="$LOCAL_FOLDER_SOURCE" "$LOCAL_FOLDER_DESTINATION"
 /usr/bin/getfacl -p "$LOCAL_FOLDER_SOURCE" | /usr/bin/setfacl --set-file=- "$LOCAL_FOLDER_DESTINATION"
}

sync_copy_file()
{
# New file creation
 local LOCAL_FOLDER_SOURCE="$1"
 local LOCAL_FILENAME_SOURCE="$2"
 local LOCAL_FOLDER_DESTINATION="$3"

 local LOCAL_CTIME_SOURCE

 LOCAL_CTIME_SOURCE=$(/usr/bin/stat -c "%Z" "$LOCAL_FOLDER_SOURCE/$LOCAL_FILENAME_SOURCE")

 /bin/cp -av "$LOCAL_FOLDER_SOURCE/$LOCAL_FILENAME_SOURCE" "$LOCAL_FOLDER_DESTINATION"
 /usr/bin/setfattr -n "user.kbcom.net:ctime" -v "$LOCAL_CTIME_SOURCE" "$LOCAL_FOLDER_DESTINATION/$LOCAL_FILENAME_SOURCE"
}

sync_copy_tree()
{
# New tree creation
 local LOCAL_FOLDER_SOURCE="$1"
 local LOCAL_FOLDER_DESTINATION="$2"

 local LOCAL_ENTRYARRAY_SOURCEFOLDER
 local LOCAL_ENTRY_SOURCEFOLDER

 cd "$LOCAL_FOLDER_SOURCE"
 LOCAL_ENTRYARRAY_SOURCEFOLDER=(*)

 IFS=$'\n'
 for LOCAL_ENTRY_SOURCEFOLDER in ${LOCAL_ENTRYARRAY_SOURCEFOLDER[@]}
 do
  if [ -d "$LOCAL_FOLDER_SOURCE/$LOCAL_ENTRY_SOURCEFOLDER" ]
  then
   /bin/mkdir "$LOCAL_FOLDER_DESTINATION/$LOCAL_ENTRY_SOURCEFOLDER"
   sync_copy_folderattribute "$LOCAL_FOLDER_SOURCE/$LOCAL_ENTRY_SOURCEFOLDER" "$LOCAL_FOLDER_DESTINATION/$LOCAL_ENTRY_SOURCEFOLDER"
   sync_copy_tree "$LOCAL_FOLDER_SOURCE/$LOCAL_ENTRY_SOURCEFOLDER" "$LOCAL_FOLDER_DESTINATION/$LOCAL_ENTRY_SOURCEFOLDER"
  else
   sync_copy_file "$LOCAL_FOLDER_SOURCE" "$LOCAL_ENTRY_SOURCEFOLDER" "$LOCAL_FOLDER_DESTINATION"
  fi
 done
}

backupcopy_file()
{
# Overwrite file
 local LOCAL_FILE_SOURCE="$1"
 local LOCAL_FILE_DESTINATION="$2"
 local LOCAL_FOLDER_BACKUP="$3"

 copy_parentfolders "$LOCAL_FOLDER_BACKUP" "$GLOBAL_FOLDER_SOURCE" "$LOCAL_FILE_SOURCE"
 move_tree "$GLOBAL_FOLDER_DESTINATION" "$LOCAL_FILE_DESTINATION" "$LOCAL_FOLDER_BACKUP"
 sync_copy_file "$LOCAL_FILE_SOURCE" "$LOCAL_FILE_DESTINATION"
}

backupdelete_file()
{
# Delete file
 local LOCAL_FILE_DESTINATION="$1"
 local LOCAL_FOLDER_BACKUP="$2"

 copy_parentfolders "$LOCAL_FOLDER_BACKUP" "$GLOBAL_FOLDER_DESTINATION" "$LOCAL_FILE_DESTINATION"
 move_tree "$GLOBAL_FOLDER_DESTINATION" "$LOCAL_FILE_DESTINATION" "$LOCAL_FOLDER_BACKUP"
}

backupdelete_tree()
{
# Delete tree
 local LOCAL_FOLDER_SOURCE="$1"
 local LOCAL_FOLDER_BACKUP="$2"

 copy_parentfolders "$LOCAL_FOLDER_BACKUP" "$GLOBAL_FOLDER_DESTINATION" "$LOCAL_FOLDER_DESTINATION"
 move_tree "$GLOBAL_FOLDER_DESTINATION" "$LOCAL_FOLDER_DESTINATION" "$LOCAL_FOLDER_BACKUP"
}

scan_folder()
{
 local LOCAL_FOLDER_SOURCE="$1"
 local LOCAL_FOLDER_DESTINATION="$2"

 local LOCAL_ENTRYARRAY_DESTINATIONFOLDER
 local LOCAL_ENTRYARRAY_SOURCEFOLDER
 local LOCAL_COUNTER_SOURCEFOLDER
 local LOCAL_COUNTER_DESTINATIONFOLDER

 local LOCAL_CTIME_SOURCE
 local LOCAL_CTIME_DESTINATION
 local LOCAL_STAT_SOURCE
 local LOCAL_STAT_DESTINATION
 local LOCAL_ACL_SOURCE
 local LOCAL_ACL_DESTINATION

 local LOCAL_BOOLEAN_EQUAL=true

 cd "$LOCAL_FOLDER_DESTINATION"
 LOCAL_ENTRYARRAY_DESTINATIONFOLDER=(*)

 cd "$LOCAL_FOLDER_SOURCE"
 LOCAL_ENTRYARRAY_SOURCEFOLDER=(*)

 LOCAL_COUNTER_SOURCEFOLDER=0
 LOCAL_COUNTER_DESTINATIONFOLDER=0

 if [ "${LOCAL_ENTRYARRAY_SOURCEFOLDER[LOCAL_COUNTER_SOURCEFOLDER]}" == "*" ]
 then
  LOCAL_COUNTER_SOURCEFOLDER=1
 fi

 if [ "${LOCAL_ENTRYARRAY_DESTINATIONFOLDER[LOCAL_COUNTER_DESTINATIONFOLDER]}" == "*" ]
 then
  LOCAL_COUNTER_DESTINATIONFOLDER=1
 fi

 while true
 do
  if [ ${#LOCAL_ENTRYARRAY_SOURCEFOLDER[*]} -le $LOCAL_COUNTER_SOURCEFOLDER -a ${#LOCAL_ENTRYARRAY_DESTINATIONFOLDER[*]} -le $LOCAL_COUNTER_DESTINATIONFOLDER ]
  then
   break
  elif [ ${#LOCAL_ENTRYARRAY_SOURCEFOLDER[*]} -le $LOCAL_COUNTER_SOURCEFOLDER ]
  then

   # Deleted file or folder
   if [ -d "$LOCAL_FOLDER_DESTINATION/${LOCAL_ENTRYARRAY_DESTINATIONFOLDER[LOCAL_COUNTER_DESTINATIONFOLDER]}" ]
   then
    echo "Fájl könyvtár: ${LOCAL_ENTRYARRAY_DESTINATIONFOLDER[LOCAL_COUNTER_DESTINATIONFOLDER]} ($LOCAL_COUNTER_SOURCEFOLDER, $LOCAL_COUNTER_DESTINATIONFOLDER)"
   else
    echo "Fájl törlése: ${LOCAL_ENTRYARRAY_DESTINATIONFOLDER[LOCAL_COUNTER_DESTINATIONFOLDER]} ($LOCAL_COUNTER_SOURCEFOLDER, $LOCAL_COUNTER_DESTINATIONFOLDER)"
   fi

   ((LOCAL_COUNTER_DESTINATIONFOLDER++))

  elif [ ${#LOCAL_ENTRYARRAY_DESTINATIONFOLDER[*]} -le $LOCAL_COUNTER_DESTINATIONFOLDER ]
  then

   # New file or folder
   if [ -d "$LOCAL_FOLDER_SOURCE/${LOCAL_ENTRYARRAY_SOURCEFOLDER[LOCAL_COUNTER_SOURCEFOLDER]}" ]
   then
    echo "Copy tree \"$LOCAL_FOLDER_SOURCE/${LOCAL_ENTRYARRAY_SOURCEFOLDER[LOCAL_COUNTER_SOURCEFOLDER]}\" \"$LOCAL_FOLDER_DESTINATION/${LOCAL_ENTRYARRAY_SOURCEFOLDER[LOCAL_COUNTER_SOURCEFOLDER]}\""
    /bin/mkdir "$LOCAL_FOLDER_DESTINATION/${LOCAL_ENTRYARRAY_SOURCEFOLDER[LOCAL_COUNTER_SOURCEFOLDER]}"
    sync_copy_folderattribute "$LOCAL_FOLDER_SOURCE/${LOCAL_ENTRYARRAY_SOURCEFOLDER[LOCAL_COUNTER_SOURCEFOLDER]}" "$LOCAL_FOLDER_DESTINATION/${LOCAL_ENTRYARRAY_SOURCEFOLDER[LOCAL_COUNTER_SOURCEFOLDER]}"
    sync_copy_tree "$LOCAL_FOLDER_SOURCE/${LOCAL_ENTRYARRAY_SOURCEFOLDER[LOCAL_COUNTER_SOURCEFOLDER]}" "$LOCAL_FOLDER_DESTINATION/${LOCAL_ENTRYARRAY_SOURCEFOLDER[LOCAL_COUNTER_SOURCEFOLDER]}"
   else
    sync_copy_file "$LOCAL_FOLDER_SOURCE" "${LOCAL_ENTRYARRAY_SOURCEFOLDER[LOCAL_COUNTER_SOURCEFOLDER]}" "$LOCAL_FOLDER_DESTINATION"
   fi

   ((LOCAL_COUNTER_SOURCEFOLDER++))

  else

   if [ "${LOCAL_ENTRYARRAY_SOURCEFOLDER[LOCAL_COUNTER_SOURCEFOLDER]}" == "${LOCAL_ENTRYARRAY_DESTINATIONFOLDER[LOCAL_COUNTER_DESTINATIONFOLDER]}" ]
   then
    LOCAL_BOOLEAN_EQUAL=true

   if [ -d "$LOCAL_FOLDER_SOURCE/${LOCAL_ENTRYARRAY_SOURCEFOLDER[LOCAL_COUNTER_SOURCEFOLDER]}" ] && [ -d "$LOCAL_FOLDER_DESTINATION/${LOCAL_ENTRYARRAY_DESTINATIONFOLDER[LOCAL_COUNTER_DESTINATIONFOLDER]}" ]
   then
    LOCAL_STAT_SOURCE=$(/usr/bin/stat -c "%a%u%g%Y" "$LOCAL_FOLDER_SOURCE/${LOCAL_ENTRYARRAY_SOURCEFOLDER[LOCAL_COUNTER_SOURCEFOLDER]}")
    LOCAL_STAT_DESTINATION=$(/usr/bin/stat -c "%a%u%g%Y" "$LOCAL_FOLDER_DESTINATION/${LOCAL_ENTRYARRAY_DESTINATIONFOLDER[LOCAL_COUNTER_DESTINATIONFOLDER]}")

    if [ "$LOCAL_STAT_SOURCE" != "$LOCAL_STAT_DESTINATION" ]
    then
     LOCAL_BOOLEAN_EQUAL=false
    fi

    if [ "$LOCAL_BOOLEAN_EQUAL" = true ]
    then
     LOCAL_ACL_SOURCE=$(/usr/bin/getfacl -cp "$LOCAL_FOLDER_SOURCE/${LOCAL_ENTRYARRAY_SOURCEFOLDER[LOCAL_COUNTER_SOURCEFOLDER]}")
     LOCAL_ACL_DESTINATION=$(/usr/bin/getfacl -cp "$LOCAL_FOLDER_DESTINATION/${LOCAL_ENTRYARRAY_DESTINATIONFOLDER[LOCAL_COUNTER_DESTINATIONFOLDER]}")

     if [ "$LOCAL_ACL_SOURCE" != "$LOCAL_ACL_DESTINATION" ]
     then
      LOCAL_BOOLEAN_EQUAL=false
     fi
    fi

    if [ "$LOCAL_BOOLEAN_EQUAL" = false ]
    then
     sync_copy_folderattribute "$LOCAL_FOLDER_SOURCE/${LOCAL_ENTRYARRAY_SOURCEFOLDER[LOCAL_COUNTER_SOURCEFOLDER]}" "$LOCAL_FOLDER_DESTINATION/${LOCAL_ENTRYARRAY_DESTINATIONFOLDER[LOCAL_COUNTER_DESTINATIONFOLDER]}"
    fi

    scan_folder "$LOCAL_FOLDER_SOURCE/${LOCAL_ENTRYARRAY_SOURCEFOLDER[LOCAL_COUNTER_SOURCEFOLDER]}" "$LOCAL_FOLDER_DESTINATION/${LOCAL_ENTRYARRAY_DESTINATIONFOLDER[LOCAL_COUNTER_DESTINATIONFOLDER]}"

   elif [ ! -d "$LOCAL_FOLDER_SOURCE/${LOCAL_ENTRYARRAY_SOURCEFOLDER[LOCAL_COUNTER_SOURCEFOLDER]}" ] && [ ! -d "$LOCAL_FOLDER_DESTINATION/${LOCAL_ENTRYARRAY_DESTINATIONFOLDER[LOCAL_COUNTER_DESTINATIONFOLDER]}" ]
   then
    LOCAL_BOOLEAN_EQUAL=true

    LOCAL_STAT_SOURCE=$(/usr/bin/stat -c "%a%u%g%s%Y" "$LOCAL_FOLDER_SOURCE/${LOCAL_ENTRYARRAY_SOURCEFOLDER[LOCAL_COUNTER_SOURCEFOLDER]}")
    LOCAL_STAT_DESTINATION=$(/usr/bin/stat -c "%a%u%g%s%Y" "$LOCAL_FOLDER_DESTINATION/${LOCAL_ENTRYARRAY_DESTINATIONFOLDER[LOCAL_COUNTER_DESTINATIONFOLDER]}")

    if [ "$LOCAL_STAT_SOURCE" != "$LOCAL_STAT_DESTINATION" ]
    then
     LOCAL_BOOLEAN_EQUAL=false
    fi

    if [ "$LOCAL_BOOLEAN_EQUAL" = true ]
    then
     LOCAL_CTIME_SOURCE=$(/usr/bin/stat -c "%Z" "$LOCAL_FOLDER_SOURCE/${LOCAL_ENTRYARRAY_SOURCEFOLDER[LOCAL_COUNTER_SOURCEFOLDER]}")
     LOCAL_CTIME_DESTINATION=$(/usr/bin/getfattr --absolute-names --only-values -n "user.kbcom.net:ctime" "$LOCAL_FOLDER_DESTINATION/${LOCAL_ENTRYARRAY_DESTINATIONFOLDER[LOCAL_COUNTER_DESTINATIONFOLDER]}")

     if [ "$LOCAL_CTIME_SOURCE" != "$LOCAL_CTIME_DESTINATION" ]
     then
      LOCAL_BOOLEAN_EQUAL=false
     fi
    fi

    if [ "$LOCAL_BOOLEAN_EQUAL" = true ]
    then
     LOCAL_ACL_SOURCE=$(/usr/bin/getfacl -cp "$LOCAL_FOLDER_SOURCE/${LOCAL_ENTRYARRAY_SOURCEFOLDER[LOCAL_COUNTER_SOURCEFOLDER]}")
     LOCAL_ACL_DESTINATION=$(/usr/bin/getfacl -cp "$LOCAL_FOLDER_DESTINATION/${LOCAL_ENTRYARRAY_DESTINATIONFOLDER[LOCAL_COUNTER_DESTINATIONFOLDER]}")

     if [ "$LOCAL_ACL_SOURCE" != "$LOCAL_ACL_DESTINATION" ]
     then
      LOCAL_BOOLEAN_EQUAL=false
     fi
    fi

    if [ "$LOCAL_BOOLEAN_EQUAL" = false ]
    then
     sync_copy_file "$LOCAL_FOLDER_SOURCE" "${LOCAL_ENTRYARRAY_SOURCEFOLDER[LOCAL_COUNTER_SOURCEFOLDER]}" "$LOCAL_FOLDER_DESTINATION"
    fi

   else
    echo "Nem ugyanaz a típus: ${LOCAL_ENTRYARRAY_SOURCEFOLDER[LOCAL_COUNTER_SOURCEFOLDER]}"
   fi

    ((LOCAL_COUNTER_SOURCEFOLDER++))
    ((LOCAL_COUNTER_DESTINATIONFOLDER++))

   elif [[ "${LOCAL_ENTRYARRAY_SOURCEFOLDER[LOCAL_COUNTER_SOURCEFOLDER]}" < "${LOCAL_ENTRYARRAY_DESTINATIONFOLDER[LOCAL_COUNTER_DESTINATIONFOLDER]}" ]]
   then

   # New file or folder
    if [ -d "$LOCAL_FOLDER_SOURCE/${LOCAL_ENTRYARRAY_SOURCEFOLDER[LOCAL_COUNTER_SOURCEFOLDER]}" ]
    then
     echo "Copy tree \"$LOCAL_FOLDER_SOURCE/${LOCAL_ENTRYARRAY_SOURCEFOLDER[LOCAL_COUNTER_SOURCEFOLDER]}\" \"$LOCAL_FOLDER_DESTINATION/${LOCAL_ENTRYARRAY_SOURCEFOLDER[LOCAL_COUNTER_SOURCEFOLDER]}\""
     /bin/mkdir "$LOCAL_FOLDER_DESTINATION/${LOCAL_ENTRYARRAY_SOURCEFOLDER[LOCAL_COUNTER_SOURCEFOLDER]}"
     sync_copy_folderattribute "$LOCAL_FOLDER_SOURCE/${LOCAL_ENTRYARRAY_SOURCEFOLDER[LOCAL_COUNTER_SOURCEFOLDER]}" "$LOCAL_FOLDER_DESTINATION/${LOCAL_ENTRYARRAY_SOURCEFOLDER[LOCAL_COUNTER_SOURCEFOLDER]}"
     sync_copy_tree "$LOCAL_FOLDER_SOURCE/${LOCAL_ENTRYARRAY_SOURCEFOLDER[LOCAL_COUNTER_SOURCEFOLDER]}" "$LOCAL_FOLDER_DESTINATION/${LOCAL_ENTRYARRAY_SOURCEFOLDER[LOCAL_COUNTER_SOURCEFOLDER]}"
    else
     sync_copy_file "$LOCAL_FOLDER_SOURCE" "${LOCAL_ENTRYARRAY_SOURCEFOLDER[LOCAL_COUNTER_SOURCEFOLDER]}" "$LOCAL_FOLDER_DESTINATION"
    fi

    ((LOCAL_COUNTER_SOURCEFOLDER++))
   else

    # Deleted file or folder
    if [ -d "$LOCAL_FOLDER_DESTINATION/${LOCAL_ENTRYARRAY_DESTINATIONFOLDER[LOCAL_COUNTER_DESTINATIONFOLDER]}" ]
    then
     echo "Könyvtár törlése: ${LOCAL_ENTRYARRAY_DESTINATIONFOLDER[LOCAL_COUNTER_DESTINATIONFOLDER]} ($LOCAL_COUNTER_SOURCEFOLDER, $LOCAL_COUNTER_DESTINATIONFOLDER)"
    else
     echo "Fájl törlése: ${LOCAL_ENTRYARRAY_DESTINATIONFOLDER[LOCAL_COUNTER_DESTINATIONFOLDER]} ($LOCAL_COUNTER_SOURCEFOLDER, $LOCAL_COUNTER_DESTINATIONFOLDER)"
    fi

    ((LOCAL_COUNTER_DESTINATIONFOLDER++))
   fi

  fi
 done
}
