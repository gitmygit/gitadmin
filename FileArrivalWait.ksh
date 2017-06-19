#!/bin/ksh
# FileArrivalWait.ksh
#
# Description  : Wait for a file to be completely written # History
# Name        Date     Req. no      Description
# kg40708     20070427  New         Accepts file name and optionally a sleep period.  Exits when the file is ready to be picked up.
#
# Modified by kg40708 on 03-Jul-2007 to issue a FATAL alert to PROD_SUPPORT when the wait has exceeded 15 minutes 
# Modified by kg40708 on 03-Jul-2007 to consider files opened with mmap 
# Modified by lg84970 on 01-Aug-2007 to ignore the sleep period passed as it no longer applies 
# Modified by lg84970 on 15-Nov-2010 : AIX Port
# Modified by lg84970 on 20-Oct-2013 : Replace fuser with file size polling 
#					Added back sleep period arg
# 
# Environment variables # DEBUG_MODE, when set to any value will enable printing of the commands as they are executed ( set -x ) 
# 
# Params:
#     < File Pattern > <sleep period in secs> 
#
USAGE="< File Pattern > <sleep period in secs>"
typeset -i SP
SP=${2:-"5"} # Standard sleep period
## Set the environment variable DEBUG_MODE to print commands as they are executed 
##
if [ "$DEBUG_MODE" ]; then
    set -x
fi

## PARAMETER evaluation
##
P1=${1:?"$USAGE"} # File Pattern
##
## File Pattern is the first parameter
FP="$P1"

## Check for file existence
##
if [ ! -f $FP ]; then
    exit 20  
fi

cumulative_sleep_period=0
## Infinite Loop, breaks out when there are no active processes writing into the files 
######################################################
#
PrevSize=`ls -l ${FP} | awk '{print $5}'`

while [ : ]; do
## Check for file existence
##
    if [ ! -f $FP ]; then
        echo "FATAL: FileArrivalWait.ksh has waited for file $FP, but it no longer exists"
        exit 30
    fi

###################

   sleep $SP
   CurrSize=`ls -l ${FP} | awk '{print $5}'`
   if [[ $CurrSize == $PrevSize ]]
   then
       break # file size is stable, so exit
   fi
   PrevSize=$CurrSize
####################


    let cumulative_sleep_period+=$SP
    if [ $cumulative_sleep_period -ge 900 ]; then
        echo "FATAL: FileArrivalWait.ksh has waited for $cumulative_sleep_period seconds on $FP"
        sleep 900
    fi
done
###################

