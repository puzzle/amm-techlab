#!/bin/bash

# Update ide deployment and restart ide

script_dir=`dirname $0`

for i in {1..20}
do
   echo "update ide deployment for project hannelore$i"
   oc patch deploy/amm-techlab-ide --type "json" -p '[{"op":"remove","path":"/spec/template/spec/containers/0/command"}]' -n hannelore$i
   oc patch deploy/amm-techlab-ide --type "json" -p '[{"op":"remove","path":"/spec/template/spec/containers/0/args"}]' -n hannelore$i
   oc set env deploy/amm-techlab-ide LAB_USER=hannelore$i -n hannelore$i
   oc rollout restart deploy/amm-techlab-ide -n hannelore$i
done
