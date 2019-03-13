FROM drake7707/wireguard-go

RUN apk --no-cache add curl

COPY ./run_test.sh /usr/local/bin/run_test

ENTRYPOINT [ "run_test" ]
