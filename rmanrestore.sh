#/bin/bash

###
### GLOBAL VARIABLES
###

ORACLE_HOME="/u01/app/oracle/product/11.2.0/dbhome_1"
ORACLE_SID="testogg"
ORACLE_UNQNAME=""
ORACLE_HOST=""
ORACLE_OWNER=""
RESTORE_USER=`whoami`
BACKUP_DIR=""
CURSCRIPT=`realpath $0`
ORACLE_VERSION=""
ORASPFILE_PATH=""
ORACLE_DBID="506461997"
DATE_AND_TIME=`date +%d_%m_%Y`
LOG_FILE_NAME=`dirname ${CURSCRIPT}`/Sessionrestore_${DATE_AND_TIME}.log



##
## For Warning and Text manupulation
##
bold=$(tput bold)
reset=$(tput sgr0)
bell=$(tput bel)
underline=$(tput smul)

###
### Handling error while running script
###
### $1 : Error Code
### $2 : Error message in detail
###

ReportError(){
       echo "########################################################"
       echo "Error during Running Script : $CURSCRIPT"
       echo -e "$1: $2"
       echo "########################################################"
       exit 1;
}

###
### Dispalying information based on input of user 
### OR
### Status of script while running.
###

ReportInfo(){
       echo "########################################################"
       echo "Information by the script : $CURSCRIPT"
       echo "INFO : $1 "
       echo "########################################################"
}


###
### Count occurance of error words in a file and stop execution if threshold is reached..
###

VerifyError(){
errorCount=`cat ${1}|grep -i ${2}|wc -l`
if test $errorCount -gt ${3}
then
        ReportError  "RERR-${4}" "Some error occured. ${5} \nPlease review "${bell}${bold}${underline}${LOG_FILE_NAME}${reset}" for more info. Aborting...."
else
	ReportInfo "${6}"
fi
}


###
### Verify if directory exists
###

VerifyDirectory(){
	fullpath=`dirname ${1}`
        if [ ! -d ${fullpath} ]
        then
                ReportError "RERR-002" "Directory \"${bell}${bold}${underline}${fullpath}${reset}\" not found or invalid. Aborting...."
	
	elif [ ! -f ${1} ]
	then
		ReportError "RERR-005" "File \"${bell}${bold}${underline}${1}${reset}\" not found or invalid. Aborting...."
	
	else
		ReportInfo "Checking Directory and file status..... passed."
	fi
}


###
### Shutdown database instance
###

ShutdownDB(){
case ${2} in
    I|i )
        $1/bin/sqlplus -s /nolog <<EOF
        set pagesize 0 feedback off verify off echo off;
        connect / as sysdba
        shutdown immediate;
EOF
        ;;

        A|a )
        $1/bin/sqlplus -s /nolog <<EOF
        set pagesize 0 feedback off verify off echo off;
        connect / as sysdba
        shutdown abort;
EOF
        ;;

    * )
        ReportInfo "Shutdown of instance skipped......."
    ;;
esac

}

###
### FUNCTION TO CHECK FUNDAMENTAL VARIABLES
###

CheckVars(){
	if [ "${1}" = "" ]
	then
		ReportError "RERR-001" "${bell}${bold}${underline}ORACLE_HOME${reset} Environmental variable not Set. Aborting...."
		
	elif [ ! -d ${1} ]
	then
		ReportError "RERR-002" "Directory \"${bell}${bold}${underline}${1}${reset}\" not found or ORACLE_HOME Env invalid. Aborting...."
	
	elif [ ! -x ${1}/bin/rman ]
	then
		ReportError  "RERR-003" "Executable \"${bell}${bold}${underline}${1}/bin/rman${reset}\" not found; Aborting..."
       
	elif [ "${2}" != "oracle" ]
        then
                ReportError  "RERR-004" "User "${bell}${bold}${underline}${2}${reset}" not valid for running script; Aborting..."
	
	else
		return 0;
	fi
}

###
### Function to restore spfile
###
RestoreSpfile(){

echo "Spfile restore option...."
echo "Y - For restroing spfile from backup by script"
echo "N - For skipping spfile restore..............."
printf "Select your choice : "

read -r spfilechoice

case ${spfilechoice} in
    y|Y )
    ReportInfo "Restoring spfile from backupset......."
	
	printf 'Please provide Full path for spfile backup location : '
	read -r ORASPFILE_PATH
	VerifyDirectory $ORASPFILE_PATH

        #$ORACLE_HOME/bin/rman target / nocatalog log = $LOG_FILE_NAME append << EOF
        $ORACLE_HOME/bin/rman target / nocatalog log=$LOG_FILE_NAME append << EOF
        run
        {
        startup nomount force;
        set DBID=${ORACLE_DBID}
        restore spfile from '${ORASPFILE_PATH}';     
        }
EOF

echo ""
VerifyError $LOG_FILE_NAME "RMAN-" 1 "006" "Restore of Spfile Failed." "Restore of Spfile Successed."
	;;

    * )
        ReportInfo "Restoring spfile skipped......."
    ;;
esac
echo ""

}

###
### Function to restore controlfiles
###
RestoreControlfile(){

echo "Controlfile restore option...."
echo "Y - For restroing controlfile from backup by script"
echo "N - For skipping spfile restore..............."
printf "Select your choice : "

read -r controlchoice

case ${controlchoice} in
    y|Y )
    ReportInfo "Restoring controlfile from backupset......."

	#
	# Clearing logfile....
	#
	> $LOG_FILE_NAME
        
	#$ORACLE_HOME/bin/rman target / nocatalog log = $LOG_FILE_NAME append << EOF
        $ORACLE_HOME/bin/rman target / nocatalog log = $LOG_FILE_NAME append <<EOF
        run
        {
        startup nomount force;
        set DBID=${ORACLE_DBID}
        restore controlfile from '${1}';     
        }
EOF
        ;;

    * )
        ReportInfo "Restoring spfile skipped......."
    ;;
esac


}

###
### Change Controlfile directory
###
ChanageControlfileDir(){

echo "Control file directory change...."
echo "Y - For changing controlfile location before restore by script"
echo "N - For skipping location change..............."
echo "If you choose Y all controlfiles are mappled to only one location specified by user.."
printf "Select your choice : "

read -r controldirchoice

case ${controldirchoice} in
    y|Y )
	ReportInfo "Changing controlfile location......."
	printf "Please provide the absolute directory path : "
	read -r controldir
	VerifyDirectory $controldir	
        ;;

    * )
        ReportInfo "Changing controlfile location skipped ......."
    ;;  
esac

}

###
### Clear the weeds in screen..
###
clear;

###
### Report user whats going on..
###
ReportInfo "Checking Fundamental Variables....."
echo "";

###
### Pause the execution of script for one sec..
###
sleep 1;

###
### Check fundamental vars..
###
CheckVars $ORACLE_HOME $RESTORE_USER

###
### Report user whats going on..
###
ReportInfo "Checking Fundamental Variables..... passed."
echo "";
sleep 1;

###
### Restore pfile / Spfile
###

#printf 'Please provide Full path for spfile backup location : '
#read -r ORASPFILE_PATH

#VerifyDirectory $ORASPFILE_PATH

RestoreSpfile

ChanageControlfileDir
