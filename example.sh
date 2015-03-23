#!/bin/bash
#
#PBS -S /bin/bash
#PBS -o /home/[YOUR_USER_NAME]/sge_output
#PBS -e /home/[YOUR_USER_NAME]/sge_error
#PBS -t 1-4

uname -a
date
echo "PBS Job ID: $PBS_JOBID"
echo "PBS Task ID: $PBS_ARRAYID"

# Read task parameters from file settings.txt
#  and define them as environment variables PARAM1-4

export $(head -$PBS_ARRAYID settings.txt | tail -1 | awk 'BEGIN{ OFS=""; } { printf "PARAM1="; print $1; }')
export $(head -$PBS_ARRAYID settings.txt | tail -1 | awk 'BEGIN{ OFS=""; } { printf "PARAM2="; print $2; }')
export $(head -$PBS_ARRAYID settings.txt | tail -1 | awk 'BEGIN{ OFS=""; } { printf "PARAM3="; print $3; }')
export $(head -$PBS_ARRAYID settings.txt | tail -1 | awk 'BEGIN{ OFS=""; } { printf "PARAM4="; print $4; }')

echo "1st Parameter: $PARAM1"
echo "2nd Parameter: $PARAM2"
echo "3rd Parameter: $PARAM3"
echo "4th Parameter: $PARAM4"

# for each file in a given directory (here, all of the file* files in /home/[YOUR_USER_NAME]]/sge_data/), 
#  call python script using these parameters

FILES=(/home/[YOUR_USER_NAME]/sge_data/file*.txt)
for f in "${FILES[@]}"
do
  python myscript.py $PARAM1 $PARAM2 $PARAM3 $PARAM4 $f
done
