ARG IMAGE_VERSION=2.59.0

FROM mcr.microsoft.com/azure-cli:$IMAGE_VERSION AS buildbase

RUN apk update \
    && apk upgrade \
    && apk add \
    jq
