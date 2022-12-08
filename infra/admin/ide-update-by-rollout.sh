#!/bin/bash

# Update ide deployment and restart ide

script_dir=`dirname $0`

for i in {1..10}
do
   echo "rollout ide for project hannelore$i"
   oc rollout restart deploy/amm-techlab-ide -n hannelore$i
done
