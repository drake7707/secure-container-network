#!/bin/bash
set -x

source /scripts/helper.sh

function parseArgs {
 for i in "$@"; do
  case $i in
    --server)
      SERVER=y
      shift
    ;;
    
    --insecure)
      INSECURE=y
      shift
    ;;
    
    --port)
      shift
      PORT=$1
      shift
    ;;
    
    --subnet)
      shift
      SUBNET=$1
      shift
    ;;

    --endpoint)
      shift
      ENDPOINT=$1
      shift
      ;;
    *)
    # unknown option
    ;;
  esac
 done
}


function loadPeers {
  # add peers
  if [[ ! -f /data/peers ]]; then
    peers=$(cat /data/peers)
    IFS=$'\n' read -d '' -r -a lines <<< "${peers}" || true
    for line in "${lines[@]}"; do
      if [[ ! -z "${line}" ]]; then
        echo ${line}
        IFS=";" read -ra line_parts <<< "${line}"
        pubkey=${line_parts[0]}
        ip=${line_parts[1]}
        wg set ${IFACE} peer ${pubkey} allowed-ips ${ip}
      fi
    done
  fi
}

function setupServer {
  if [[ -z "${SUBNET}" ]]; then
    echo "No subnet specified for the VPN server (missing --subnet arg)" 1>&2
    exit 1
  fi

  # Configure tun device
  /usr/local/bin/wireguard-go ${IFACE} -f &
  wg_pid=$!

  if [[ ! -d /data/pki ]]; then
    mkdir -p /data/pki
  fi

  if [[ ! -f /data/pki/private.key ]]; then
     wg genkey > /data/pki/private.key
     wg pubkey < /data/pki/private.key > /data/pki/public.key
  fi

  echo "${SUBNET}" >> /data/subnet
 
  wg set ${IFACE} listen-port ${PORT:-51820} private-key /data/pki/private.key

  IFS=$'/' read -d '' -r -a subnetparts <<< "${SUBNET}" || true
  base_net=${subnetparts[0]}
  net_prefix=${subnetparts[1]}

  ip=$(helper::add_to_ip ${base_net} 1)

  ip addr add dev ${IFACE} ${ip}

  loadPeers

  ip link set dev ${IFACE} up

  # run the endpoint
  while true; do
    rest-endpoint --script "/scripts/rest-endpoint-handler.sh"
    sleep 1
  done
}


function setupClient {
  if [[ -z "${ENDPOINT}" ]]; then
    echo "No endpoint specified for the VPN client (missing --endpoint arg)" 1>&2
    exit 1
  fi

  # Configure tun device
  /usr/local/bin/wireguard-go ${IFACE} -f &
  wg_pid=$!

  if [[ ! -d /data/pki ]]; then
    mkdir -p /data/pki
  fi

  if [[ ! -f /data/pki/private.key ]]; then
     wg genkey > /data/pki/private.key
     wg pubkey < /data/pki/private.key > /data/pki/public.key
  fi

  pubkey=$(cat /data/pki/public.key)

  if [[ -z ${INSECURE:-} ]]; then
     prefix="http://"
  else
     prefix="https://"
  fi

  base64pubkey=$(echo "${pubkey}" | base64)
  result=$(wget -O - -q "${prefix}${ENDPOINT}/associate-peer/${base64pubkey}")

  if [[ $? == 0 && ! -z ${result} ]]; then

    IFS=$'\n' read -d '' -r -a lines <<< "${result}" || true
    endpointpubkey=${lines[0]}
    clientip=${lines[1]}
    base_net=${lines[2]}
    net_prefix=${lines[3]}


    wg set ${IFACE} private-key /data/pki/private.key peer ${endpointpubkey} allowed-ips ${base_net}/${net_prefix} endpoint ${ENDPOINT}

    ip addr add dev ${IFACE} ${clientip}/${net_prefix}

    ip link set dev ${IFACE} up
  else
    echo "Unable to connect to remote endpoint" 1>&2
    exit 1
  fi
}


parseArgs "$@"
IFACE=wg0


if [[ ${SERVER} == "y" ]]; then
   setupServer
else
   setupClient
fi
