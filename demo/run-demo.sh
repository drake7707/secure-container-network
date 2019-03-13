#!/bin/bash


N=2

docker rm -f wireguard-rest-server
docker rm -f wireguard-server

for ((i=0;i<N;i++)); do
   docker rm -f wireguard-client-$i
done


echo "Clean done, press any key to continue"
read

mkdir -p $(pwd)/data/server
mkdir -p $(pwd)/data/client

# set up vpn server
docker run \
-d --name wireguard-server \
-p 51820:51820/tcp -p 51820:51820/udp \
--cap-add=NET_ADMIN --device /dev/net/tun \
-v $(pwd)/data/server:/data \
drake7707/wireguard-go --server --subnet 6.0.0.0/8 --foreground

# set up demo server
docker run \
-d --name wireguard-rest-server \
--net=container:wireguard-server \
drake7707/wireguard-server-test




for ((i=0;i<N;i++)); do
   docker run -d --name wireguard-client-$i --hostname wireguard-client-$i \
              -v $(pwd)/data/client:/results \
              --cap-add=NET_ADMIN --device /dev/net/tun \
              drake7707/wireguard-client-test &
done

