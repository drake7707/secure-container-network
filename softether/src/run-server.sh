#!/bin/bash

docker run -d -p 443:443/tcp -p 4443:4443/tcp --cap-add=NET_ADMIN --device /dev/net/tun drake7707/softether --server --subnet 6.0.0.0/8 --foreground

#docker run -it -p 443:443/tcp -p 4443:4443/tcp --cap-add=NET_ADMIN --device /dev/net/tun --entrypoint=/bin/sh drake7707/softether
