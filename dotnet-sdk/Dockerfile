# syntax=docker/dockerfile:1

FROM mcr.microsoft.com/dotnet/sdk@sha256:65f3c7c6a25a239ab3e6719f2896147e7b68242ff2d8818dd70498bde6ef8bea AS runtime

ARG IMAGE_VERSION="10.0.403-noble-v1"

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
	# libbrotli1 da base tem a CVE-2026-111497 (HIGH); corrigida em 1.1.0-2ubuntu0.1.
	&& apt-get install --yes --no-install-recommends --only-upgrade libbrotli1 \
	&& rm -rf /var/lib/apt/lists/* \
	&& install --directory --owner="${APP_UID}" --group="${APP_UID}" /workspace

WORKDIR /workspace

USER ${APP_UID}:${APP_UID}

CMD ["dotnet", "--info"]
