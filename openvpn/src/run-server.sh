#!/bin/bash

docker run -d -p 1194:1194/tcp -p 1194:1194/udp --cap-add=NET_ADMIN --device /dev/net/tun drake7707/openvpn --server --subnet 6.0.0.0/16 --foreground
