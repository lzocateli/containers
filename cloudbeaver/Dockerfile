ARG BUILDPLATFORM=linux/amd64
ARG CLOUDBEAVER_VERSION=26.1.4
ARG CLOUDBEAVER_DIGEST=sha256:e2a39623f2ab617c1c88e6edf92219dac24e876f2fa79b242113c03107ac6d5d

FROM --platform=$BUILDPLATFORM dbeaver/cloudbeaver:${CLOUDBEAVER_VERSION}@${CLOUDBEAVER_DIGEST}

ARG CLOUDBEAVER_VERSION
ARG DRIVER_VERSION=3.22.0
ARG DRIVER_SHA256=e4f22e29a5cb66a1a212604734f5ae3eb23a7f9cd0e1f79af92d8959b04822fb
ARG POSTGRES_DRIVER_VERSION=42.7.12
ARG POSTGRES_DRIVER_SHA256=31fbf6f06b2217fb51d5100cee51b22625cc81640da0679b47914e54c1e6377c
ARG JETTY_SECURITY_VERSION=12.1.10
ARG JETTY_SECURITY_SHA256=2f34b7895cec4e3547a1b52e12e7e92b3f3a110bf3c17637f8743ca3f4e42f0c
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
    && apt-get install -y --no-install-recommends iproute2 openssl libssl3t64 \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/cloudbeaver/drivers/snowflake

ADD https://repo.maven.apache.org/maven2/net/snowflake/snowflake-jdbc/${DRIVER_VERSION}/snowflake-jdbc-${DRIVER_VERSION}.jar \
    /opt/cloudbeaver/drivers/snowflake/

RUN echo "${DRIVER_SHA256}  /opt/cloudbeaver/drivers/snowflake/snowflake-jdbc-${DRIVER_VERSION}.jar" | sha256sum -c - \
    && chmod 644 /opt/cloudbeaver/drivers/snowflake/snowflake-jdbc-${DRIVER_VERSION}.jar

# Remove driver Databend herdado para reduzir superfície com dependências vulneráveis (Jackson 2.15.x).
RUN rm -rf /opt/cloudbeaver/drivers/databend

# Atualiza JDBC PostgreSQL para versão corrigida.
ADD https://repo.maven.apache.org/maven2/org/postgresql/postgresql/${POSTGRES_DRIVER_VERSION}/postgresql-${POSTGRES_DRIVER_VERSION}.jar \
    /opt/cloudbeaver/drivers/postgresql/

RUN echo "${POSTGRES_DRIVER_SHA256}  /opt/cloudbeaver/drivers/postgresql/postgresql-${POSTGRES_DRIVER_VERSION}.jar" | sha256sum -c - \
    && rm -f /opt/cloudbeaver/drivers/postgresql/postgresql-42.7.11.jar \
    && chmod 644 /opt/cloudbeaver/drivers/postgresql/postgresql-${POSTGRES_DRIVER_VERSION}.jar

# Atualiza Jetty Security para versão corrigida no bundle servidor.
ADD https://repo.maven.apache.org/maven2/org/eclipse/jetty/jetty-security/${JETTY_SECURITY_VERSION}/jetty-security-${JETTY_SECURITY_VERSION}.jar \
    /tmp/jetty-security-${JETTY_SECURITY_VERSION}.jar

RUN echo "${JETTY_SECURITY_SHA256}  /tmp/jetty-security-${JETTY_SECURITY_VERSION}.jar" | sha256sum -c - \
    && JETTY_LIB_DIR=$(find /opt/cloudbeaver/server/plugins -type d -path "*/org.jkiss.bundle.jetty.server_*/lib" | head -n 1) \
    && test -n "$JETTY_LIB_DIR" \
    && rm -f "$JETTY_LIB_DIR"/jetty-security-*.jar \
    && cp /tmp/jetty-security-${JETTY_SECURITY_VERSION}.jar "$JETTY_LIB_DIR/jetty-security-${JETTY_SECURITY_VERSION}.jar" \
    && rm -f /tmp/jetty-security-${JETTY_SECURITY_VERSION}.jar \
    && chmod 644 "$JETTY_LIB_DIR/jetty-security-${JETTY_SECURITY_VERSION}.jar"

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
