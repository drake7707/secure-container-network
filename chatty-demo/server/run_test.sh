#!/bin/bash
set -x

/scripts/run-container.sh $@

if [[ $? != 0 ]]; then
  echo "Connection to VPN server was not set up correctly" 1>&2
  exit 1
fi


# find the vpn interface, in the container there are only 3, lo , eth0 and the vpn iface
vpn_iface=$(ls -1 /sys/class/net/ | grep -e "[^lo|eth0]")

errcount=0
while [[ -z ${vpn_iface} ]]; do
  sleep 1
  ((errcount++))
  if [[ ${errcount} > 5 ]]; then
    echo "Interface did not came up in time" 1>&2
    exit 1
  fi
  vpn_iface=$(ls -1 /sys/class/net/ | grep -e "[^lo|eth0]")
done


eth_iface=eth0

function checkProcessStats {
   local PID=$(cat /var/run/vpn.pid)
   local timestamp=$(date +%s%N)
   echo "${timestamp} $(cat /proc/$PID/stat | cut -d ' ' -f 14,15,16,17) $(cat /proc/$PID/statm | cut -d ' ' -f 1,2,3)"
}


while true; do
  checkProcessStats >> /data/server_proc.txt
  sleep 1
done
