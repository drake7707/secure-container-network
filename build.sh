#!/bin/bash

cd rest-endpoint && ./build.sh

docker build -t drake7707/wireguard-go .
