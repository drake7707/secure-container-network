#!/bin/bash

curl -s -X GET --header "X-ZT1-Auth: $(cat /var/lib/zerotier-one/authtoken.secret)" 'http://localhost:9993/controller/network/' | jq ".[0]" | sed 's/"//g'

