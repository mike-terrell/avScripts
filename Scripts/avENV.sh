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
# Actian Client
#

#!/bin/bash

# This script is not a Actian-supported product, and is provided as-is, without warranty of any kind.

#



#

# Version

#

export PAVERSION=1.0.0



#

# Functions

#

createmenu ()

{

  arrsize=$1

  select option in "${@:2}"; do

    if [ "$REPLY" -eq "$arrsize" ];

    then

      echo "Exiting..."

      break;

    elif [ 1 -le "$REPLY" ] && [ "$REPLY" -le $((arrsize-1)) ];

    then

      break;

    fi

  done

}

#

# Actian Client

#

TERM_INGRES=konsolel

export AV_SQLCMD="sql"
#export AV_HOST=01935a898c2096e4a.avstage.aws.actiandatacloud.com
export AV_HOST=`hostname`
#export AV_USER=dbuser
export AV_USER=actian
export AV_PASSWORD=act1an1
#export AV_DATABASE=db
export AV_PROTOCOL=tcp_ip
export AV_PORT=27832


ret=0

unset options i

while IFS= read -r  f; do

  options[i++]="$f"

done < <(ls ~/.ing??sh | awk '{print $1} END {print "Exit Script";}')

if [ "${#options[@]}" -eq 1 ]

then

        echo "Missing the 'avENV.sh' program."

        echo "Please run ./avSetup.sh script to setup environment."

        exit -1

fi



while true

do

   if [ "${#options[@]}" -eq 2 ]

   then

      ret=0

      break

   fi

   createmenu "${#options[@]}" "${options[@]}"}

   cnt=${#options[@]}

   ret="$(($REPLY-1))"



   if [ ${REPLY} -le ${cnt} ]

   then

      break

   fi

done



if [ -f ${options[${ret}]} ]

then

#
# Connection 
#
        source ${options[${ret}]}

else

        echo "Missing the 'avENV.sh' program."

        echo "Please run ./avSetup.sh script to setup environment."

        exit -1

fi



export TERM_INGRES

