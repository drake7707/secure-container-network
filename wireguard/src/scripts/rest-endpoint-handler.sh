#!/bin/bash

source /scripts/helper.sh

IFACE=wg0

if [[ "${DEBUG:-}" == "y" ]]; then
  set -x
fi

function ensure_entry {
    if [[ ! -f /data/peers ]]; then
      line=""
    else
      line=$(grep "${worker_pubkey_base64}" /data/peers)
    fi

    if [[ ! -z ${line} ]]; then
       IFS=";" read -ra line_parts <<< "${line}"
       pubkey=${line_parts[0]}
       ip=${line_parts[1]}
    else
      if [[ ! -f /data/peers ]]; then
        nrPeers=0
      else
        nrPeers=$(wc -l /data/peers | cut -d ' ' -f 1)
      fi
      # 1 is server, 1 for new
      idx=${nrPeers}
      ((idx+=2))
      ip=$(helper::add_to_ip ${base_net} ${idx})
      echo "${worker_pubkey_base64};${ip}" >> /data/peers
    fi
}

function worker_connect {
  local worker_pubkey_base64=$1
  local worker_pubkey=$(echo "$1" | base64 -d)

  subnet=$(cat /data/subnet)
  IFS=$'/' read -d '' -r -a subnetparts <<< "${subnet}" || true
  base_net=${subnetparts[0]}
  net_prefix=${subnetparts[1]}

  ensure_entry


  line=$(grep "${worker_pubkey_base64}" /data/peers)

  IFS=";" read -ra line_parts <<< "${line}"
  pubkey=${line_parts[0]}
  ip=${line_parts[1]}

  # add peer to wireguard interface
  wg set ${IFACE} peer ${worker_pubkey} allowed-ips ${ip} &

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

