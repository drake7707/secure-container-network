#!/bin/bash
set -x

for ((i=25;i<=400;i+=25)); do

   echo "Setting up run $i"

   name=$i
   ./run-kubernetes.sh run $i run-${name}

   echo "Waiting for a bit"
   sleep 900

   echo "Terminating run $i"
  ./run-kubernetes.sh clean $i run-${name}

  sleep 300
done
