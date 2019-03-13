#!/bin/bash
#set -x

/scripts/run-container.sh --endpoint 10.2.0.78:51820

function curl_time {
   local timestamp=$(date +%s)

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
