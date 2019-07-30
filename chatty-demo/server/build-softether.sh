#!/bin/sh

 docker build -t drake7707/softether-server-chatty-test --build-arg IMAGE=drake7707/softether .
 docker push  drake7707/softether-server-chatty-test
