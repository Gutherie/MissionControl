#!/bin/bash

# collect logs from a system, store them on a backup system zero out the system logs

# arg1: servername

EMAIL="youremail@here.com"
EMAILSUB="Log backup"
BASEREMOTE=/srv/plone-service/plone4-prod/var/log
BASELOCAL=/srv/MISSIONCONTROL/LOGS
STATUSFILE=${BASELOCAL}/status.tmp
DELAY=30
DATE=$(date +Y-%m-%d)

if [ $# -eq 1 ]
then
	## create directory
	for file in $(ssh $1 "ls ${BASEREMOTE}")
	do
		sleep ${DELAY}
		echo "Backing up $file" | tee -a ${STATUSFILE}
		ssh $1 "mv ${BASEREMOTE}/$file ${BASEREMOTE}/${DATE}-$file && touch ${BASEREMOTE}/$file"
		sleep ${DELAY}
		scp $1:${BASEREMOTE}/${DATE}-$file ${BASELOCAL}
		sleep ${DELAY}
		ssh $1 "cat /dev/null > ${BASEREMOTE}/${DATE}-${file}"
	done
	cat ${STATUSFILE} | /usr/bin/mailx -s ${EMAILSUB} $EMAIL
else
	echo "You must specify a single parameter that is the target host system name (FQDN)"
fi
exit 0
