#!/bin/bash

COMMANDS=(
		"keybase service"
		"kbfsfuse"
	)

COMMANDS_SZ=${#COMMANDS[@]}

BACKUP_FOLDERS=(
		"/opt/scripts"
		"/home/johan/install.txt"
		)

USERNAME="payano"
KBFSPATH="${XDG_RUNTIME_DIR}/keybase/kbfs/private/$USERNAME/backup"

close_processes()
{
	echo "close"
	for (( i = ${COMMANDS_SZ}; i > 0 ; i-- ))
	do
		kill %$i
	done

}

start_processes()
{
	echo "start"
	for i in "${COMMANDS[@]}"
	do 
		$i >> /dev/null 2>&1 &
		sleep 1
	done
	sleep 10
	# test if kbfs works
	if [ ! -d $KBFSPATH ]
	then
		close_processes
		return 1
	fi
	return 0


}

compress_and_store_backup(){
	echo ${BACKUP_FOLDERS[@]}
	echo "hej"
}

clean_backups()
{
	echo "hej"
}

send_message()
{
	keybase chat send payano "auto"
	echo "hej"
}

check_processes()
{
	sleep 10
	jobs
	PROCESSES=$(jobs)
	if [ ! -z "$PROCESSES" ]
	then
		return 1
	fi
	return 0
}

# main
start_processes
if [ $? -ne 0 ]
then
	echo "Could not access kbfs directory..."
	exit 1
fi

compress_and_store_backup
clean_backups
send_message
sleep 10

close_processes
check_processes
if [ $? -ne 0 ]
then
	echo "COULD NOT STOP ALL PROCESSES!"
	exit 1
fi

exit 0
