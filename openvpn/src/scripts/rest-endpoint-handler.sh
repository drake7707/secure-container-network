#!/bin/bash

source /scripts/helper.sh

if [[ "${DEBUG:-}" == "y" ]]; then
  set -x
fi

function worker_connect {
  local worker_name=$1

  if [[ ! -f /data/peers/${worker_name}.conf ]]; then

    cd /data

    # Build the client pki
    /usr/share/easy-rsa/easyrsa build-client-full "${worker_name}" nopass 1>/dev/null 2>&1
    /scripts/build_config.sh client ${worker_name}
  fi

  vpn_profile=$(cat /data/peers/${worker_name}.conf)

  printf "%s\n" "${vpn_profile}"
}

# Handle the requests
method=$1
path=$2
if echo ${path} | grep -qE '^/(associate-peer)'; then
  IFS='/' read -ra url_parts <<< "${path}"
  len=${#url_parts[@]}
  name=${url_parts[len-1]}


  result=$(worker_connect ${name})
  printf "%s" "${result}"

fi

