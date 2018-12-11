#/bin/bash

###
### GLOBAL VARIABLES
###

ORACLE_HOME="/u01/app/oracle/product/11.2.0/dbhome_1"
ORACLE_SID=""
ORACLE_UNQNAME=""
ORACLE_HOST=""
ORACLE_OWNER=""
RESTORE_USER=`whoami`
BACKUP_DIR=""
CURSCRIPT=`realpath $0`
ORACLE_VERSION=""
ORASPFILE_PATH=""

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
       echo "$1: $2"
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
### Verify if directory exists
###

VerifyDirectory(){
        if [ ! -d ${1} ]
        then
		ReportInfo "Verifying file and directory $1"
                ReportError "RERR-002" "Directory \"${bell}${bold}${underline}${1}${reset}\" not found or invalid. Aborting...."
	fi
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

printf 'Please provide Full path for spfile backup location : '
read -r ORASPFILE_PATH

VerifyDirectory $ORASPFILE_PATH
