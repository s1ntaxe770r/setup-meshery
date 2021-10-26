FROM golang:stretch

COPY LICENSE README.md /

COPY entrypoint.sh /entrypoint.sh

RUN apt-get update && apt install openssl curl bash ca-certificates 

RUN  apt install docker && systemctl start docker

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
