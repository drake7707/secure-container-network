#!/bin/bash

docker run -d -p 51820:51820/udp --cap-add=NET_ADMIN --device /dev/net/tun drake7707/wireguard-go -f wg0
