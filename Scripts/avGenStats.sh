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

#
# List last SQL
#
usage()
{
       	echo "Usage: ${0} -t table -s [-h]"
		cat <<-EOF
                        -d: database        - Database name.
                        -t: table [-c]|all  - Table name. [list of columns for statistics]
                        -s: sample|nosample value - sample value between 0 and 100 i.e sample=10|nosample for no sampling
                        -c: (column list)  - List of columns to gather statistics for. Note parentheses are required and need to be in double quotes.
                                             i.e. "(column1, column2,....)"
                        -h: Help            - Help
		EOF
                exit -1
}

#
# Global ENV Variables
#

#
# Args
#
export AV_DATABASE=""
export AV_SAMPLE="NOSAMPLE"
export AV_VALUE="0"
export AV_COLUMNS=""
export AV_SELECT=""
export AV_FROM=" FROM iitables"
export AV_WHERE=" where table_name NOT LIKE 'ii%'"
export AV_ORDER="ORDER  BY table_name" 
export AV_GROUPBY=""
    while getopts "d:t:c:s:h" i
    do
     case "$i" in
             d)
                     export AV_DATABASE=${OPTARG}
                     ;;

             t) 
                     export AV_TABLE_NAME="${OPTARG}"

                        
                     ;;
             s)
                     export AV_SAMPLE=${OPTARG}
                     if [ "${AV_SAMPLE}" = "" ]
                        then
                        usage
                     fi

                     ;;
             c)
                     if [ "${AV_TABLE_NAME}" = "ALL TABLES" ]
                        then
                        echo "Columns not allowed for all tables"
                        usage
                     fi
                     export AV_COLUMNS="("${OPTARG}")"
                     if [ "${AV_COLUMNS}" = "" ]
                        then
                        usage
                     fi

                     ;;

             *) 
                     usage
                     exit -1
                     ;;
     esac
    done
if [ "${AV_DATABASE}" == "" ]
    then
        echo "${0}: Error, you need to speciify a database."
        exit -1
fi
#
# Check args
#
if [ -f ./avENV.sh ]
then
        . ./avENV.sh
else
        echo "Missing the 'avENV.sh' program."
        exit -1
fi
if [ "${AV_TABLE_NAME}" = "" ]
    then
        usage
fi
if [ "${AV_TABLE_NAME}" = "all" ]
    then
        export AV_TABLE_NAME="ALL TABLES"
    else
        cnt=$(${AV_SQLCMD} -S @${AV_HOST},${AV_PROTOCOL},${AV_PORT}[${AV_USER},${AV_PASSWORD}]::${AV_DATABASE}<<< "select count(*) from iitables where table_name in ('${AV_TABLE_NAME}') and table_name not like 'ii%';\g")
        if [ "$cnt" -ne "1" ]
            then
                echo "Table name not found"
                usage
        fi
fi
                                
echo "Creating Statistics: " ${AV_TABLE_NAME}
   export AV_SELECT="CREATE STATISTICS FOR  ${AV_TABLE_NAME} ${AV_COLUMNS}  WITH ${AV_SAMPLE}"
echo $AV_SELECT
${AV_SQLCMD} -S @${AV_HOST},${AV_PROTOCOL},${AV_PORT}[${AV_USER},${AV_PASSWORD}]::${AV_DATABASE} <<EOF
    ${AV_SELECT}
     \g
EOF
