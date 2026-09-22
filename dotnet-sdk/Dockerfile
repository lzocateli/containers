# syntax=docker/dockerfile:1

FROM mcr.microsoft.com/dotnet/sdk@sha256:2fa828c68761b1b8c23d7662dc134421b9d3b59fe1425fdbc80804e390cdb24d AS runtime

ARG IMAGE_VERSION="10.0.400-noble"

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
