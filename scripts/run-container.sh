#!/bin/bash
set -x


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

    --ip)
      shift
      IP=$1
      shift
    ;;

    --endpoint)
      shift
      ENDPOINT=$1
      shift
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
  if [[ -z "${IP}" ]]; then
    echo "No ip specified for the VPN server (missing --ip arg)" 1>&2
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

  wg set ${IFACE} listen-port ${PORT:-51820} private-key /data/pki/private.key

  ip addr add dev ${IFACE} ${IP}

  loadPeers

  ip link set dev ${IFACE} up
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

  result=$(wget -O - -q "${prefix}${ENDPOINT}/associate-peer/${pubkey}")

  if [[ $? == 0 && ! -z ${result} ]]; then

    IFS=$'\n' read -d '' -r -a lines <<< "${result}" || true
    endpointpubkey=${lines[0]}
    clientip=${lines[1]}
    subnet=${lines[2]}

    wg set ${IFACE} private-key /data/pki/private.key peer ${endpointpubkey} allowed-ips ${clientip} endpoint ${ENDPOINT}

    ip addr add dev ${IFACE} ${clientip}

    ip link set dev ${IFACE} up
  else
    echo "Unable to connect to remote endpoint" 1>&2
    exit 1
  fi
}


parseArgs
IFACE=wg0


if [[ ${SERVER} == "y" ]]; then
   setupServer
else
   setupClient
fi
