#!/bin/bash

for i in {1..10}
do
   echo "label namespace to grant rights for argocd in project hannelore$i"
   oc label namespaces hannelore$i argocd.argoproj.io/managed-by=techlab-argocd
   oc get namespace hannelore$i --show-labels
done
