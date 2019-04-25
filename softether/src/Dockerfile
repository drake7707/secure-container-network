FROM golang:alpine

RUN apk update && apk add --no-cache libc6-compat git make gcc musl-dev libmnl-dev bash

COPY ./rest-endpoint /rest-endpoint
RUN cd /rest-endpoint && ./build.sh


FROM alpine:edge

ENV LD_LIBRARY_PATH=/usr/local/lib64

RUN set -xe && apk --no-cache add openssl readline ncurses curl busybox-extras zlib && \
  apk --no-cache -t .build-deps add readline-dev openssl-dev ncurses-dev build-base cmake git zlib-dev && \
  git clone --depth 1 --recursive https://github.com/SoftEtherVPN/SoftEtherVPN.git /tmp/softether && export USE_MUSL=YES && \
  cd /tmp/softether && ./configure && make -C tmp && make -C tmp install && \
  cp /tmp/softether/build/libcedar.so /tmp/softether/build/libmayaqua.so /usr/lib && \
  rm -fr /tmp/softether && apk del --quiet --no-cache .build-deps && apk del --quiet --no-cache --purge && rm -rf /var/cache/apk/*

RUN apk add --no-cache bash

COPY --from=0 /rest-endpoint/output/rest-endpoint /usr/local/bin/rest-endpoint

#EXPOSE 	41421/udp \
#	443/tcp \
#	992/tcp \
#	1194/tcp \
#	1194/udp \
#	5555/tcp \
#	27088/udp \
#	52651/udp

EXPOSE 443/tcp 4443/tcp

COPY ./scripts /scripts

VOLUME /data

ENTRYPOINT [ "/scripts/run-container.sh" ]
