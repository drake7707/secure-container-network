#!/bin/bash

source /scripts/helper.sh

if [[ "${DEBUG:-}" == "y" ]]; then
  set -x
fi

function ensure_entry {
    if [[ ! -f /data/peers ]]; then
      line=""
    else
      line=$(grep "${worker_name}" /data/peers)
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
      echo "${worker_name};${ip}" >> /data/peers
    fi
}

function worker_connect {
  local worker_name=$1

  subnet=$(cat /data/subnet)
  hubname=$(cat /data/hubname)

  IFS=$'/' read -d '' -r -a subnetparts <<< "${subnet}" || true
  base_net=${subnetparts[0]}
  net_prefix=${subnetparts[1]}

  ensure_entry

  line=$(grep "${worker_name}" /data/peers)

  IFS=";" read -ra line_parts <<< "${line}"
  name=${line_parts[0]}
  ip=${line_parts[1]}


  # create a user
  vpncmd localhost:443 /SERVER /Hub:${hubname} /CMD UserCreate ${worker_name} /GROUP:"" /REALNAME:"" /NOTE:"" > /dev/null
  # set user password
  password=${worker_name}
  vpncmd localhost:443 /SERVER /Hub:${hubname} /CMD UserPasswordSet ${worker_name} /PASSWORD:${password} > /dev/null

  printf "%s\n" "${hubname}"
  printf "%s\n" "${password}"
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
  worker_name=${url_parts[len-1]}


  result=$(worker_connect ${worker_name})
  printf "%s" "${result}"

fi

