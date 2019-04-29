#!/bin/bash

set -x

action=${1:-run}
N=${2:-5}
runname=${3:-untitled}

vpn=${4:-}

clientpath="/proj/wall2-ilabt-iminds-be/dkkerkho/secure-container-network/chatty-demo/data/${runname}/client"

modprobe sch_netem

if [[ ${vpn} == "wireguard" ]]; then
  vpn_image="drake7707/wireguard-go"
  port="51820"
  image="drake7707/wireguard-client-chatty-test"
  endpoint=10.2.0.23:${port}
elif [[ ${vpn} == "openvpn" ]]; then
  vpn_image="drake7707/openvpn"
  port="1194"
  image="drake7707/openvpn-client-chatty-test"
  endpoint=10.2.0.23:${port}
elif [[ ${vpn} == "zerotier" ]]; then
  vpn_image="drake7707/zerotier"
  port="9993"
  image="drake7707/zerotier-client-chatty-test"
  endpoint=10.2.0.23:${port}
elif [[ ${vpn} == "tinc" ]]; then
  vpn_image="drake7707/tinc"
  port="655"
  image="drake7707/tinc-client-chatty-test"
  endpoint=10.2.0.23:6555
elif [[ ${vpn} == "softether" ]]; then
  vpn_image="drake7707/softether"
  port="443"
  image="drake7707/softether-client-chatty-test"
  endpoint=10.2.0.23:4443
else
  echo "Invalid VPN specified" 1>&2
  exit 1
fi

replicas=${N}

if [[ ${action} == "run" || ${action} == "clean" ]]; then

  kubectl delete deployment chattytestclient

  docker rm -f ${vpn}-rest-server
  docker rm -f ${vpn}-server

  #echo "Clean done, press any key to continue"
  #read

fi

if [[ ${action} == "run" ]]; then

  mkdir -p $(pwd)/data/${runname}/server
  mkdir -p ${clientpath}

  additionalPorts=""
  if [[ ${vpn} == "tinc" ]]; then
    additionalPorts="-p 6555:6555"
  elif [[ ${vpn} == "softether" ]]; then
    additionalPorts="-p 4443:4443"
  fi

  # set up vpn server
  docker run \
  -d --name ${vpn}-server \
  -p ${port}:${port}/tcp -p ${port}:${port}/udp ${additionalPorts} \
  --cap-add=NET_ADMIN --device /dev/net/tun \
  -v $(pwd)/data/${runname}/server:/data \
  ${vpn_image} --server --subnet 6.0.0.0/16 --foreground

  # set up demo server
  docker run \
  -d --name ${vpn}-rest-server \
  --cap-add=NET_ADMIN \
  --net=container:${vpn}-server \
  drake7707/rest-server-test

  # if zerotier overwrite the endpoint with the network id
  if [[ ${vpn} == "zerotier" ]]; then
    endpoint=$(docker exec ${vpn}-server /scripts/get-network-id.sh)
    while [[ -z ${endpoint} || ${endpoint} == "null" ]]; do
      endpoint=$(docker exec ${vpn}-server /scripts/get-network-id.sh)
    done
  fi

  tmpfile=$(mktemp /tmp/kube-deployment.XXXXXX)
  cat "./deployment.yaml.templ" > ${tmpfile}
  sed -i "s/{{replicas}}/${replicas}/" "${tmpfile}"
  sed -i "s#{{image}}#${image}#" "${tmpfile}"
  sed -i "s#{{clientpath}}#${clientpath}#" "${tmpfile}"
  sed -i "s/{{endpoint}}/${endpoint}/" "${tmpfile}"
  sed -i "s/{{port}}/${port}/" "${tmpfile}"
  sed -i "s/{{runname}}/${runname}/" "${tmpfile}"

  kubectl apply -f ${tmpfile}
fi
