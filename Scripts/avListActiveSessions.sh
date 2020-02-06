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
			List of currently connected users.
			-h: Help
                        
                        Note: Requires security privilege.
                              alter user mike with nogroup, PRIVILEGES = (SECURITY), DEFAULT_PRIVILEGES = (SECURITY)\g
		EOF
}

#
# Args
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
                                
echo "User       Client Host                    Database             Connect Time                     State"
echo "--------------------------------------------------------------------------------------------------------------------"
cat <<EOF |${AV_SQLCMD} -S @${AV_HOST},${AV_PROTOCOL},${AV_PORT}[${AV_USER},${AV_PASSWORD}]::imadb | awk 'BEGIN {FS="|"} {printf "%-10s %-30s %-20s %-20s %s \n", $1, $2, $3, $4, $5}' | awk '{printf "%s \n",$0}'
\nopadding
\vdelim |
select  ss.real_user,ss.client_host, ss.db_name,
        timestamp_with_tz(from_unixtime(se.session_time)) as connect_time,
        trim(se.session_state)||' '||trim(se.session_wait_reason) as state
from    ima_server_sessions_extra se, ima_server_sessions ss
where   se.server = ss.server
and     se.session_id = ss.session_id
and     ss.db_name not in ('imadb', '')
\g
EOF
