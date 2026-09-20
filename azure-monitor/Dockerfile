FROM python:3.12-bookworm

ARG IMAGE_VERSION=3.12-bookworm


LABEL org.opencontainers.image.title="azure-monitor" \
    org.opencontainers.image.description="Azure Monitor Agent com Fluent Bit para coleta de logs de aplicações" \
    org.opencontainers.image.source="https://github.com/lzocateli/containers" \
    org.opencontainers.image.documentation="https://github.com/lzocateli/containers/tree/main/azure-monitor" \
    org.opencontainers.image.url="https://github.com/lzocateli/containers/tree/main/azure-monitor" \
    org.opencontainers.image.version="${IMAGE_VERSION}"

RUN apt-get update -y && apt-get upgrade -y \
    && apt install -y \
    gpg \
    jq \
    wget \
    curl \
    lsb-release \
    unzip \
    python3-pip \
    gnupg \
    sudo \
    apt-transport-https \
    && rm -rf /var/lib/apt/lists/*

RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list \
    && apt update -y && apt install -y terraform

RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

RUN pip install --upgrade pip

ARG TZ=America/Sao_Paulo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ >/etc/timezone

RUN apt install -y zsh zsh-autosuggestions
RUN echo "plugins=(zsh-autosuggestions)" >> ~/.zshrc \
    && echo 'HISTFILE=~/.zsh_history' >> ~/.zshrc


RUN sh -c "$(curl -fsSL https://ohmyposh.dev/install.sh)"

COPY start.sh /usr/local/bin/azure-monitor-entrypoint
RUN chmod 0755 /usr/local/bin/azure-monitor-entrypoint

ENTRYPOINT ["/usr/local/bin/azure-monitor-entrypoint"]
CMD ["/opt/microsoft/omsagent/bin/service_control", "start"]
