ARG NGINX_VERSION=1.27.2-bookworm-perl

FROM nginx:$NGINX_VERSION AS buildbase

RUN apt update -y \
    && apt upgrade -y

RUN apt install -y wget nano net-tools apt-utils iputils-ping telnet
RUN ls -lha /etc/nginx/modules-enabled/

# RUN mkdir -p /etc/apt/keyrings
# RUN wget -qO - https://nginx.org/packages/keys/nginx_signing.key | tee /etc/apt/keyrings/nginx_signing.key

# RUN echo "deb [signed-by=/etc/apt/keyrings/nginx_signing.key] https://nginx.org/packages/debian bookworm nginx" | tee /etc/apt/sources.list.d/nginx.list

# RUN apt update -y
# RUN apt install nginx-module-*

COPY html /usr/share/nginx/html
COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./configs/custom-error.locations /etc/nginx/conf.d/

RUN ln -s -f /usr/share/nginx/html/custom-error-page/custom-error-page.html /usr/share/nginx/html/index.html 
