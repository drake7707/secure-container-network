#!/bin/bash
set -x

vpn=${1:-wireguard}
n=100

for ((i=0;i<=100;i+=5)); do

   echo "Setting up run $i"

   name=$i
   ./run-kubernetes.sh run $n run-${name} ${vpn} $i

   echo "Waiting for a bit"
   sleep 900

   echo "Terminating run $i"
  ./run-kubernetes.sh clean $n run-${name} ${vpn} $i

  sleep 100
done
