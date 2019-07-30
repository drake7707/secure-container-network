#!/bin/sh

 docker build -t drake7707/openvpn-server-chatty-test --build-arg IMAGE=drake7707/openvpn .
 docker push drake7707/openvpn-server-chatty-test
