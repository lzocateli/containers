ARG IMAGE_VERSION=3.12.2-bookworm

FROM python:$IMAGE_VERSION AS buildbase

RUN apt update -y \
    && apt upgrade -y \
    && apt install -y
