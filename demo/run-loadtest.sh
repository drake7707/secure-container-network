#!/bin/bash
set -x

for ((i=25;i<=300;i+=25)); do

   echo "Setting up run $i"

   name=$i
   ./run-demo.sh run $i ${name}

   echo "Waiting for a bit"
   sleep 10

   echo "Terminating run $i"
  ./run-demo.sh clean $i ${name}
done
