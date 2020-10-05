#!/bin/bash
for i in {1..15}
do
   echo "deleting hannelore$i projects"
   oc delete project hannelore$i hannelore$i-operator hannelore$i-resources
done

echo "------------"
echo "missed some hannelore projects?"
oc get project | grep hannelore
