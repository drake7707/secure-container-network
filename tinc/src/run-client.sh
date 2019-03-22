#!/bin/bash

#docker run -d --cap-add=NET_ADMIN --device /dev/net/tun drake7707/tinc --endpoint $1 --foreground
docker run -it --hostname=bG9hZHRlc3RjbGllbnQtNTc3ZmI4NDk1NC1hYmxhaAo --entrypoint=/bin/bash --cap-add=NET_ADMIN --device /dev/net/tun drake7707/tinc
