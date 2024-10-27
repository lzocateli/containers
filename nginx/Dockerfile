ARG NGINX_VERSION=1.27.2-bookworm

FROM nginx:$NGINX_VERSION AS buildbase

RUN apt update -y \
    && apt upgrade -y

RUN apt install -y \
    nginx-extras \
    nano
    
    # net-tools \
    # telnet
    
    # iputils-ping \
COPY html /usr/share/nginx/html
COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./configs/custom-error.locations /etc/nginx/conf.d/

RUN ln -s -f /usr/share/nginx/html/custom-error-page/custom-error-page.html /usr/share/nginx/html/index.html 
