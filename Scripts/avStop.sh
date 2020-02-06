#!/bin/bash
# Copyright 2017 Actian Corporation

#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at

#      http://www.apache.org/licenses/LICENSE-2.0

#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

usage()
{
       	echo "Usage: ${0}  [-f] [-h]"
		cat <<-EOF
                        -f: Force shutdown.
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

    export CMD="ingstop"
    while getopts "f h" i
    do
     case "$i" in
             f) 
                     export CMD="ingstop -force"
                     ;;
             *) 
                     usage
                     exit -1
                     ;;
     esac
    done
$CMD 

if [ $? -eq 1 ]
then
    echo "Avalanche is in use. Pleas use -f to force shutdown."
    exit 1
else
echo "Avalanche is stopped."
fi
