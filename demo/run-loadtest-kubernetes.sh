#!/bin/bash
set -x

vpn=${1}

for ((i=25;i<=1000;i+=25)); do

   echo "Setting up run $i"

   name=$i
   ./run-kubernetes.sh run $i run-${name} ${vpn}

   echo "Waiting for a bit"
   sleep 900

   echo "Terminating run $i"
  ./run-kubernetes.sh clean $i run-${name} ${vpn}

  sleep 300
done
