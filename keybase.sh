#!/bin/bash

BACKUP_SIZE=0 # dont change this
BACKUP_FILE_NAME=""

COMMANDS=(
		"keybase service"
		"kbfsfuse"
	)

COMMANDS_SZ=${#COMMANDS[@]}

BACKUP_FOLDERS=(
		"/opt/scripts"
		"/data/nextcloud/johan"
		"/data/nextcloud/anna"
		)

USERNAME="payano"
BACKUPPATH="${XDG_RUNTIME_DIR}/keybase/kbfs/private/$USERNAME/backup"
BACKUP_MAX_DAYS="10" # if one each day, keep 10 backups

get_time()
{
	RET=$(date +%Y-%m-%d_%H:%M)
	echo "$RET"
}

send_message()
{
	MSG="$1"
	keybase chat send $USERNAME "$(get_time): $MSG"
}

close_processes()
{
	ALREADY_STARTED=$1
	if [ $ALREADY_STARTED -eq 1 ]
	then
		return 0
	fi
	for (( i = ${COMMANDS_SZ} - 1 ; i >= 0 ; i-- ))
	do
		PROCESS=${COMMANDS[$i]}
		P_ID=$(pgrep -f "$PROCESS")
		kill $P_ID
	done
}

start_processes()
{
	#check if already started
	for i in "${COMMANDS[@]}"
	do 
		I_PID=$(pgrep -f "$i")
		if [ ! -z "$I_PID" ]
		then
			return 1
		fi
	done

	#start
	for i in "${COMMANDS[@]}"
	do 
		$i >> /dev/null 2>&1 &
		sleep 5
	done
	sleep 5

	# test if kbfs works
	if [ ! -d $BACKUPPATH ]
	then
		send_message "KBFS did not start correctly."
		close_processes
		return 2
	fi
	return 0
}

compress_and_store_backup()
{
	BACKUP_FILE_NAME="$1"
	tar -czf ${BACKUP_FILE_NAME} ${BACKUP_FOLDERS[@]} 
	if [ $? -ne 0 ]
	then
		send_message "$(get_time): Error with the tar command.."
		return 1
	fi
	sync
	sleep 10
	BACKUP_SIZE=$(du -hs $BACKUP_FILE_NAME | awk '{print $1}')
	FILE_NAME=$(basename $BACKUP_FILE_NAME)
	send_message 'BACKUP 
FILE: '"$FILE_NAME"'
SIZE: '"$BACKUP_SIZE'"
}

remove_old_backups()
{
	DAYS_TO_KEEP=$1
	D_PATH=$2
	PATH_SZ=${#D_PATH}
	if [ -z "$D_PATH" ] || [ $PATH_SZ -lt 5 ] || [ $DAYS_TO_KEEP -lt 1 ]
	then
		return 1
	fi
	find $D_PATH -mtime +${DAYS_TO_KEEP} -exec rm -f {} \;
	return $?
}

# main
echo "$(get_time): Backup started."
start_processes
STARTED=$?
if [ $STARTED -eq 2 ]
then
	echo "$(get_time): Could not access kbfs directory..."
	exit 1
fi

echo "$(get_time): Compress and store backup.."
compress_and_store_backup "${BACKUPPATH}/$(get_time).tar.gz"
if [ $? -ne 0 ]
then
	echo "$(get_time): Could not store the backup..."
	send_message "$(get_time): Could not store the backup..."
	exit 1
fi

echo "$(get_time): Remove old backups.."
remove_old_backups $BACKUP_MAX_DAYS $BACKUPPATH
if [ $? -ne 0 ]
then
	echo "$(get_time): Could not remove old backups..."
	send_message "$(get_time): Could not remove old backups..."
	exit 1
fi

close_processes $STARTED
if [ $? -ne 0 ]
then
	echo "$(get_time): could not stop all processes..."
	exit 1
fi

echo "$(get_time): Backup success."
exit 0
