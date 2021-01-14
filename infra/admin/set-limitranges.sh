#!/bin/bash

# Limitranges optimized for pipelines

script_dir=`dirname $0`

for i in {1..20}
do
   echo "set limitrange for project hannelore$i"
   oc apply -f "${script_dir}/configuration/limitrange.yaml" -n hannelore$i
   oc describe limitranges -n hannelore$i
done
