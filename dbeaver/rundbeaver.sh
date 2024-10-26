#!/bin/bash

vardbeaver=~/cloudbeaver/workspace
mkdir -p $vardbeaver


podman rm cloudbeaver -f

    # --restart unless-stopped \
podman run -d \
    -p 8978:8978 \
    -v $vardbeaver:/opt/cloudbeaver/workspace \
    --name cloudbeaver \
    lzocateli/dbeaver:24.0.0
