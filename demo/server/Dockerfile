FROM alpine

RUN apk add --no-cache iproute2

COPY server /usr/local/bin

EXPOSE 1500

CMD "server"
