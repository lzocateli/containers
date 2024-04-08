ARG AZ_VERSION=2.59.0

FROM mcr.microsoft.com/azure-cli:$AZ_VERSION AS buildbase

RUN apt update -y \
    && apt upgrade -y \
    && apt install -y \
    jq
