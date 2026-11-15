# syntax=docker/dockerfile:1
ARG NGINX_VERSION=1.30.6

FROM nginx:${NGINX_VERSION}-alpine AS module-builder

ARG NGINX_VERSION

RUN apk add --no-cache \
        build-base \
        ca-certificates \
        curl \
        libmaxminddb-dev \
        linux-headers \
        openssl-dev \
        pcre2-dev \
        zlib-dev

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

FROM nginx:${NGINX_VERSION}-alpine

ARG NGINX_VERSION

LABEL org.opencontainers.image.title="lzocateli/nginx" \
  org.opencontainers.image.description="NGINX estável com suporte ao módulo headers-more para configurações legadas via bind mount." \
  org.opencontainers.image.source="https://github.com/lzocateli/containers" \
  org.opencontainers.image.documentation="https://github.com/lzocateli/containers/tree/main/nginx" \
  org.opencontainers.image.url="https://github.com/lzocateli/containers/tree/main/nginx" \
  org.opencontainers.image.version="${NGINX_VERSION}-alpine-v1"

RUN mkdir -p /etc/nginx/modules-enabled

# Pacotes do Alpine atualizados no build, menos o nginx e os módulos dele: os módulos dinâmicos abaixo são compilados
# contra esta versão exata.
RUN apk add --no-cache libmaxminddb \
    && apk upgrade --no-cache $(apk info | grep -vE '^nginx($|-)')

COPY --from=module-builder /tmp/nginx-${NGINX_VERSION}/objs/ngx_http_headers_more_filter_module.so /etc/nginx/modules/ngx_http_headers_more_filter_module.so
COPY --from=module-builder /tmp/nginx-${NGINX_VERSION}/objs/ngx_http_geoip2_module.so /etc/nginx/modules/ngx_http_geoip2_module.so

RUN printf 'load_module modules/ngx_http_headers_more_filter_module.so;\n' > /etc/nginx/modules-enabled/50-mod-http-headers-more-filter.conf
RUN printf 'load_module modules/ngx_http_geoip2_module.so;\n' > /etc/nginx/modules-enabled/51-mod-http-geoip2.conf

COPY html /usr/share/nginx/html
COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./custom-error.locations /etc/nginx/conf.d/

RUN ln -s -f /usr/share/nginx/html/custom-error-page/custom-error-page.html /usr/share/nginx/html/index.html
