FROM golang:alpine

RUN apk update && apk add --no-cache libc6-compat git make gcc musl-dev libmnl-dev bash

COPY ./rest-endpoint /rest-endpoint
RUN cd /rest-endpoint && ./build.sh




FROM alpine:edge
RUN apk add --no-cache bash tinc

COPY --from=0 /rest-endpoint/output/rest-endpoint /usr/local/bin/rest-endpoint

COPY ./scripts /scripts


EXPOSE 6555 655 655/udp

ENTRYPOINT [ "/scripts/run-container.sh" ]
