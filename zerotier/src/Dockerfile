FROM alpine:edge
RUN apk add --no-cache bash curl jq

RUN apk add zerotier-one --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing/

#RUN curl -L -o /tmp/zerotier-install.sh https://install.zerotier.com/ && bash /tmp/zerotier-install.sh

COPY ./scripts /scripts

VOLUME /data

EXPOSE 9993/udp

ENTRYPOINT [ "/scripts/run-container.sh" ]
