FROM alpine:3.10

RUN apk --no-cache add curl jq

COPY entrypoint.sh /entrypoint.sh

RUN chmod a+x /entrypoint.sh

USER 2000:2000


ENTRYPOINT ["/entrypoint.sh"]
