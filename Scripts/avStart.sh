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
