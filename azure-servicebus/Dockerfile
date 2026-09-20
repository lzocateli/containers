# Azure Service Bus Emulator — pinned base image + fallback topology.
#
# This image intentionally does nothing beyond pinning the base by digest and baking in a minimal
# fallback Config.json (used only when the container runs without a config bind mount). There are no
# package installs and no entrypoint override, so no proxy build-args are needed here (unlike
# containers/cloudbeaver, which downloads a JDBC driver at build time).
#
# Digest resolved via:
#   docker inspect --format '{{index .RepoDigests 0}}' mcr.microsoft.com/azure-messaging/servicebus-emulator:latest
ARG IMAGE_VERSION=servicebus-emulator-digest-2026-09

FROM mcr.microsoft.com/azure-messaging/servicebus-emulator@sha256:5a96d893b245031740f7d46e0fe5ff282d24b78c4b7d761dd57590f3f010a9b3

ARG IMAGE_VERSION

LABEL org.opencontainers.image.title="azure-servicebus" \
      org.opencontainers.image.description="Emulador do Azure Service Bus com topologia mínima para desenvolvimento local" \
      org.opencontainers.image.source="https://github.com/lzocateli/containers" \
      org.opencontainers.image.documentation="https://github.com/lzocateli/containers/tree/main/azure-servicebus" \
      org.opencontainers.image.url="https://github.com/lzocateli/containers/tree/main/azure-servicebus" \
      org.opencontainers.image.version="${IMAGE_VERSION}"

COPY Config.default.json /ServiceBus_Emulator/ConfigFiles/Config.json
