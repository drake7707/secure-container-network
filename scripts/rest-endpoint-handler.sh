#!/bin/bash
set -x

source /scripts/helper.sh

IFACE=wg0

if [[ "${DEBUG:-}" == "y" ]]; then
  set -x
fi

function worker_connect {
  local worker_pubkey=$(echo "$1" | base64 -d)

  subnet=$(cat /data/subnet)
  IFS=$'/' read -d '' -r -a subnetparts <<< "${subnet}" || true
  base_net=${subnetparts[0]}
  net_prefix=${subnetparts[1]}

  if [[ ! -f /data/peers ]]; then
    line=""
  else
    line=$(grep -q "${worker_pubkey}" /data/peers)
  fi

  if [[ ! -z ${line} ]]; then
     IFS=";" read -ra line_parts <<< "${line}"
     pubkey=${line_parts[0]}
     ip=${line_parts[1]}
  else
    nrPeers=$(wc -l /data/peers | cut -d ' ' -f 1)
    # 1 is server, 1 for new
    idx=${nrPeers}
    ((idx+=2))
    ip=$(helper::add_to_ip ${base_net} ${idx})
    echo "${worker_pubkey};${ip}" >> /data/peers
    # add peer to wireguard interface
    wg set ${IFACE} peer ${worker_pubkey} allowed-ips ${ip}
  fi

  endpointpubkey=$(cat /data/pki/public.key)

  printf "%s\n" "${endpointpubkey}"
  printf "%s\n" "${ip}"
  printf "%s\n" "${base_net}"
  printf "%s\n" "${net_prefix}"
}

# Handle the requests
method=$1
path=$2
if echo ${path} | grep -qE '^/(associate-peer)'; then
  IFS='/' read -ra url_parts <<< "${path}"
  len=${#url_parts[@]}
  base64pubkey=${url_parts[len-1]}
  
  result=$(worker_connect ${base64pubkey})
  printf "%s" "${result}"
fi

