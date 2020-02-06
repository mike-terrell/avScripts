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
        source ${options[${ret}]}
else
        echo "Missing the 'avENV.sh' program."
        echo "Please run ./avSetup.sh script to setup environment."
        exit -1
fi

export TERM_INGRES
