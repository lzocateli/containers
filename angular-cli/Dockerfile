FROM lzocateli/node:18.20.3-alpine

ARG ANGULAR_CLI_VERSION=17.3.8
ENV NG_CLI_ANALYTICS=false

RUN apk update \
  && apk add --update alpine-sdk python3 \
  && yarn global add @angular/cli@$ANGULAR_CLI_VERSION \
  && ng config --global cli.packageManager yarn \
  && apk del alpine-sdk python3 \
  && rm -rf /tmp/* /var/cache/apk/* *.tar.gz ~/.npm \
  && npm cache clean --force \
  && yarn cache clean \
  && sed -i -e "s/bin\/ash/bin\/sh/" /etc/passwd

EXPOSE 4200

COPY docker-entrypoint.sh /usr/local/bin/

# CMD [ "ng" ]