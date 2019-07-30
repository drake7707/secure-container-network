#!/bin/bash
set -x


loadsleep=$1

if [[ -z "${loadsleep:-}" ]]; then
	echo "Specify sleep duration between REST requests" 1>&2
	exit 1
fi

vpns=( "tinc" "softether" "zerotier" "openvpn" "wireguard" )

for vpn in ${vpns[@]}; do

   n=100

   echo "Setting up run $vpn"

   name=$vpn
   ./run-kubernetes.sh run $n run-${name} ${vpn} ${loadsleep}

   echo "Waiting for a bit"
   sleep 900

   echo "Terminating run $vpn"
  ./run-kubernetes.sh clean $n run-${name} ${vpn} ${loadsleep}

  sleep 100
done
