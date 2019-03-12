FROM golang:alpine

RUN apk update && apk add --no-cache libc6-compat git make gcc musl-dev libmnl-dev bash

RUN wget https://git.zx2c4.com/wireguard-go/snapshot/wireguard-go-0.0.20180613.tar.xz && \
    tar -xvf wireguard-go-0.0.20180613.tar.xz && \
    mv wireguard-go-0.0.20180613 wireguard-go && \
    cd wireguard-go && \
    mkdir .git && \
    make && \
    cp /go/wireguard-go/wireguard-go /usr/local/bin

RUN wget https://git.zx2c4.com/WireGuard/snapshot/WireGuard-0.0.20181018.tar.xz && \
    tar -xvf WireGuard-0.0.20181018.tar.xz && \
    mv WireGuard-0.0.20181018 Wireguard && \
    cd Wireguard/src && \
    make tools && \
    cp /go/Wireguard/src/tools/wg /usr/local/bin/wg && \
    cp /go/Wireguard/src/tools/wg-quick/linux.bash /usr/local/bin/wg-quick


FROM alpine:edge
RUN apk add --no-cache libmnl bash
COPY --from=0 /usr/local/bin /usr/local/bin
ENV WG_I_PREFER_BUGGY_USERSPACE_TO_POLISHED_KMOD=1

COPY ./scripts /scripts
COPY ./rest-endpoint/output/rest-endpoint /usr/local/bin/rest-endpoint

VOLUME /data

EXPOSE 51820 51820/udp

ENTRYPOINT [ "/scripts/run-container.sh" ]
