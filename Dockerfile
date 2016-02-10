FROM janeczku/alpine-kubernetes:3.3
MAINTAINER pjpires@gmail.com

EXPOSE 4222 6222 8222

RUN apk add --update ca-certificates sudo

COPY artifacts/gnatsd /gnatsd
COPY run.sh /run.sh

CMD [ "/run.sh" ]
