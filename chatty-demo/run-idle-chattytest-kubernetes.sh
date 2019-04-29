#!/bin/bash
set -x


vpns=( "openvpn", "wireguard", "zerotier", "tinc", "softether" )

for vpn in ${vpns[@]}; do

   n=100

   echo "Setting up run $vpn"

   name=$vpn
   ./run-kubernetes.sh run $n run-${name} ${vpn}

   echo "Waiting for a bit"
   sleep 900

   echo "Terminating run $vpn"
  ./run-kubernetes.sh clean $n run-${name} ${vpn}

  sleep 100
done
