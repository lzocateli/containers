# syntax=docker/dockerfile:1

FROM mcr.microsoft.com/dotnet/sdk@sha256:0d99ebf1ccad15037b5c98c9fe8979d6b8dbac23812feae2277a0b277b5c5ffa AS runtime

ARG IMAGE_VERSION="10.0.402-noble-v1"

LABEL org.opencontainers.image.title="lzocateli/dotnet-sdk" \
	org.opencontainers.image.description=".NET 10 SDK com ferramentas de diagnóstico de rede para builds em contêineres." \
	org.opencontainers.image.source="https://github.com/lzocateli/containers" \
	org.opencontainers.image.documentation="https://github.com/lzocateli/containers/tree/main/dotnet-sdk" \
	org.opencontainers.image.url="https://github.com/lzocateli/containers/tree/main/dotnet-sdk" \
	org.opencontainers.image.version="${IMAGE_VERSION}"

RUN apt-get update \
	&& apt-get install --yes --no-install-recommends \
	curl \
	iputils-ping \
	libxml2-dev \
	net-tools \
	telnet \
	&& rm -rf /var/lib/apt/lists/* \
	&& install --directory --owner="${APP_UID}" --group="${APP_UID}" /workspace

WORKDIR /workspace

USER ${APP_UID}:${APP_UID}

CMD ["dotnet", "--info"]
