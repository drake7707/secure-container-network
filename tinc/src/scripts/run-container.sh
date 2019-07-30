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

  net_name="test"

  IFS=$'/' read -d '' -r -a subnetparts <<< "${SUBNET}" || true
  base_net=${subnetparts[0]}
  net_prefix=${subnetparts[1]}

  ip=$(helper::add_to_ip ${base_net} 1)

  mkdir -p /etc/tinc/${net_name}/hosts

  # Server /etc/tinc/${net_name}/tinc.conf:
  (cat <<EOF
Name = server
Device = /dev/net/tun
AddressFamily = ipv4
EOF
  ) > /etc/tinc/${net_name}/tinc.conf

  # Server /etc/tinc/${net_name}/hosts/server
  (cat <<EOF
Subnet = ${ip}/32
EOF
  ) > /etc/tinc/${net_name}/hosts/server


  # Generate the public/private key pair for the network
  tincd -n ${net_name} -K 1024 <<EOF


EOF

  # run daemon
  tincd -n ${net_name} -d3 &
  pid=$!

  errcount=0
  while ! ip a show dev ${net_name} > /dev/null 2>&1; do
    sleep 1
    ((errcount++))
    if [[ ${errcount} > 5 ]]; then
      echo "Interface did not came up in time" 1>&2
      exit 1
    fi
  done

  # tinc spawns a child so it has a different pid
  pid=$(pgrep "tincd")
  echo ${pid} > /var/run/vpn.pid

  # configure network interface
  ip link set dev ${net_name} up
  ip a a ${ip}/${net_prefix} dev ${net_name}
  ip r r ${SUBNET} dev ${net_name}

  # run the endpoint
  rest-endpoint --script "/scripts/rest-endpoint-handler.sh" --port 6555 &
  rest_pid=$!

  if [[ "${FOREGROUND:-n}" == "y" ]]; then
    while true; do
      if ! ip a s ${net_name} > /dev/null 2>&1; then
        echo "Interface ${net_name} doesn't exist anymore, exiting"
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

  if [[ ! -d /data/pki ]]; then
    mkdir -p /data/pki
  fi

  if [[ -z ${INSECURE:-} ]]; then
     prefix="http://"
  else
     prefix="https://"
  fi

  hostname=$(hostname | base64 | tr -d '=')
  result=$(wget -O - -q "${prefix}${ENDPOINT}/associate-peer/${hostname}")

  if [[ $? == 0 && ! -z ${result} ]]; then

    IFS=$'\n' read -d '' -r -a lines <<< "${result}" || true

    net_name=${lines[0]}
    subnet=${lines[1]}
    server_file_base64=${lines[2]}
    client_file_base64=${lines[3]}
    client_private_key_base64=${lines[4]}

    mkdir -p /etc/tinc/${net_name}/hosts

    IFS=':' read -d '' -r -a endpointparts <<< "${ENDPOINT}" || true

    echo ${server_file_base64} | base64 -d > /etc/tinc/${net_name}/hosts/server.tmp
    echo "Address = ${endpointparts[0]}" > /etc/tinc/${net_name}/hosts/server
    cat /etc/tinc/${net_name}/hosts/server.tmp >> /etc/tinc/${net_name}/hosts/server
    rm  /etc/tinc/${net_name}/hosts/server.tmp

    echo ${client_file_base64} | base64 -d > /etc/tinc/${net_name}/hosts/${hostname}
    echo ${client_private_key_base64} | base64 -d > /etc/tinc/${net_name}/rsa_key.priv



    (cat <<EOF
Name = ${hostname}
Device = /dev/net/tun
AddressFamily = ipv4
ConnectTo = server
EOF
    ) > /etc/tinc/${net_name}/tinc.conf


    tincd -n ${net_name} -d3 &
    pid=$!

    errcount=0
    while ! ip a show dev ${net_name} > /dev/null 2>&1; do
      sleep 1
      ((errcount++))
      if [[ ${errcount} > 5 ]]; then
        echo "Interface did not came up in time" 1>&2
        exit 1
      fi
    done

    # tinc spawns a child so it has a different pid
    pid=$(pgrep "tincd")
    echo ${pid} > /var/run/vpn.pid

    ip=$(grep Subnet /etc/tinc/${net_name}/hosts/${hostname} | cut -d ' ' -f 3 | cut -d '/' -f 1)
    IFS=$'/' read -d '' -r -a subnetparts <<< "${subnet}" || true
    base_net=${subnetparts[0]}
    net_prefix=${subnetparts[1]}

    # configure network interface
    ip link set dev ${net_name} up
    ip a a ${ip}/${net_prefix} dev ${net_name}
    ip r r ${subnet} dev ${net_name}

    if [[ "${FOREGROUND:-n}" == "y" ]]; then
      while true; do

        if ! ip a s ${net_name} > /dev/null 2>&1; then
          echo "Interface ${net_name} doesn't exist anymore, exiting"
          exit 1
        fi

        sleep 1
      done
    fi

  else
    echo "Unable to connect to remote endpoint" 1>&2
    exit 1
  fi
}


parseArgs "$@"

if [[ ${SERVER} == "y" ]]; then
   setupServer
else
   setupClient
fi
