#!/bin/bash
for i in {1..20}
do
   echo "add ServiceMonitor rihgts for hannelore$i in project hannelore$i"
   oc policy add-role-to-user monitoring-edit hannelore$i -n hannelore$i
done