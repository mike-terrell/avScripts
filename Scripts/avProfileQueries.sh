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
       	echo "Usage: ${0} -d database -q query file [-h]"
		cat <<-EOF
                        -d: database        - Database name.
                        -q: query file      - File containg query. Must include \g
                        -p: pdf profile file - Create a PDF for the query profie
                        -h: Help            - Help
		EOF
        exit 1
}

#
# Global ENV Variables
#
#
# Args
#
export AV_DATABASE=""
export AV_QFILE=""
export PROFGRAPH_PATH=$II_SYSTEM/ingres/sig/x100profgraph/x100profgraph
    while getopts "d:q:ph" i
    do
     case "$i" in
             d)
                     export AV_DATABASE=${OPTARG}
                     ;;

             q)
                     export AV_QFILE=${OPTARG}
                     ;;
             p)
                     AV_PROFILE=1
                     ;;


             h) 
                     usage
                     exit -1
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
if [ "${AV_QFILE}" == "" ]
    then
        echo "${0}: Error, you need to speciify a query file."
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

#echo "CALL VECTORWISE(SETCONF 'server, profiling, ''true''')\g" > /tmp/${AV_QFILE}.tmp


if [ "${AV_PROFILE}"  == "1" ]
then
    echo "\SUPPRESS\g" > /tmp/${AV_QFILE}.tmp
    echo "CALL VECTORWISE(SETCONF 'server, profiling, ''true''')\g" >> /tmp/${AV_QFILE}.tmp
    cat ${AV_QFILE} >> /tmp/${AV_QFILE}.tmp
    echo "CALL VECTORWISE(print_profile '''/tmp/${AV_QFILE}.profile''')\g" >> /tmp/${AV_QFILE}.tmp
else
    echo "\SUPPRESS\g" > /tmp/${AV_QFILE}.tmp
    cat ${AV_QFILE} >> /tmp/${AV_QFILE}.tmp
fi
echo "\q" >> /tmp/${AV_QFILE}.tmp

${AV_SQLCMD} -S @${AV_HOST},${AV_PROTOCOL},${AV_PORT}[${AV_USER},${AV_PASSWORD}]::${AV_DATABASE} < /tmp/${AV_QFILE}.tmp # >/dev/null 2>&1


if [ ${AV_PROFILE}  == 1 ]
then
$PROFGRAPH_PATH --pdf < /tmp/${AV_QFILE}.profile > /tmp/${AV_QFILE}.profile.pdf
fi
