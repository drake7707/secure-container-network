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

   local timestamp=$(date +%s%N)

   utime=0
   ktime=0
   cutime=0
   cktime=0
   vmsize=0
   rsssize=0
   sharedsize=0

   while IFS= read -r PID; do
      echo "Text read from file: $PID"

      stat=$(cat /proc/$PID/stat | cut -d ' ' -f 14,15,16,17)
      mstat=$(cat /proc/$PID/statm | cut -d ' ' -f 1,2,3)

      IFS=$' ' read -d '' -r -a stat_parts <<< "$stat"
      IFS=$' ' read -d '' -r -a mstat_parts <<< "$mstat"

      ((utime=utime+stat_parts[0]))
      ((ktime=ktime+stat_parts[1]))
      ((cutime=cutime+stat_parts[2]))
      ((cktime=cktime+stat_parts[3]))

      ((vmsize=vmsize+mstat_parts[0]))
      ((rsssize=rsssize+mstat_parts[1]))
      ((sharedsize=sharedsize+mstat_parts[2]))

   done < "/var/run/vpn.pid"
   echo "${timestamp} ${utime} ${ktime} ${cutime} ${cktime} ${vmsize} ${rsssize} ${sharedsize}"

#   local PID=$(cat /var/run/vpn.pid)
#   local timestamp=$(date +%s%N)
#   echo "${timestamp} $(cat /proc/$PID/stat | cut -d ' ' -f 14,15,16,17) $(cat /proc/$PID/statm | cut -d ' ' -f 1,2,3)"
}


while true; do
  checkProcessStats >> /data/server_proc.txt
  sleep 1
done
