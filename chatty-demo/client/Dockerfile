ARG IMAGE

FROM $IMAGE

RUN apk --no-cache add curl

COPY ./run_test.sh /usr/local/bin/run_test

ENTRYPOINT [ "run_test" ]
