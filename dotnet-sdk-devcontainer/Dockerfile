ARG BUILDPLATFORM=linux/amd64

FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:8.0.303-jammy

RUN apt update -y && apt upgrade -y \
 && apt install -y \
    gpg \
    jq \
    lsb-release \
    fzf \
    zip unzip \
    python3-pip \
    net-tools iputils-ping curl wget \
    libxml2-dev

RUN apt-get clean && rm -rf /var/lib/apt/lists/*

RUN pip install --upgrade pip

ARG TZ=America/Sao_Paulo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ >/etc/timezone

RUN apt install -y zsh zsh-autosuggestions
RUN echo "export PATH=$PATH:/root/.local/bin" >> ~/.zshrc \
 && echo "plugins=(zsh-autosuggestions)" >> ~/.zshrc \
 && echo 'HISTFILE=~/.zsh_history' >> ~/.zshrc


RUN sh -c "$(curl -fsSL https://ohmyposh.dev/install.sh)"
