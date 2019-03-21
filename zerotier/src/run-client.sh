#!/bin/bash

docker run -d --cap-add=NET_ADMIN --device /dev/net/tun drake7707/zerotier --endpoint $1 --foreground
#docker run -it --entrypoint=/bin/bash --cap-add=NET_ADMIN --device /dev/net/tun drake7707/zerotier
