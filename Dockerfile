FROM alpine:3.10

COPY LICENSE README.md /

COPY ./action.sh /action.sh

RUN apk add --no-cache bash


ENTRYPOINT ["/action.sh"]