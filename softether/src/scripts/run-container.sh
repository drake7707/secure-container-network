#!/bin/bash
#set -x

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

  # Start VPN server
  vpnserver execsvc &
  server_pid=$!
#  echo ${server_pid} > /var/run/vpn.pid

  errcount=0
  while ! vpncmd localhost:443 /SERVER /CMD About > /dev/null 2>&1; do
    sleep 1
    ((errcount++))
    if [[ ${errcount} > 5 ]]; then
      echo "Softether VPN server did not came up in time" 1>&2
      exit 1
    fi
  done

  echo "${SUBNET}" >> /data/subnet

  # Todo check if they aren't already configured 
  HUBNAME="myhub"

  echo "${HUBNAME}" >> /data/hubname

  # create a virtual hub
  vpncmd localhost:443 /SERVER /CMD HubCreate ${HUBNAME} /PASSWORD:""

  # create a user
  vpncmd localhost:443 /SERVER /Hub:${HUBNAME} /CMD UserCreate server /GROUP:"" /REALNAME:"" /NOTE:""
  # set user password
  vpncmd localhost:443 /SERVER /Hub:${HUBNAME} /CMD UserPasswordSet server /PASSWORD:server

  # save all pids to the vpn pid
  pgrep vpnserver > /var/run/vpn.pid

  vpnclient execsvc &
  client_pid=$!

  errcount=0
  while ! vpncmd localhost /CLIENT /CMD About > /dev/null 2>&1; do
    sleep 1
    ((errcount++))
    if [[ ${errcount} > 5 ]]; then
      echo "Softether VPN client did not came up in time" 1>&2
      exit 1
    fi
  done

  # create a network interface
  vpncmd localhost /CLIENT /CMD NicCreate ether0

  # create a vpn profile that connects to the server
  vpncmd localhost /CLIENT /CMD AccountCreate account0 /SERVER:localhost:443 /HUB:${HUBNAME} /USERNAME:server /NICNAME:ether0
  vpncmd localhost /CLIENT /CMD AccountPassword account0 /TYPE:standard /PASSWORD:server

  # Connect to the VPN
  vpncmd localhost /CLIENT /CMD AccountConnect account0

  IFS=$'/' read -d '' -r -a subnetparts <<< "${SUBNET}" || true
  base_net=${subnetparts[0]}
  net_prefix=${subnetparts[1]}

  ip=$(helper::add_to_ip ${base_net} 1)

  ip addr add dev ${IFACE} ${ip}/${net_prefix}

  # run the endpoint
  rest-endpoint --script "/scripts/rest-endpoint-handler.sh" &
  rest_pid=$!

  if [[ "${FOREGROUND:-n}" == "y" ]]; then
    while true; do
      # TODO check if processes haven't exited
      sleep 1
    done
  fi
}


function setupClient {
  if [[ -z "${ENDPOINT}" ]]; then
    echo "No endpoint specified for the VPN client (missing --endpoint arg)" 1>&2
    exit 1
  fi

  vpnclient execsvc &
  client_pid=$!
  echo ${client_pid} > /var/run/vpn.pid

  errcount=0
  while ! vpncmd localhost /CLIENT /CMD About > /dev/null 2>&1; do
    sleep 1
    ((errcount++))
    if [[ ${errcount} > 5 ]]; then
      echo "Softether VPN client did not came up in time" 1>&2
      exit 1
    fi
  done

  if [[ -z ${INSECURE:-} ]]; then
     prefix="http://"
  else
     prefix="https://"
  fi

  name=$(hostname)
  result=$(wget -O - -q "${prefix}${ENDPOINT}/associate-peer/${name}")

  if [[ $? == 0 && ! -z ${result} ]]; then

    IFS=$'\n' read -d '' -r -a lines <<< "${result}" || true
    hub=${lines[0]}
    password=${lines[1]}
    clientip=${lines[2]}
    base_net=${lines[3]}
    net_prefix=${lines[4]}

    IFS=':' read -ra hostname_parts <<< "${ENDPOINT}"
    VPN_SERVER="${hostname_parts[0]}"

    # create a network interface
    vpncmd localhost /CLIENT /CMD NicCreate ether0

    # create a vpn profile that connects to the server
    vpncmd localhost /CLIENT /CMD AccountCreate account0 /SERVER:${VPN_SERVER}:443 /HUB:${hub} /USERNAME:${name} /NICNAME:ether0

    vpncmd localhost /CLIENT /CMD AccountPassword account0 /TYPE:standard /PASSWORD:${password}

    # Connect to the VPN
    vpncmd localhost /CLIENT /CMD AccountConnect account0

    ip addr add dev ${IFACE} ${clientip}/${net_prefix}

    # save all pids to the vpn pid
    pgrep vpnclient > /var/run/vpn.pid

    if [[ "${FOREGROUND:-n}" == "y" ]]; then
      while true; do
        # todo check if pids don't exit
        sleep 1
      done
    fi

  else
    echo "Unable to connect to remote endpoint" 1>&2
    exit 1
  fi
}


parseArgs "$@"
IFACE=vpn_ether0


if [[ ${SERVER} == "y" ]]; then
   setupServer
else
   setupClient
fi
