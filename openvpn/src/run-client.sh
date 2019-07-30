#!/bin/bash

docker run -d --cap-add=NET_ADMIN --device /dev/net/tun drake7707/openvpn --endpoint 10.2.0.40:1194 --foreground
