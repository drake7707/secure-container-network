#!/bin/bash
set -x

vpn=${1}
n=100

for ((i=0;i<=10000;i+=500)); do

   echo "Setting up run $i"

   name=$i
   ./run-kubernetes.sh run $n run-${name} ${vpn} 0 $i

   echo "Waiting for a bit"
   sleep 900

   echo "Terminating run $i"
  ./run-kubernetes.sh clean $n run-${name} ${vpn} 0 $i

  sleep 100
done
