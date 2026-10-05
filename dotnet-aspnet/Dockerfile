# syntax=docker/dockerfile:1

FROM mcr.microsoft.com/dotnet/aspnet@sha256:222759b391a1aaf241166672c8f99b2d4ada452e7b5319f3c6e8f265a37b5ad4 AS runtime

ARG IMAGE_VERSION="10.0.11-noble"

LABEL org.opencontainers.image.title="lzocateli/dotnet-aspnet" \
	org.opencontainers.image.description="Runtime ASP.NET Core 10 em Ubuntu Noble para aplicações em contêineres produtivos." \
	org.opencontainers.image.source="https://github.com/lzocateli/containers" \
	org.opencontainers.image.documentation="https://github.com/lzocateli/containers/tree/main/dotnet-aspnet" \
	org.opencontainers.image.url="https://github.com/lzocateli/containers/tree/main/dotnet-aspnet" \
	org.opencontainers.image.version="${IMAGE_VERSION}"

RUN install --directory --owner="${APP_UID}" --group="${APP_UID}" /app

WORKDIR /app

EXPOSE 8080

USER ${APP_UID}:${APP_UID}

ENTRYPOINT ["dotnet"]
CMD ["--info"]
