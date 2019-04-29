#!/bin/sh

 docker build -t drake7707/wireguard-client-chatty-test --build-arg IMAGE=drake7707/wireguard-go .
 docker push drake7707/wireguard-client-chatty-test
