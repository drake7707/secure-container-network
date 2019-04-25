#!/bin/bash

docker run -d --cap-add=NET_ADMIN --device /dev/net/tun drake7707/softether --endpoint 10.2.0.23:4443 --foreground
