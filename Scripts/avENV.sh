#!/bin/bash
#
# This script is not a Actian-supported product, and is provided as-is, without warranty of any kind.
#

#
# Version
#
export PAVERSION=5.1

#
# PADB Constants
#
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
