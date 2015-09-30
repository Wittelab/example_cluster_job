#!/bin/bash
#
#PBS -S /bin/bash
#PBS -o /home/carioc/test/output/sge-output
#PBS -e /home/carioc/test/errors/sge-error
#PBS -t 1-5

# Print some useful information to the output file
uname -a
date
echo "Project Directory: /home/carioc/test"
echo "PBS Job ID:        $PBS_JOBID"
echo "PBS Task ID:       $PBS_ARRAYID"

# Navigate to the project directory and give the script executable permissions
cd /home/carioc/test
chmod a+x myscript.py

# Read the job parameters from the 'settings.txt' file
#  and pass them as paramaters to the script (this should include working files)
read -a PARAMS <<< $(sed '/#/d;' settings.txt | sed "s/\t/ /g;${PBS_ARRAYID}q;d")

# Run the script on this node
myscript.py ${PARAMS[@]}