#!/bin/bash

docker run -d --cap-add=NET_ADMIN --device /dev/net/tun drake7707/wireguard-go --endpoint 10.2.0.114:51820 --foreground
