#!/bin/bash
#
# This script is not a Actian-supported product, and is provided as-is, without warranty of any kind.
#

#
# List last SQL
#
usage()
{
       	echo "Usage: ${0}  [-h]"
		cat <<-EOF
                        -h: Help            - Help
		EOF
                exit -1
}

#
# Global ENV Variables
#
if [ -f ./avENV.sh ]
then
        . ./avENV.sh
else
        echo "Missing the 'avENV.sh' program."
        echo "Please run ./avSetup.sh script to setup environment."
        exit -1
fi

#
# Args
#

ingstart >/dev/null 2>&1

if [ $? -eq 1 ]
then
    echo "Avalanche is curently up."
    exit 1
else
echo "Avalanche is up."
fi

