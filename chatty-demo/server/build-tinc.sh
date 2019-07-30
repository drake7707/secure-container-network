#!/bin/sh

 docker build -t drake7707/tinc-server-chatty-test --build-arg IMAGE=drake7707/tinc .
 docker push drake7707/tinc-server-chatty-test
