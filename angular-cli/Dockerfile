FROM lzocateli/node:18.20.3-alpine

ARG ANGULAR_CLI_VERSION=17.3.8
ENV NG_CLI_ANALYTICS=false

RUN apk update \
  && apk add --update alpine-sdk python3 \
  && npm install -g @angular/cli@$ANGULAR_CLI_VERSION \
  && ng config --global cli.packageManager npm \
  && apk del alpine-sdk python3 \
  && rm -rf /tmp/* /var/cache/apk/* *.tar.gz ~/.npm \
  && npm cache clean --force \
  && sed -i -e "s/bin\/ash/bin\/sh/" /etc/passwd


EXPOSE 4200
