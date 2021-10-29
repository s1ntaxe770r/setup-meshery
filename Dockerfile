FROM ubuntu:latest

COPY LICENSE README.md /

COPY entrypoint.sh /entrypoint.sh

RUN apt-get update -y && apt install -y openssl git unzip curl bash ca-certificates 

ENTRYPOINT ["/entrypoint.sh"]
