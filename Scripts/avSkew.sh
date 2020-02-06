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
       	echo "Usage: ${0} -d database -t table -s [-h]"
		cat <<-EOF
                        -d: database        - Database name.
                        -t: table|all       - Table name.
                        -h: Help            - Help
		EOF
        exit 1
}


#
# Args
#
export AV_DATABASE=""
export AV_SELECT=""
export AV_FROM=" FROM iitables"
export AV_WHERE=" where table_name NOT LIKE 'ii%'"
export AV_ORDER="ORDER  BY table_name" 
export AV_GROUPBY=""
    while getopts "d:t:h" i
    do
     case "$i" in
             d)
                     export AV_DATABASE=${OPTARG}
         #            shift
                     ;;

             t) 
                     export AV_TABLE_NAME="${OPTARG}"
                     #echo  AV_TABLE_NAME="${OPTARG}"

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
fi
if [ "${AV_TABLE_NAME}" == "" ]
    then
        echo "${0}: Error, you need to speciify a table."
        usage
fi
                                
if [ "${AV_SELECT}" = "" ]
    then
    export AV_SELECT="SELECT table_name "
fi

#
# Global ENV Variables
#
if [ -f ./avENV.sh ]
then
        . ./avENV.sh
else
        echo "Missing the 'avENV.sh' program."
        exit -1
fi
export HEADER1="Table                                 "
export HEADER2="------------------------------------------"
tbls="${AV_TABLE_NAME}"
if [ "${AV_TABLE_NAME}" = "all" ]
    then
    tbls=$(${AV_SQLCMD} -S @${AV_HOST},${AV_PROTOCOL},${AV_PORT}[${AV_USER},${AV_PASSWORD}]::${AV_DATABASE}<<< "select table_name from iitables where table_name not like 'ii%' and table_owner = '${AV_USER}';\g")
    else
    cnt=$(${AV_SQLCMD} -S @${AV_HOST},${AV_PROTOCOL},${AV_PORT}[${AV_USER},${AV_PASSWORD}]::${AV_DATABASE}<<< "select count(*) from iitables where table_name in ('${AV_TABLE_NAME}') and table_name not like 'ii%' and table_owner = '${AV_USER}';\g")
    if [ "$cnt" -ne "1" ]
        then
        echo "Table name not found"
        usage
    fi
fi
                        
export HEADER1="Partition                  Number of Rows       % of Table"
export HEADER2="----------------------------------------------------------"


for i in $tbls 
do
   rows=$(${AV_SQLCMD} -S @${AV_HOST},${AV_PROTOCOL},${AV_PORT}[${AV_USER},${AV_PASSWORD}]::${AV_DATABASE}<<< "select count(*) from ${i};\g")
   if [ "${rows}" -gt "0" ]
   then
        
echo "Skew for table: " ${i}
printf "%s\n" "$HEADER1"
echo $HEADER2
   export AV_SELECT="SELECT tid/10000000000000000, count(*), cast(cast(count(*) as DECIMAL(15,2))/${rows} AS DECIMAL(15,2))*100  FROM ${i} GROUP BY 1"
cat <<EOF | ${AV_SQLCMD} -S @${AV_HOST},${AV_PROTOCOL},${AV_PORT}[${AV_USER},${AV_PASSWORD}]::${AV_DATABASE} | awk '{printf "%-28s %-20s %-2s\n", $1, $2, $3}' | awk '{printf "%s \n",$0}'
    ${AV_SELECT}
     \g
EOF
fi
done
