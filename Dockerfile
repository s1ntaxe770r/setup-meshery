FROM golang:alpine3.14

COPY LICENSE README.md /

COPY entrypoint.sh /entrypoint.sh

RUN apk add --no-cache bash

RUN apk add --no-cache curl

RUN apk add -U ca-certificates 

RUN apk add  --no-cache openssl openrc


RUN  apk --no-cache add --repository http://dl-cdn.alpinelinux.org/alpine/edge/main libseccomp
RUN  apk --no-cache add --repository http://dl-cdn.alpinelinux.org/alpine/edge/community docker
RUN  apk update && rc-update add docker boot 
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]