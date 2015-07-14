#!/bin/bash

 ######################################################
###  Backup Plone production sites, send to off-site ##
###  system and delete                               ##
#####################################################


#BK_SRV=zope2.fammedmcmaster.ca
BASE_DIR=/srv/Plone/plone-main/zinstance/var
TMP_DIR=/tmp/BACKUP
DATA=/data
FILE=/filestorage
BLOB=/blobstorage
STATUS="Backup was not completed for "
SITES=(main bayswatermd hchlink mat_centre oscarResource tapestry chap iampreg mfp oscarResource-plone trihpp dfmh iam_x my_blood_pressure oscartools ebm-chews inch oscarcanada qcanz fht it oscarmanual quality fmah macfm oscar-resource sfhc)


if [ $# -gt 0 ]
then
	if [ $1 == "?" ]
	then
		echo "Available arguments (site to backup) are :"
		for server in ${SITES[*]}
		do
			echo $server
		done
		echo "  ... or ? for help"
	else
		# special case for main, others are located in data
		if [ $1 == ${SITES[0]} ]
		then
			echo "Archiving data file for $1"
			cd ${BASE_DIR}${FILE}
			tar -pcvzf $TMP_DIR/Data.fs-$1.tar.gz Data.fs

			echo "Archiving blobstorage for $1"
			cd ${BASE_DIR}
			tar -pcvzf $TMP_DIR/blobstorage-$1.tar.gz .${BLOB}

 			# send data to backup 
 			#scp $TMP_DIR/Data.fs-$1.tar.gz ${BK_SRV}:/srv/BACKUP
                        #rm $TMP_DIR/Data.fs-$1.tar.gz

			# send blobs to backup
                        #scp $TMP_DIR/blobstorage-$1.tar.gz ${BK_SRV}:/srv/BACKUP
                        #rm $TMP_DIR/blobstorage-$1.tar.gz
			STATUS="Backup was completed for "$1
		else
			for server in ${SITES[*]}
			do
				if [ $server == $1 ]
				then
		                        echo "Archiving data file for $1"
		                        cd ${BASE_DIR}${DATA}/$1${FILE}
		                        tar -pcvzf $TMP_DIR/Data.fs-$1.tar.gz Data.fs

					echo "Archiving blobstorage for $1"
			                cd ${BASE_DIR}${DATA}/$1
			                tar -pcvzf $TMP_DIR/blobstorage-$1.tar.gz .${BLOB}

					# send data to backup
                                        scp $TMP_DIR/Data.fs-$1.tar.gz ${BK_SRV}:/srv/BACKUP
	                                rm $TMP_DIR/Data.fs-$1.tar.gz

					# send blobs to backup
					scp $TMP_DIR/blobstorage-$1.tar.gz ${BK_SRV}:/srv/BACKUP
					rm $TMP_DIR/blobstorage-$1.tar.gz
					
					STATUS="Backup was completed for "$1
				fi
			done
		fi
	fi
	echo ${STATUS} | /usr/bin/mailx -s "zope1 backup" jasonbaker@ieee.org
else
	echo "You must enter on argument: ? for help"
fi
