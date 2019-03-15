#!/bin/bash
set -x

for ((i=125;i<=400;i+=25)); do

   echo "Setting up run $i"

   name=$i
   ./run-demo.sh run $i ${name}

   echo "Waiting for a bit"
   sleep 900

   echo "Terminating run $i"
  ./run-demo.sh clean $i ${name}
done
