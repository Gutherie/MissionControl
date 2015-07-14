#!/bin/bash

 ######################################################
###  Backup Plone production sites, send to off-site ##
###  system and delete                               ##
#####################################################

EMAIL="youremail@here.com"
BASE_DIR=/srv/plone-service/plone4-prod/var
TMP_DIR=/tmp/BACKUP
DATA=/data
FILE=/filestorage
BLOB=/blobstorage
STATUS="Backup was not completed for "
SITES=(main bayswatermd hchlink mat_centre oscarResource tapestry chap iampreg mfp oscarResource-plone trihpp dfmh iam_x my_blood_pressure oscartools ebm-chews inch oscarcanada qcanz fht it oscarmanual quality fmah macfm oscar-resource sfhc)

# arg1 : tmpdir
# arg2 : datadir
# arg3 : blobdir
# arg4 : appname
# arg5 : servername
 
function process {
	echo "Archiving data file for $4"
        ssh $5 "tar -pcvzf ${1}/Data.fs-$4.tar.gz $2/Data.fs"
	sleep 5
        echo "Archiving blobstorage for $2"
        ssh $5 "tar -pcvzf $TMP_DIR/blobstorage-$4.tar.gz $3"
	sleep 5
        echo "send data to backup server" 
        scp $5:$1/Data.fs-$4.tar.gz ./
	sleep 5
        ssh $5 "rm $TMP_DIR/Data.fs-$4.tar.gz"
	sleep 5
        echo "send blobs to backup"
        scp $5:$1/blobstorage-$4.tar.gz ./
	sleep 5
        ssh $5 "rm $TMP_DIR/blobstorage-$4.tar.gz"
	sleep 5
        STATUS="Backup was completed for "$4
}

if [ $# -gt 0 ]
then
	if [ $1 == "?" ]
	then
		echo "Available arguments (site to backup) are servername and site (one of the following):"
		for server in ${SITES[*]}
		do
			echo $server
		done
		echo "  ... or ? for help"
	else 
		if [ $# -eq 1 ]
		then
			echo "Processing all sites, enter any key to continue (ctrl-C to cancel)"
			read

			for server in ${SITES[*]}
			do
				echo "Processing a single site (${server}), enter any key to continue (ctrl-c to cancel)"
                                if [ ${server} == ${SITES[0]} ]
                                then
                                        process ${TMP_DIR} ${BASE_DIR}${FILE} ${BASE_DIR}${BLOB} ${server} $1
                                else
                                        process ${TMP_DIR} ${BASE_DIR}${DATA}/${server}${FILE} ${BASE_DIR}${DATA}/${server}${BLOB} ${server} $1
                                fi
			done	
			
		else 
			if [ $# -eq 2 ]
			then
				echo "Processing a single site ($2), enter any key to continue (ctrl-c to cancel)"
				read
				if [ $2 == ${SITES[0]} ]
				then
					process ${TMP_DIR} ${BASE_DIR}${FILE} ${BASE_DIR}${BLOB} $2 $1
				else
					process ${TMP_DIR} ${BASE_DIR}${DATA}/$2${FILE} ${BASE_DIR}${DATA}/$2${BLOB} $2 $1
				fi
			else
				echo "Error with your selection, only two arguements allowed"
			fi
		fi
	fi
	# echo ${STATUS} | /usr/bin/mailx -s "zope1 backup" $EMAIL
else
	echo "You must enter on argument: ? for help"
fi

echo "Processing complete! Have a nice day"
exit 0
