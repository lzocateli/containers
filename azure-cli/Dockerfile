ARG AZ_VERSION=2.59.0-amd64

FROM mcr.microsoft.com/azure-cli:$AZ_VERSION AS buildbase

RUN apk update \
    && apk upgrade \
    && apk add \
    jq
