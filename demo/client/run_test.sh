#!/bin/bash
#set -x

/scripts/run-container.sh --endpoint 10.2.0.78:51820
if [[ $? != 0 ]]; then
  echo "Connection to VPN server was not set up correctly" 1>&2
  exit 1
fi

function curl_time {
   local timestamp=$(echo $(($(date +'%s * 1000 + %-N / 1000000'))))

   curl -f -s -o /dev/null -w "\
   namelookup:  %{time_namelookup};\
      connect:  %{time_connect};\
   appconnect:  %{time_appconnect};\
  pretransfer:  %{time_pretransfer};\
     redirect:  %{time_redirect};\
starttransfer:  %{time_starttransfer};\
        total:  %{time_total};" "$@"

    if [[ $? != 0 ]]; then
      echo "failed;${timestamp}"
    else
      echo "ok;${timestamp}"
    fi
}

while true; do
   curl_time "http://6.0.0.1:1500/test" >> /results/$(hostname).csv
   sleep 0.25
done
