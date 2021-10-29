FROM ubuntu:latest

COPY LICENSE README.md /

COPY entrypoint.sh /entrypoint.sh

RUN apt-get update -y && apt install -y openssl wget git unzip curl bash ca-certificates 

ENTRYPOINT ["/entrypoint.sh"]
