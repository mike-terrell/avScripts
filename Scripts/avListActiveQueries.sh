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
       	echo "Usage: ${0} [-h]"
		cat <<-EOF
			List of currently running queries. 
			-h: Help

                        Note: Requires security privilege.
                              alter user dbuser with nogroup, PRIVILEGES = (SECURITY), DEFAULT_PRIVILEGES = (SECURITY)\g
		EOF
}

#
# Args
#

# Global ENV Variables
#

export AV_DATABASE=""
    while getopts "h" i;
    do
     case "${i}" in
             *) 
                     usage
                     exit -1
                     ;;
     esac
    done
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

echo "User       Client Host                    Database             Runtime              Query Text"
echo "----------------------------------------------------------------------------------------------"
cat <<EOF |${AV_SQLCMD} -S @${AV_HOST},${AV_PROTOCOL},${AV_PORT}[${AV_USER},${AV_PASSWORD}]::imadb | awk 'BEGIN {FS="|"} {printf "%-10s %-30s %-20s %-20s %s \n", $1, $2, $3, $4, $5}' | awk '{printf "%s, \n",$0}'
\nopadding
\vdelim |
select
        real_user,client_host,db_name,
        timestamp(current_timestamp) - timestamp(from_unixtime(query_start_secs)) as elapsed,
        rtrim(session_query)
from    ima_server_sessions s,ima_server_sessions_extra e
where   s.session_id = e.session_id
and     s.effective_user != ''
and     (e.session_state != 'CS_EVENT_WAIT' or e.session_wait_reason != 'BIOR')
and     db_name not in ('', 'imadb')
order by elapsed desc
\g
EOF
