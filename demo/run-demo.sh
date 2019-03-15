#!/bin/bash

action=${1:-run}
N=${2:-100}
name=${3:-untitled}

if [[ ${action} == "run" || ${action} == "clean" ]]; then


  pids=""
  for ((i=0;i<N;i++)); do
   docker rm -f wireguard-client-$i &
   pids="$pids $!"
  done

  for pid in $pids; do
    wait $pid
  done

  docker rm -f wireguard-rest-server
  docker rm -f wireguard-server

  #echo "Clean done, press any key to continue"
  #read

fi

if [[ ${action} == "run" ]]; then

  mkdir -p $(pwd)/data/run-${name}/server
  mkdir -p $(pwd)/data/run-${name}/client

  # set up vpn server
  docker run \
  -d --name wireguard-server \
  -p 51820:51820/tcp -p 51820:51820/udp \
  --cap-add=NET_ADMIN --device /dev/net/tun \
  -v $(pwd)/data/run-${name}/server:/data \
  drake7707/wireguard-go --server --subnet 6.0.0.0/8 --foreground

  # set up demo server
  docker run \
  -d --name wireguard-rest-server \
  --net=container:wireguard-server \
  drake7707/wireguard-server-test

  pids=""
  for ((i=0;i<N;i++)); do
   docker run -d --name wireguard-client-$i --hostname wireguard-client-$i \
 	      --ulimit nofile=98304:98304 \
              -v $(pwd)/data/run-${name}/client:/results \
              --cap-add=NET_ADMIN --device /dev/net/tun \
              drake7707/wireguard-client-test &
   pids="$pids $!"
  done

  for pid in $pids; do
    wait $pid
  done
fi
