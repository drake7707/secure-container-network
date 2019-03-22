#!/bin/bash

docker run -d --cap-add=NET_ADMIN  -p 655:655 -p 6555:6555 -p 655:655/udp --device /dev/net/tun drake7707/tinc --server --subnet 6.0.0.0/8 --foreground

#docker run -it --entrypoint=/bin/bash -p 655:655 -p 655:655/udp --cap-add=NET_ADMIN --device /dev/net/tun drake7707/tinc
#--server --subnet 6.0.0.0/8 --foreground
