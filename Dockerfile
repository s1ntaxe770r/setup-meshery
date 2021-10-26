FROM golang:stretch

COPY LICENSE README.md /

COPY entrypoint.sh /entrypoint.sh

RUN apt-get update -y && apt install -y openssl curl bash ca-certificates 

RUN curl -fsSL https://get.docker.com -o install-docker.sh && chmod +x install-docker.sh && ./install-docker.sh 

ENTRYPOINT ["/entrypoint.sh"]
