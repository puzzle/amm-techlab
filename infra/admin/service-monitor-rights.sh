#!/bin/bash

for i in {1..20}
do
   echo "add ServiceMonitor rihgts for hannelore and argocd in project hannelore$i"
   oc policy add-role-to-user monitoring-edit hannelore -n hannelore$i
   oc policy add-role-to-user monitoring-edit system:serviceaccount:pitc-infra-argocd:argocd-application-controller -n hannelore$i
   echo "add ServiceMonitor rihgts for hannelore$i in project hannelore$i"
   oc policy add-role-to-user monitoring-edit hannelore$i -n hannelore$i
done
