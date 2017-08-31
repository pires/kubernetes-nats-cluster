FROM alpine:3.6

LABEL maintainer=pjpires@gmail.com

EXPOSE 4222 6222 8222

RUN apk update && \
    apk add ca-certificates && \
    rm -rf /var/cache/apk/*

COPY artifacts/gnatsd /gnatsd
COPY artifacts/route_checker /route_checker
COPY run.sh /run.sh

CMD [ "/run.sh" ]
