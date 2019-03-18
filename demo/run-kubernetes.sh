#!/bin/bash

set -x

action=${1:-run}
N=${2:-5}
runname=${3:-untitled}

clientpath="/proj/wall2-ilabt-iminds-be/dkkerkho/secure-container-network/demo/data/${runname}/client"
image="drake7707/wireguard-client-test"
endpoint="10.2.0.23:51820"
replicas=${N}


if [[ ${action} == "run" || ${action} == "clean" ]]; then


  kubectl delete deployment loadtestclient


  docker rm -f wireguard-rest-server
  docker rm -f wireguard-server

  #echo "Clean done, press any key to continue"
  #read

fi

if [[ ${action} == "run" ]]; then

  mkdir -p $(pwd)/data/${runname}/server
  mkdir -p ${clientpath}

  # set up vpn server
  docker run \
  -d --name wireguard-server \
  -p 51820:51820/tcp -p 51820:51820/udp \
  --cap-add=NET_ADMIN --device /dev/net/tun \
  -v $(pwd)/data/${runname}/server:/data \
  drake7707/wireguard-go --server --subnet 6.0.0.0/8 --foreground

  # set up demo server
  docker run \
  -d --name wireguard-rest-server \
  --net=container:wireguard-server \
  drake7707/wireguard-server-test

  tmpfile=$(mktemp /tmp/kube-deployment.XXXXXX)
  cat "./deployment.yaml.templ" > ${tmpfile}
  sed -i "s/{{replicas}}/${replicas}/" "${tmpfile}"
  sed -i "s#{{image}}#${image}#" "${tmpfile}"
  sed -i "s#{{clientpath}}#${clientpath}#" "${tmpfile}"
  sed -i "s/{{endpoint}}/${endpoint}/" "${tmpfile}"
  sed -i "s/{{runname}}/${runname}/" "${tmpfile}"

  kubectl apply -f ${tmpfile}
fi
