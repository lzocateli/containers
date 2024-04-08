ARG AZ_VERSION=2.59.0-amd64

FROM mcr.microsoft.com/azure-cli:$AZ_VERSION AS buildbase

RUN cat /etc/os-release

RUN apt update -y \
    && apt upgrade -y \
    && apt install -y \
    jq
