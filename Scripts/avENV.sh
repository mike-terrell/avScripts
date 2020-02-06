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

export PAVERSION=5.1
export ACTIANHOME="/home/actian"
export AVSCRIPTS="${ACTIANHOME}/avScripts"

opts=$((cd $ACTIANHOME;ls .ing??sh) | tr -d '.')

if [ $(wc -w <<< "$opts") -gt 1 ]
then
   PS3='Please enter your choice of instance: '
   options=($opts)
   select opt in "${options[@]}"
   do
       source $ACTIANHOME/.$opt
       break
   done
else
   source $ACTIANHOME/.$opts
fi

TERM_INGRES=konsolel
export TERM_INGRES
export AV_SQLCMD="sql"
#export AV_HOST=01935a898c2096e4a.avstage.aws.actiandatacloud.com
export AV_HOST=`hostname`
#export AV_USER=dbuser
export AV_USER=actian
export AV_PASSWORD=act1an1
#export AV_DATABASE=db
export AV_PROTOCOL=tcp_ip
export AV_PORT=27832