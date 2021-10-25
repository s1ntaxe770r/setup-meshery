FROM alpine:3.10

COPY LICENSE README.md /

COPY action.sh /action.sh

ENTRYPOINT ["/action.sh"]