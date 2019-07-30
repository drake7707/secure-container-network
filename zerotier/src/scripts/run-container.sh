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
    --foreground)
      shift
      FOREGROUND=y
    ;;

    *)
    # unknown option
    ;;
  esac
 done
}

function setupServer {
  if [[ -z "${SUBNET}" ]]; then
    echo "No subnet specified for the VPN server (missing --subnet arg)" 1>&2
    exit 1
  fi

  IFS=$'/' read -d '' -r -a subnetparts <<< "${SUBNET}" || true
  base_net=${subnetparts[0]}
  net_prefix=${subnetparts[1]}

  first_ip=$(helper::add_to_ip ${base_net} 2)
  last_ip=$(helper::lastip ${base_net} ${net_prefix})

  server_ip=$(helper::add_to_ip ${base_net} 1)


  zerotier-one &
  pid=$!
  echo ${pid} > /var/run/vpn.pid

  # wait until the token is created by the daemon
  while [[ ! -f /var/lib/zerotier-one/authtoken.secret ]]; do
     sleep 1
  done

  # get local address
  while ! curl -s -X GET --header "X-ZT1-Auth: $(cat /var/lib/zerotier-one/authtoken.secret)" 'http://localhost:9993/status'; do
    sleep 1
  done
  address=$(curl -s -X GET --header "X-ZT1-Auth: $(cat /var/lib/zerotier-one/authtoken.secret)" 'http://localhost:9993/status' | jq ".address" | sed 's/"//g')

  # create network
  curl -s -X POST --header "X-ZT1-Auth: $(cat /var/lib/zerotier-one/authtoken.secret)" -d '{"name":"test", "private":false, "v4AssignMode": { "zt": true }, "ipAssignmentPools": [ { "ipRangeStart": "'${first_ip}'", "ipRangeEnd": "'${last_ip}'" }], "routes": [ { "target": "'${SUBNET}'" } ] }' 'http://localhost:9993/controller/network/'${address}'______' -v

  # get network id
  networkid=$(curl -s -X GET --header "X-ZT1-Auth: $(cat /var/lib/zerotier-one/authtoken.secret)" 'http://localhost:9993/controller/network/' | jq ".[0]" | sed 's/"//g')

  # join the network as node
  zerotier-cli join ${networkid}

  # get the network interface
  iface=$(zerotier-cli listnetworks | cut -d ' ' -f 8 | sed -n '1!p')

  # add a manual assignment of 6.0.0.1 to the interface
  ip a a ${server_ip}/8 dev ${iface}

  ownmember=$(zerotier-cli status | cut -d ' ' -f 3)

  echo "Address: ${address}"
  echo "Network id: ${networkid}"
  echo "Own node id: ${ownmember}"

  if [[ "${FOREGROUND:-n}" == "y" ]]; then
    while true; do
      if ! ip a s ${iface} > /dev/null 2>&1; then
        echo "Interface ${iface} doesn't exist anymore, exiting"
        exit 1
      fi

      sleep 1
    done
  fi
}


function setupClient {
  if [[ -z "${ENDPOINT}" ]]; then
    echo "No endpoint specified for the VPN client (missing --endpoint arg)" 1>&2
    exit 1
  fi

  zerotier-one &
  pid=$!
  echo ${pid} > /var/run/vpn.pid

  # wait until the token is created by the daemon
  while [[ ! -f /var/lib/zerotier-one/authtoken.secret ]]; do
     sleep 1
  done

  while ! zerotier-cli status; do
    sleep 1
  done

  zerotier-cli join ${ENDPOINT}

  # get the network interface
  iface=$(zerotier-cli listnetworks | cut -d ' ' -f 8 | sed -n '1!p')

  if [[ "${FOREGROUND:-n}" == "y" ]]; then
    while true; do

      if ! ip a s ${iface} > /dev/null 2>&1; then
        echo "Interface ${IFACE} doesn't exist anymore, exiting"
        exit 1
      fi

      sleep 1
    done
  fi

}


parseArgs "$@"


if [[ ${SERVER} == "y" ]]; then
   setupServer
else
   setupClient
fi
