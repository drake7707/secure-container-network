FROM golang:alpine

RUN apk update && apk add --no-cache libc6-compat git make gcc musl-dev libmnl-dev bash

COPY ./rest-endpoint /rest-endpoint
RUN cd /rest-endpoint && ./build.sh


FROM alpine:latest
RUN apk add --no-cache bash openvpn easy-rsa wget
COPY --from=0 /rest-endpoint/output/rest-endpoint /usr/local/bin/rest-endpoint

COPY ./scripts /scripts

VOLUME /data

EXPOSE 1194 1194/udp

ENTRYPOINT [ "/scripts/run-container.sh" ]
