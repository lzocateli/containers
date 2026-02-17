FROM hugomods/hugo:exts-0.147.0

USER root

ENV TZ=America/Sao_Paulo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

WORKDIR /src

EXPOSE 1313
