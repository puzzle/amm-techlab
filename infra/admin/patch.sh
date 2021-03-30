#!/bin/bash

# set deployment strategy to Recreate

for i in {1..40}
do
   echo "change deployment strategy to Recreate in project hannelore$i"
   oc patch deployment/amm-techlab-ide --type json -p '[{"op": "replace", "path": "/spec/strategy/type", "value": "Recreate" }, { "op": "remove", "path": "/spec/strategy/rollingUpdate" }]' -n hannelore$i
   echo "restart IDE in project hannelore$i"
   oc rollout restart deployment/amm-techlab-ide -n hannelore$i
done
