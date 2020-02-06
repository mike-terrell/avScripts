#!/bin/bash
#
# This script is not a Actian-supported product, and is provided as-is, without warranty of any kind.
#

#
# BAR a database/table
#
usage()
{
		echo "Usage: ${0} {-b|-r| -d database [-c] [-v] [-k number] [-h]"
		cat <<-EOF
			-b: Backup
			-r: Restore
			-d: Database
			-c: Destroys all previous checkpoint files
			-v: Indicates verbose mode, which displays interim messages as checkpointing proceeds
			-i: Initial backup and turn on journalling
			-k: Preserves the specified number of last valid checkpoints and deletes all older checkpoints, valid or invalid
			-h: Help
		EOF
}

#
# Global ENV Variables
#
if [ -f ./avENV.sh ]
then
	. .avENV.sh
else
	echo "Missing the 'avENV.sh' program."
	echo "Please run ./avSetup.sh script to setup environment."
	exit -1
fi

#WSDD: cd %D; /bin/tar czSf %A *
#WSDT: cd %D; /bin/tar czSf %A %B
#WRDD: cd %D; /bin/tar xzf %A
#WRDT: cd %D; /bin/tar xzf %A %B


#
# Initialize Args
#
export AV_DESTROYCP=''
export AV_VERBOSE=''
export AV_INITIAL=0
if [ ${#} -gt 0 ]
then
        args=`getopt brcid:vk: $*`
        set -- $args
        for i
        do
	        case "$i" in
				-r) 
					shift
					export AV_BACKUP=0
					;;
				-b) 
					shift
					export AV_BACKUP=1
					;;
				-d) 
					shift
					export AV_DATABASE=${1}
					shift
					;;
				-c) 
					shift
					export AV_DESTROYCP='-d'
					;;
				-i) 
					shift
					export AV_INITIAL=1
					;;
				-v) 
					shift
					export AV_VERBOSE='-v'
					;;
				-k) 
					shift
					export AV_KEEP=${1}
					shift
					;;
				-h) 
					shift
					usage
					exit -1
					;;
	        esac
        done
else
        usage
        exit -1
fi

#
# Verify Args
#
if [ -z "$AV_BACKUP" ]
then
      echo "Backup or Restore option is required"
      usage
      exit 1
fi
re='^[0-9]+$'
if [[ ! -z $AV_KEEP ]] ; then
   if [[ $AV_KEEP =~ $re ]] ; then
      echo "error: Preserves the specified number of last valid checkpoints is Not a number" >&2
      usage
      exit 1
   fi
fi

#
# Avalanche up?
#
echo show | iinamu | grep INGRES > /dev/null
CMD=$?
if [ ${CMD} -ne 0 ]
then
	echo "Error: Avalanche is not running..."
	exit -1
fi

if [ ${AV_BACKUP} -eq 1 ]
then
	#
	# Database exist?
	#
        infodb ${AV_DATABASE} > /dev/null 2>&1
	CNT=$?
	if [[ ! ${CNT} -eq 0 ]]
	then
		echo "Error: The database ${AV_DATABASE} doesn't exist."
		usage
		exit -1
	fi
fi


#
# Process the checkpoint
#
if [ ${AV_BACKUP} -eq 1 ]
then
	#
	# Backup
	#
	if [ ${AV_INITIAL} -eq 1 ]
	then
		ckpdb +j -d ${AV_VERBOSE} ${AV_DATABASE}
        elif [ ${AV_KEEP} -ge 0 ]
        then
                ckpdb ${AV_VERBOSE} -keep=${AV_KEEP} ${AV_DATABASE}
        else
                ckpdb ${DESTROYCP} ${AV_VERBOSE} ${AV_DATABASE}
	fi
else
	#
	# Restore
	#
        rollforwarddb ${AV_VERBOSE} ${AV_DATABASE}
fi

#
# Exit
#
exit

