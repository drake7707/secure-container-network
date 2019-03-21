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

  mkdir -p /data

  if [[ ! -d "/data/pki" ]]; then
    mkdir -p /data/pki && cd /data

    /usr/share/easy-rsa/easyrsa --batch init-pki
    /usr/share/easy-rsa/easyrsa --req-cn=openvpn-server --batch build-ca nopass
    /usr/share/easy-rsa/easyrsa --keysize=${VPN_KEYSIZE:-1024} --batch gen-dh

    openvpn --genkey --secret /data/pki/ta.key

    /usr/share/easy-rsa/easyrsa --batch build-server-full "openvpn-server" nopass
    /usr/share/easy-rsa/easyrsa --batch gen-crl
  fi

  if [[ ! -f "/data/server.conf" ]]; then
    IFS='/' read -ra vpn_network_parts <<< "${SUBNET}"
    local vpn_subnet_mask="$(helper::netmask ${vpn_network_parts[1]})"

    export VPN_SUBNET="${vpn_network_parts[0]}"
    export VPN_SUBNETMASK="${vpn_subnet_mask}"
    /scripts/build_config.sh server
  fi

  mkdir -p /data/ccd

  extraArgs=""
  if [[ "${FOREGROUND:-n}" != "y" ]]; then
    extraArgs="--daemon"
  fi

  # run the endpoint
  rest-endpoint --script "/scripts/rest-endpoint-handler.sh" &
  rest_pid=$!

  openvpn --config /data/server.conf --client-config-dir /data/ccd ${extraArgs}
}


function setupClient {
  if [[ -z "${ENDPOINT}" ]]; then
    echo "No endpoint specified for the VPN client (missing --endpoint arg)" 1>&2
    exit 1
  fi

  if [[ -z ${INSECURE:-} ]]; then
     prefix="http://"
  else
     prefix="https://"
  fi

  name=$(hostname)
  wget -O - -q "${prefix}${ENDPOINT}/associate-peer/${name}" > /data/client.conf

  if [[ $? == 0 ]]; then

    IFS=':' read -ra hostname_parts <<< "${ENDPOINT}"
    VPN_SERVER="${hostname_parts[0]}"
    VPN_SERVER_PORT="${hostname_parts[1]:-1194}"

    sed -e "s/{{openvpn_server}}/${VPN_SERVER}/" \
        -e "s/{{openvpn_server_port}}/${VPN_SERVER_PORT}/" \
      /data/client.conf > /data/client.conf.tmp && \
    rm /data/client.conf && mv /data/client.conf.tmp /data/client.conf


    extraArgs=""
    if [[ "${FOREGROUND:-n}" != "y" ]]; then
      extraArgs="--daemon"
    fi

    openvpn --config "/data/client.conf" ${extraArgs}
    openvpnpid=$!

    if [[ "${FOREGROUND:-n}" == "y" ]]; then
      while true; do
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
