#!/bin/sh

 docker build -t drake7707/zerotier-client-chatty-test --build-arg IMAGE=drake7707/zerotier .
 docker push drake7707/zerotier-client-chatty-test
