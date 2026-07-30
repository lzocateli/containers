# syntax=docker/dockerfile:1
ARG NGINX_VERSION=1.28.0

FROM nginx:${NGINX_VERSION}-bookworm AS module-builder

ARG NGINX_VERSION

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        libmaxminddb-dev \
        libpcre2-dev \
        libssl-dev \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

RUN curl -fsSLO "http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" \
    && tar -xzf "nginx-${NGINX_VERSION}.tar.gz" \
    && curl -fsSL "https://github.com/openresty/headers-more-nginx-module/archive/refs/tags/v0.38.tar.gz" -o headers-more-nginx-module-v0.38.tar.gz \
    && tar -xzf headers-more-nginx-module-v0.38.tar.gz \
    && curl -fsSL "https://github.com/leev/ngx_http_geoip2_module/archive/refs/tags/3.4.tar.gz" -o ngx-http-geoip2-module-3.4.tar.gz \
    && tar -xzf ngx-http-geoip2-module-3.4.tar.gz

RUN cd "nginx-${NGINX_VERSION}" \
    && ./configure --with-compat \
        --add-dynamic-module=../headers-more-nginx-module-0.38 \
        --add-dynamic-module=../ngx_http_geoip2_module-3.4 \
    && make modules

FROM nginx:${NGINX_VERSION}-bookworm

ARG NGINX_VERSION

LABEL org.opencontainers.image.title="lzocateli/nginx" \
  org.opencontainers.image.description="NGINX estável com suporte ao módulo headers-more para configurações legadas via bind mount." \
  org.opencontainers.image.source="https://github.com/lzocateli/containers" \
  org.opencontainers.image.documentation="https://github.com/lzocateli/containers/tree/main/nginx" \
  org.opencontainers.image.url="https://github.com/lzocateli/containers/tree/main/nginx" \
  org.opencontainers.image.version="${NGINX_VERSION}-bookworm"

RUN mkdir -p /etc/nginx/modules-enabled

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends libmaxminddb0 \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --only-upgrade \
        libgnutls30 \
        libssl3 \
        openssl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=module-builder /tmp/nginx-${NGINX_VERSION}/objs/ngx_http_headers_more_filter_module.so /etc/nginx/modules/ngx_http_headers_more_filter_module.so
COPY --from=module-builder /tmp/nginx-${NGINX_VERSION}/objs/ngx_http_geoip2_module.so /etc/nginx/modules/ngx_http_geoip2_module.so

RUN printf 'load_module modules/ngx_http_headers_more_filter_module.so;\n' > /etc/nginx/modules-enabled/50-mod-http-headers-more-filter.conf
RUN printf 'load_module modules/ngx_http_geoip2_module.so;\n' > /etc/nginx/modules-enabled/51-mod-http-geoip2.conf

COPY html /usr/share/nginx/html
COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./custom-error.locations /etc/nginx/conf.d/

RUN ln -s -f /usr/share/nginx/html/custom-error-page/custom-error-page.html /usr/share/nginx/html/index.html
