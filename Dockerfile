FROM alpine:latest

RUN apk add bind-tools curl haproxy

COPY manageproxy.sh /
COPY basefile /

ENTRYPOINT ["/manageproxy.sh"]
