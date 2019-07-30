#!/bin/sh

 docker build -t drake7707/wireguard-server-chatty-test --build-arg IMAGE=drake7707/wireguard-go .
 docker push drake7707/wireguard-server-chatty-test
