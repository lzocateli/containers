# syntax=docker/dockerfile:1

FROM mcr.microsoft.com/dotnet/aspnet@sha256:bc0d6653979efba491ab3d6f589d691f96c309c3c3ef81325efa6978e7b7f242 AS runtime

ARG IMAGE_VERSION="10.0.15-noble-v1"

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
