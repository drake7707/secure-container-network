#!/bin/bash
set -x

/scripts/run-container.sh --endpoint $1

PORT=${2}

export LOAD_SLEEP=${3:-36000}

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

# monitor the tcp/udp on the port used by the vpn to filter out all other traffic
iptables -A INPUT -p udp --dport $PORT -i eth0
iptables -A OUTPUT -p udp --sport $PORT -o eth0
iptables -A INPUT -p tcp --dport $PORT -i eth0
iptables -A OUTPUT -p tcp --sport $PORT -o eth0


old_vpn_rx=-1
old_vpn_tx=-1
old_eth_rx=-1
old_eth_tx=-1

function checkBytes {
  eth_rx="$(cat /sys/class/net/${eth_iface}/statistics/rx_bytes)"
  eth_tx="$(cat /sys/class/net/${eth_iface}/statistics/tx_bytes)"

  vpn_rx="$(cat /sys/class/net/${vpn_iface}/statistics/rx_bytes)"
  vpn_tx="$(cat /sys/class/net/${vpn_iface}/statistics/tx_bytes)"

  vpn_rx_packets="$(cat /sys/class/net/${vpn_iface}/statistics/rx_packets)"
  vpn_tx_packets="$(cat /sys/class/net/${vpn_iface}/statistics/tx_packets)"

  lines=$(iptables -x -L -v | grep -E "Chain INPUT|OUTPUT" | cut -d ' ' -f 2,5,7)
  IFS=$'\n' read -d '' -ra line_arr <<< "${lines}"

  for line in "${line_arr[@]}"; do
	IFS=' ' read -ra parts_arr <<< "${line}"
	type="${parts_arr[0]}"
	packets="${parts_arr[1]}"
	bytes="${parts_arr[2]}"

	if [[ "${type}" == "INPUT" ]]; then
		eth_rx=${bytes}
		eth_rx_packets=${packets}
	elif [[ "${type}" == "OUTPUT" ]]; then
		eth_tx=${bytes}
		eth_tx_packets=${packets}
	fi
  done


  if [[ ${eth_rx} != ${old_eth_rx} || ${vpn_rx} != ${old_vpn_rx} || ${eth_tx} != ${old_eth_tx} || ${vpn_tx} != ${old_vpn_tx} ]]; then
     local timestamp=$(date +%s%N)
     echo "${timestamp};${eth_rx};${eth_tx};${eth_rx_packets};${eth_tx_packets};${vpn_rx};${vpn_tx};${vpn_rx_packets};${vpn_tx_packets}"
  fi

  old_eth_rx=${eth_rx}
  old_vpn_rx=${vpn_rx}

  old_eth_tx=${eth_tx}
  old_vpn_tx=${vpn_tx}

}


# generate some requests
(while true; do sleep ${LOAD_SLEEP}; curl -s http://6.0.0.1:1500/test > /dev/null; done) &

while true; do
  checkBytes >> /results/$(hostname).csv
  sleep 1
done
