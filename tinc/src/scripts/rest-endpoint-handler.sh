#!/bin/bash

source /scripts/helper.sh

net_name="test"

if [[ "${DEBUG:-}" == "y" ]]; then
  set -x
fi

function worker_connect {
  local worker_name=$1

  subnet=$(ip r | grep "dev ${net_name}" | cut -d ' ' -f 1)
  IFS=$'/' read -d '' -r -a subnetparts <<< "${subnet}" || true
  base_net=${subnetparts[0]}
  net_prefix=${subnetparts[1]}


  if [[ ! -f /etc/tinc/${net_name}/hosts/${worker_name} ]]; then
    # create entry
    idx=$(ls -l /etc/tinc/${net_name}/hosts | wc -l | cut -d ' ' -f 1)
    # this is server + nrOfClients + 1, so it's the correct idx out of the box
    ip=$(helper::add_to_ip ${base_net} ${idx})
  else
    ip=$(grep Subnet /etc/tinc/${net_name}/hosts/${worker_name} | cut -d ' ' -f 3 | cut -d '/' -f 1)
  fi

  mkdir -p /etc/tinc/dummy/hosts

  # Generate the public/private key pair for the client and it refuses to read the stdin when scripted so use a dummy network
  tincd -n "dummy" -K 1024 <<EOF


EOF

  tmppriv=/etc/tinc/dummy/rsa_key.priv
  tmppub=/etc/tinc/dummy/rsa_key.pub

  (cat <<EOF
Subnet = ${ip}/32
EOF
  ) > /etc/tinc/${net_name}/hosts/${worker_name}
  cat ${tmppub} >> /etc/tinc/${net_name}/hosts/${worker_name}

  printf "%s\n" "${net_name}"
  printf "%s\n" "${subnet}"
  printf "%s\n" "$(cat /etc/tinc/${net_name}/hosts/server | base64 | tr -d '\n')"
  printf "%s\n" "$(cat /etc/tinc/${net_name}/hosts/${worker_name} | base64 | tr -d '\n')"
  printf "%s\n" "$(cat ${tmppriv} | base64 | tr -d '\n')"

  rm -rf /etc/tinc/dummy
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
