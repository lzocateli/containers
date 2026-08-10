ARG BUILDPLATFORM=linux/amd64
ARG CLOUDBEAVER_VERSION=26.0.3

FROM --platform=$BUILDPLATFORM dbeaver/cloudbeaver:${CLOUDBEAVER_VERSION}

ARG CLOUDBEAVER_VERSION
ARG DRIVER_VERSION=3.22.0
ARG Env_HttpProxy
ARG Env_HttpsProxy
ARG Env_NoProxy

ENV http_proxy=${Env_HttpProxy} \
    https_proxy=${Env_HttpsProxy} \
    HTTP_PROXY=${Env_HttpProxy} \
    HTTPS_PROXY=${Env_HttpsProxy} \
    no_proxy=${Env_NoProxy} \
    NO_PROXY=${Env_NoProxy}

USER root

# Instala iproute2 para permitir configuração de rotas no entrypoint.
# Se proxy estiver configurado, usa -o Acquire para passar com scheme http://.
# Se não houver proxy (ex: pipeline Azure), roda apt-get direto.
RUN if [ -n "${Env_HttpProxy}" ]; then \
        apt-get update -o Acquire::http::Proxy="http://${Env_HttpProxy}" \
                       -o Acquire::https::Proxy="http://${Env_HttpsProxy}"; \
    else \
        apt-get update; \
    fi \
    && apt-get install -y --no-install-recommends iproute2 \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/cloudbeaver/drivers/snowflake

ADD https://repo1.maven.org/maven2/net/snowflake/snowflake-jdbc/${DRIVER_VERSION}/snowflake-jdbc-${DRIVER_VERSION}.jar \
    /opt/cloudbeaver/drivers/snowflake/

RUN chmod 644 /opt/cloudbeaver/drivers/snowflake/snowflake-jdbc-${DRIVER_VERSION}.jar

# Registra o driver Snowflake como habilitado no CloudBeaver CE.
# Modifica o plugin.xml dentro do JAR de drivers base, adicionando snowflake.
COPY snowflake-driver-plugin.xml /tmp/snowflake-driver-plugin.xml
RUN DRIVERS_JAR=$(find /opt/cloudbeaver/server/plugins -name "io.cloudbeaver.resources.drivers.base_*.jar") && \
    cd /tmp && \
    jar xf "$DRIVERS_JAR" plugin.xml && \
    sed -i '/<\/plugin>/d' plugin.xml && \
    echo '' >> plugin.xml && \
    echo '    <!-- Snowflake driver registration (added by custom build) -->' >> plugin.xml && \
    echo '    <extension point="org.jkiss.dbeaver.resources">' >> plugin.xml && \
    echo '        <resource name="drivers/snowflake"/>' >> plugin.xml && \
    echo '    </extension>' >> plugin.xml && \
    echo '    <extension point="org.jkiss.dbeaver.product.bundles">' >> plugin.xml && \
    echo '        <bundle id="drivers.snowflake" label="Snowflake drivers"/>' >> plugin.xml && \
    echo '    </extension>' >> plugin.xml && \
    echo '    <extension point="io.cloudbeaver.driver">' >> plugin.xml && \
    echo '        <driver id="snowflake:snowflake_jdbc"/>' >> plugin.xml && \
    echo '    </extension>' >> plugin.xml && \
    echo '</plugin>' >> plugin.xml && \
    jar uf "$DRIVERS_JAR" plugin.xml && \
    rm -f /tmp/plugin.xml /tmp/snowflake-driver-plugin.xml

# Limpa variáveis de proxy para não vazar na imagem final
ENV http_proxy="" \
    https_proxy="" \
    HTTP_PROXY="" \
    HTTPS_PROXY="" \
    no_proxy="" \
    NO_PROXY=""

LABEL org.opencontainers.image.title="lzocateli/cloudbeaver" \
  org.opencontainers.image.description="CloudBeaver com driver JDBC do Snowflake pré-instalado." \
  org.opencontainers.image.source="https://github.com/lzocateli/containers" \
  org.opencontainers.image.documentation="https://github.com/lzocateli/containers/tree/main/cloudbeaver" \
  org.opencontainers.image.url="https://hub.docker.com/r/lzocateli/cloudbeaver" \
  org.opencontainers.image.version="${CLOUDBEAVER_VERSION}"

# Entrypoint wrapper: corrige permissões do workspace bind-montado antes de iniciar
# o servidor (necessário no Docker Desktop Windows — NTFS ACLs ignoram chmod do WSL).
# O entrypoint original da imagem base é ./launch-product.sh (relativo ao WORKDIR).
COPY entrypoint.sh /opt/cloudbeaver/custom-entrypoint.sh
RUN chmod +x /opt/cloudbeaver/custom-entrypoint.sh

EXPOSE 8978

ENTRYPOINT ["./custom-entrypoint.sh"]
