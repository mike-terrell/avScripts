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
       	echo "Usage: ${0} -d database [-h]"
		cat <<-EOF
                        -d: database        - Database name.
                        -h: Help            - Help
		EOF
        exit 1
}

#
# Global ENV Variables
#
# Args
#
export AV_DATABASE=""
    while getopts "d:h" i
    do
     case "$i" in
             d)
                     export AV_DATABASE=${OPTARG}
                     ;;

             *) 
                     usage
                     exit -1
                     ;;
     esac
    done

#
# Check args
#
if [ "${AV_DATABASE}" == "" ]
    then
        echo "${0}: Error, you need to speciify a database."
        usage
        exit -1
fi
if [ -f ./avENV.sh ]
then
        . ./avENV.sh
else
        echo "Missing the 'avENV.sh' program."
        exit -1
fi

echo "Database Size(MB)"
echo "-----------------"
echo "`vwinfo $AV_DATABASE | grep columnspace | awk '{print substr($2,2); }'` * `vwinfo $AV_DATABASE | grep block_size | awk '{print substr($2,2); }'` /1024/1024" | bc
