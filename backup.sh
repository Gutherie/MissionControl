#!/bin/bash

 ######################################################
###  Backup Plone production sites, send to off-site ##
###  system and delete                               ##
#####################################################

## these variables must be edited to reflect the target systems
EMAIL="youremail@here.com"
EMAILSUB="some kinda backup!"
BASE_DIR=/srv/plone-service/plone4-prod/var
TMP_DIR=/tmp/BACKUP
DATA=/data
FILE=/filestorage
BLOB=/blobstorage
STATUS="Backup was not completed for "
SITES=(main bayswatermd hchlink mat_centre oscarResource tapestry chap iampreg mfp oscarResource-plone trihpp dfmh iam_x my_blood_pressure oscartools ebm-chews inch oscarcanada qcanz fht it oscarmanual quality fmah macfm oscar-resource sfhc)
DELAY=30
LOCALDIR=/your/dir/for/backupfiles
DATE=`date +%Y-%m-%d`
STATUSFILE=${LOCALDIR}/"status.tmp"

cat /dev/null > ${STATUSFILE}

# arg1 : tmpdir
# arg2 : datadir
# arg3 : blobdir
# arg4 : appname
# arg5 : servername
# arg6 : date prefix
 
function process {
	DFILE="${6}_Data.fs-$4.tar.gz"
	DFILEMD5="${6}_Data.fs-$4.md5"
	BFILE="${6}_blobstorage-$4.tar.gz"
	BFILEMD5="${6}_blobstorage-$4.md5"


	echo "Archiving data file for $4" | tee -a ${STATUSFILE}
        ssh $5 "tar -pcvzf ${1}/${DFILE} -C $2 ./Data.fs"
	sleep ${DELAY}
	ssh $5 "md5sum ${1}/${DFILE} $2/Data.fs" > ${6}_Data.fs-$4.md5
	sleep ${DELAY} 
        echo "Archiving blobstorage for $2" | tee -a ${STATUSFILE}
        ssh $5 "tar -pcvzf $TMP_DIR/${BFILE} -C $3 ."
	sleep ${DELAY}
	ssh $5 "md5sum $TMP_DIR/${BFILE}" > ${6}_blobstorage-$4.md5
	sleep ${DELAY}
        echo "send data to backup server"  | tee -a ${STATUSFILE}
        scp $5:$1/${DFILE} ${LOCALDIR}
	sleep ${DELAY}
	scp $5:$1/${DFILEMD5} ${LOCALDIR}
	sleep ${DELAY}

	# get hash values local and remote data files then compare
	md5L=$(md5sum ${DFILE}| cut -f 1 -d ' ')
	md5R=$(head -n 1 ${DFILEMD5} | cut -f 1 -d ' ')
	if [ $md5L == $md5R ]
	then
		echo "Hash match for ${DFILE}" | tee -a ${STATUSFILE}
	else
		echo "Hash FAILED for ${DFILE}" | tee -a ${STATUSFILE}
	fi
	sleep ${DELAY}
        ssh $5 "rm $TMP_DIR/${DFILE}"
	sleep ${DELAY}
        echo "send blobs to backup" | tee ${STATUSFILE}
        scp $5:$1/${BFILE} ${LOCALDIR}
	sleep ${DELAY}
	scp $5:$1/${BFILEMD5} ${LOCALDIR}

	# get the hash values for local and remote then compare
	md5L=$(md5sum ${BFILE} | cut -f 1 -d ' ')
	md5R=$(head -n 1 ${BFILEMD5} | cut -f 1 -d ' ')
	 
	if [ $md5L == $md5R ]
	then
               echo "Hash match for ${BFILE}" | tee -a ${STATUSFILE}
        else
               echo "Hash FAILED for ${BFILE}" | tee -a ${STATUSFILE}
        fi
		
	sleep ${DELAY}
        ssh $5 "rm $TMP_DIR/${BFILE}"
	sleep ${DELAY}
        STATUS="Backup was completed for "$4 | tee ${STATUSFILE}
}

# main program will look at arguments and execute accordingly

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
                                        process ${TMP_DIR} ${BASE_DIR}${FILE} ${BASE_DIR}${BLOB} ${server} $1 ${DATE}
                                else
                                        process ${TMP_DIR} ${BASE_DIR}${DATA}/${server}${FILE} ${BASE_DIR}${DATA}/${server}${BLOB} ${server} $1 ${DATE}
                                fi
				sleep ${DELAY} 
			done	
			
		else 
			if [ $# -eq 2 ]
			then
				echo "Processing a single site ($2), enter any key to continue (ctrl-c to cancel)"
				read
				if [ $2 == ${SITES[0]} ]
				then
					process ${TMP_DIR} ${BASE_DIR}${FILE} ${BASE_DIR}${BLOB} $2 $1 ${DATE}
				else
					process ${TMP_DIR} ${BASE_DIR}${DATA}/$2${FILE} ${BASE_DIR}${DATA}/$2${BLOB} $2 $1 ${DATE}
				fi
			else
				echo "Error with your selection, only two arguements allowed"
			fi
		fi
	fi
	cat ${STATUSFILE} | /usr/bin/mailx -s ${EMAILSUB} $EMAIL
else
	echo "You must enter on argument: ? for help"
fi

echo "Processing complete! Have a nice day"
exit 0
