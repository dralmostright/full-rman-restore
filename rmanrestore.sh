#/bin/bash

###
### GLOBAL VARIABLES
###

##
## Some oracle mandetory env's
##
ORACLE_HOME="/u01/app/oracle/product/11.2.0/db_home1"
ORACLE_SID="testorcl"
ORACLE_UNQNAME=""
ORACLE_HOST=""
ORACLE_OWNER=""

##
## Current user executing the script
##
RESTORE_USER=`whoami`

##
## Env for pointing the backup base location
##
BACKUP_DIR=""

##
## Env for locating full path of the script being executed
##
#CURSCRIPT=`realpath $0`
CURSCRIPT=`readlink -f $0`

##
##
##
ORACLE_VERSION=""
ORASPFILE_PATH=""
ORACONTROLBKP_PATH=""
ORACLE_DBID="506461997"

##
## Variables for holding database physical files
##
DBDATAFILES=""
DBLOGFILES=""
DBTEMPFILES=""

##
## Variables for generating logfiles 
##
DATE_AND_TIME=`date +%d_%m_%Y`
LOG_FILE_NAME=`dirname ${CURSCRIPT}`/Sessionrestore_${DATE_AND_TIME}.log

##
## Variables holding O/S physical directories
##
ORADATADIRS=""
ORALOGDIRS=""
ORATEMPDIRS=""
ORADATADIRSMAP=""
ORALOGDIRSMAP=""
ORATEMPDIRSMAP=""

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
       echo -e "INFO : $1 "
       echo "########################################################"
}

###
### Print contents in an array
###
printArray(){
temparr=("$@")
for i in "${temparr[@]}"
	do :
	echo ${bold}${underline}$i${reset} 
	done
}


###
### If file exixts remove the file
###
ClearFile(){
        if [ -f ${1} ]
        then
		> ${1}
        fi
}


###
### Count occurance of error words in a file and stop execution if threshold is reached..
###

VerifyError(){
errorCount=`cat ${1}|grep  ${2}|grep -v grep|wc -l`
if test $errorCount -gt ${3}
then
	ShutdownDB $ORACLE_HOME "A"
        ReportError  "RERR-${4}" "Some error occured. ${5} \nPlease review "${bell}${bold}${underline}${LOG_FILE_NAME}${reset}" for more info. Aborting...."
else
	ReportInfo "${6}"
fi
}


###
### Verify if directory/file exists
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
### Verify if only directory exixts
###

VerifyDirectoryOnly(){
#fullpath=`dirname ${1}`
        if [ ! -d ${1} ]
        then
                ReportError "RERR-002" "Directory \"${bell}${bold}${underline}${1}${reset}\" not found or invalid. Aborting...."

        else
                ReportInfo "Checking Directory status..... passed."
        fi

}


###
### Create linked arrays with respective dirs
###
MapDirArray(){
	tempvar=""
	if [ "${1}" = "D" ]
	then
		ReportInfo "Mapping Directories for Datafiles......"
		for i in "${ORADATADIRS[@]}"
        		do :
        		printf "Echo the map dir for ${bold}${underline}$i${reset} : "
			read -r tempvar
			VerifyDirectoryOnly $tempvar
			#
			# replace the occurance of user input with matching string
			#
			DBDATAFILES=`echo $DBDATAFILES | sed -e "s|$i|$tempvar|g"`
        		done
		#echo $DBDATAFILES

	elif [ "${1}" = "L" ]
	then
		ReportInfo "Mapping Directories for Logfiles......"
                for i in "${ORALOGDIRS[@]}"
                        do :
                        printf "Echo the map dir for ${bold}${underline}$i${reset} : "
                        read -r tempvar
			VerifyDirectoryOnly $tempvar
                        #
                        # replace the occurance of user input with matching string
                        #
			DBLOGFILES=`echo $DBLOGFILES | sed -e "s|$i|$tempvar|g"`
                        done
		#echo $DBLOGFILES
		
	elif [ "${1}" = "T" ]
	then
		ReportInfo "Mapping Directories for Tempfiles......"
                for i in "${ORATEMPDIRS[@]}"
                        do :
                        printf "Echo the map dir for ${bold}${underline}$i${reset} : "
                        read -r tempvar
			VerifyDirectoryOnly $tempvar
                        #
                        # replace the occurance of user input with matching string
                        #
			DBTEMPFILES=`echo $DBTEMPFILES | sed -e "s|$i|$tempvar|g"`
                        done
		#echo $DBTEMPFILES

	else
		ReportError "RERR-009" "${bell}${bold}${underline}Invalid Mapping Choice${reset}. Aborting...."
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
### Remap values in arrray
###
RemapValuesArray(){
echo "hello"

}

###
### Start the database
###
StartDB(){
case ${2} in
    n|N )
        $1/bin/sqlplus -s /nolog <<EOF
        set pagesize 0 feedback off verify off echo off;
        connect / as sysdba
        startup nomount;
EOF
        ;;

        m|M )
        $1/bin/sqlplus -s /nolog <<EOF
        set pagesize 0 feedback off verify off echo off;
        connect / as sysdba
        startup mount;
EOF
        ;;

	o|O )
        $1/bin/sqlplus -s /nolog <<EOF
        set pagesize 0 feedback off verify off echo off;
        connect / as sysdba
        startup;
EOF
        ;;

    * )
        ReportInfo "Startup of instance skipped......."
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

        elif [ "${3}" = "" ]
        then
                ReportError  "RERR-007" ${bell}${bold}${underline}"ORACLE_SID"${reset}" not set or is empty. Aborting..."

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
	ClearFile $LOG_FILE_NAME
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
### Set new value for controlfile
###
SetNewLocControl(){
$1/bin/sqlplus -s /nolog <<EOF
        set pagesize 0 feedback off verify off echo off;
        connect / as sysdba
	alter system set control_files='${2}/control_${ORACLE_SID}_01.ctl', '${2}/control_${ORACLE_SID}_02.ctl' scope=spfile;
EOF
ReportInfo "Controlfile location changed to ${2}\nTwo New controlfiles which will be restored are:\n${bold}${2}/control_${ORACLE_SID}_01.ctl${reset}, \n${bold}${2}/control_${ORACLE_SID}_02.ctl${reset}"

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
	VerifyDirectoryOnly $controldir	
        ReportInfo "Shutting down instance......."
	ShutdownDB ${ORACLE_HOME} "A"
	ReportInfo "Starting database instance in nomount mode......."
	StartDB ${ORACLE_HOME} "N"
	SetNewLocControl ${ORACLE_HOME} ${controldir}
	ReportInfo "Shutting down instance......."
	ShutdownDB ${ORACLE_HOME} "A"
	ReportInfo "Starting database instance in nomount mode......."
        StartDB ${ORACLE_HOME} "N"
	ReportInfo "Changing controlfile location completed successfully ......."
	;;

    * )
        ReportInfo "Changing controlfile location skipped ......."
    ;;  
esac

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
	
	ChanageControlfileDir
        printf 'Please provide Full path for control backup location : '
        read -r ORACONTROLBKP_PATH
        ClearFile $LOG_FILE_NAME
        VerifyDirectory $ORACONTROLBKP_PATH
	
        $ORACLE_HOME/bin/rman target / nocatalog log = $LOG_FILE_NAME append <<EOF
        run
        {
        set DBID=${ORACLE_DBID}
        restore controlfile from '${ORACONTROLBKP_PATH}';     
        }
EOF

	echo ""
	VerifyError $LOG_FILE_NAME "RMAN-" 1 "008" "Restore of Controlfiles Failed." "Restore of Controlfiles Successed."
	ReportInfo "Shutting down instance......."
        ShutdownDB ${ORACLE_HOME} "A"
        ReportInfo "Opening Database on mount mode......."
	StartDB ${ORACLE_HOME} "M"
	ReportInfo "Opening Database on mount mode completed successfully......."
        ;;

    * )
        ReportInfo "Restoring of controlfiles skipped......."
    ;;
esac


}


###
### Generate setnew name scripts.
###
GenerateSetNewName(){

#
# Get the details of original datafiles
#
DBDATAFILES=$($1/bin/sqlplus -s /nolog <<END
set pagesize 0 feedback off verify off echo off;
connect / as sysdba
select name from v\$datafile;
END
)

#
# Get the details of the original logfiles
#
DBLOGFILES=$($1/bin/sqlplus -s /nolog <<END
set pagesize 0 feedback off verify off echo off;
connect / as sysdba
select member from v\$logfile;
END
)

#
# Get the details of the original tempfiles
#
DBTEMPFILES=$($1/bin/sqlplus -s /nolog <<END
set pagesize 0 feedback off verify off echo off;
connect / as sysdba
select name from v\$tempfile;
END
)

#
# Extract only unique directories from datafiles, logfiles and tempfiles
# 
ORADATADIRS=(`echo -e "$DBDATAFILES" | sed -e 's/\/[^\/]*$//'|uniq`)
#ORADATADIRS=(`echo "$DBDATAFILES" | sed -e 's/\/[^\/]*$//'`)
ORALOGDIRS=(`echo "$DBLOGFILES" | sed -e 's/\/[^\/]*$//'|uniq`)
#ORALOGDIRS=(`echo "$DBLOGFILES" | sed -e 's/\/[^\/]*$//'`)
ORATEMPDIRS=(`echo "$DBTEMPFILES" | sed -e 's/\/[^\/]*$//'|uniq`)
#ORATEMPDIRS=(`echo "$DBTEMPFILES" | sed -e 's/\/[^\/]*$//'`)
ReportInfo "Original Unique Directories found for datafiles......."
printArray "${ORADATADIRS[@]}"
sleep 1;
echo ""
ReportInfo "Original Unique Directories found for logfiles......."
printArray "${ORALOGDIRS[@]}"
sleep 1;
echo ""
ReportInfo "Original Unique Directories found for tempfiles......."
printArray "${ORATEMPDIRS[@]}"
MapDirArray "D"
MapDirArray "L"
MapDirArray "T"
}

###
### Restore the datafiles...
###
RestoreDatafile(){
ReportInfo "Restoring Datafiles........"
echo "Do you want to change the location of datafiles...."
echo "Y - For changing by script during restore"
echo "N - For skipping datafile location change during restore..............."
printf "Select your choice : "
read -r DATAFILE_LOC

case ${DATAFILE_LOC} in
    y|Y )
        ReportInfo "Generating Scripts for datafile location change......."
        #printf "Please provide the absolute directory path : "
        #read -r DATAFILEDIR
        #VerifyDirectoryOnly $DATAFILEDIR
	GenerateSetNewName $ORACLE_HOME
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
CheckVars $ORACLE_HOME $RESTORE_USER $ORACLE_SID

###
### Report user whats going on..
###
ReportInfo "Checking Fundamental Variables..... passed."
echo "";
sleep 1;

###
### Restore pfile / Spfile
###

RestoreSpfile

###
### Restore Controlfiles
###
RestoreControlfile

###
### Restore datafiles
###
RestoreDatafile
