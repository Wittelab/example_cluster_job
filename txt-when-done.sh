#!/bin/bash
#
# This script will email (txt email) parameter $2 when process $1 has finished on a SGE via qstat

status="Q";

while [ "$status" == "Q" -o "$status" == "R" ]
do
    sleep 5s;
    status=$(qstat | grep $1 | awk 'BEGIN{FS=" "}{print $5}');
    if [ "$status" == "" -o "$status" == "CD" ]
    then
        echo "Your job with ID $1 has finished." | mail -s "\ >_<" $2
        break;
    fi
done
