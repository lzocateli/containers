# Imagem multifuncional para automação, IaC e fluxo de conteúdo.
# Parâmetros de build, exemplos de uso e contrato da imagem:
# veja README.md desta pasta.

ARG BASE_IMAGE=nvidia/cuda:12.6.3-cudnn-runtime-ubuntu24.04
ARG NODE_VERSION=24.15.0
ARG TERRAFORM_VERSION=1.15.8

FROM node:${NODE_VERSION}-bookworm AS node-runtime
FROM hashicorp/terraform:${TERRAFORM_VERSION} AS terraform-runtime

FROM ${BASE_IMAGE}

# ---- Re-declara ARGs após FROM (necessário para uso nos RUN abaixo) ---------
ARG BASE_IMAGE=nvidia/cuda:12.6.3-cudnn-runtime-ubuntu24.04
ARG NODE_VERSION=24.15.0
ARG NPM_VERSION=12.0.2
ARG TERRAFORM_VERSION=1.15.8
ARG INSTALL_ML=false
ARG INSTALL_GOOGLE=true
ARG GH_VERSION=2.92.0
ARG SQLCMD_VERSION=1.10.0
ARG IMAGE_VERSION=dev

# ---- Proxy corporativo (opcional) -------------------------------------------
ARG Env_HttpProxy=
ARG Env_NoProxy=
ENV HTTP_PROXY=${Env_HttpProxy:+http://${Env_HttpProxy}} \
    HTTPS_PROXY=${Env_HttpProxy:+http://${Env_HttpProxy}} \
    NO_PROXY=${Env_NoProxy} \
    http_proxy=${Env_HttpProxy:+http://${Env_HttpProxy}} \
    https_proxy=${Env_HttpProxy:+http://${Env_HttpProxy}} \
    no_proxy=${Env_NoProxy}

ARG TZ=America/Sao_Paulo
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=${TZ} \
    PATH="/opt/venv/bin:/root/.local/bin:${PATH}" \
    UV_LINK_MODE=copy \
    UV_PROJECT_ENVIRONMENT=/opt/venv

LABEL org.opencontainers.image.title="devops" \
    org.opencontainers.image.description="Imagem multifuncional com Python, Azure CLI, Terraform 1.15.8, Ansible, GitHub CLI, Node.js 24 LTS/Marp e ferramentas opcionais de ML" \
    org.opencontainers.image.source="https://github.com/lzocateli/containers" \
    org.opencontainers.image.documentation="https://github.com/lzocateli/containers/tree/main/devops" \
    org.opencontainers.image.url="https://github.com/lzocateli/containers/tree/main/devops" \
    org.opencontainers.image.version="${IMAGE_VERSION}"

# Nota: variáveis NVIDIA_VISIBLE_DEVICES e NVIDIA_DRIVER_CAPABILITIES são
# definidas pela própria imagem base nvidia/cuda:* quando aplicável. Em bases
# não-CUDA (ex.: ubuntu:24.04) elas simplesmente não existem — sem confusão.

# ---- Pacotes base + ffmpeg + Python 3.12 + libs Chromium (Marp) -------------
RUN apt-get update -y && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
    ca-certificates curl wget gnupg gpg lsb-release software-properties-common \
    sudo sshpass openssh-client \
    git jq aha less unzip zip bzip2 \
    ffmpeg \
    python3.12 python3.12-venv python3-pip \
    fonts-dejavu fonts-liberation \
    libnss3 libatk1.0-0t64 libatk-bridge2.0-0t64 libcups2t64 libdrm2 libxkbcommon0 \
    libxcomposite1 libxdamage1 libxfixes3 libxrandr2 libgbm1 libpango-1.0-0 \
    libcairo2 libasound2t64 libatspi2.0-0t64 \
    && ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && echo ${TZ} > /etc/timezone \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3.12 1 \
    && rm -rf /var/lib/apt/lists/*

# ---- Terraform 1.15.8 (binario oficial HashiCorp) --------------------------
COPY --from=terraform-runtime /bin/terraform /usr/local/bin/terraform

# ---- Azure CLI --------------------------------------------------------------
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# ---- GitHub CLI (gh) — versão pinada via ARG --------------------------------
RUN ARCH=$(dpkg --print-architecture) \
    && curl -fsSL "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_${ARCH}.tar.gz" \
    -o /tmp/gh.tar.gz \
    && tar -xz -f /tmp/gh.tar.gz -C /tmp \
    && mv "/tmp/gh_${GH_VERSION}_linux_${ARCH}/bin/gh" /usr/local/bin/gh \
    && rm -rf /tmp/gh.tar.gz "/tmp/gh_${GH_VERSION}_linux_${ARCH}"

# ---- sqlcmd (go-sqlcmd) — binário oficial Microsoft -------------------------
# https://github.com/microsoft/go-sqlcmd/releases
# Não exige aceite de EULA (ao contrário do mssql-tools clássico) e é um
# binário estático único. Configuração por padrão em /root/.sqlcmd/sqlconfig.
# Os assets do upstream usam diretamente a nomenclatura `dpkg --print-architecture`
# (amd64, arm64), então não é preciso traduzir.
RUN ARCH=$(dpkg --print-architecture) \
    && case "$ARCH" in \
    amd64|arm64) : ;; \
    *) echo "Arquitetura não suportada para sqlcmd: $ARCH" && exit 1 ;; \
    esac \
    && curl -fsSL "https://github.com/microsoft/go-sqlcmd/releases/download/v${SQLCMD_VERSION}/sqlcmd-linux-${ARCH}.tar.bz2" \
    -o /tmp/sqlcmd.tar.bz2 \
    && mkdir -p /tmp/sqlcmd \
    && tar -xjf /tmp/sqlcmd.tar.bz2 -C /tmp/sqlcmd \
    && mv /tmp/sqlcmd/sqlcmd /usr/local/bin/sqlcmd \
    && chmod +x /usr/local/bin/sqlcmd \
    && rm -rf /tmp/sqlcmd /tmp/sqlcmd.tar.bz2 \
    && sqlcmd --version

# ---- Node.js 24 LTS + npm 12 + Marp CLI ------------------------------------
COPY --from=node-runtime /usr/local/ /usr/local/
RUN npm install --global "npm@${NPM_VERSION}" \
    && ln -sf /usr/local/bin/corepack /usr/local/bin/pnpm \
    && ln -sf /usr/local/bin/corepack /usr/local/bin/pnpx \
    && ln -sf /usr/local/bin/corepack /usr/local/bin/yarn \
    && ln -sf /usr/local/bin/corepack /usr/local/bin/yarnpkg \
    && corepack enable \
    && npm install --global @marp-team/marp-cli \
    && npm cache clean --force

# ---- uv (gerenciador Python) -------------------------------------------------
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# ---- Venv base (sempre): Ansible + utilitários Python -----------------------
RUN uv venv --python python3.12 /opt/venv \
    && uv pip install --python /opt/venv/bin/python \
    ansible ansible-dev-tools passlib \
    typer rich httpx python-dotenv

# ---- ML opcional: PyTorch + openai-whisper ----------------------------------
# Usa wheel cu126 quando a base for CUDA, ou wheel CPU caso contrário.
RUN if [ "$INSTALL_ML" = "true" ]; then \
    case "$BASE_IMAGE" in \
    *nvidia/cuda*|*cuda*) \
    echo "[ML] PyTorch CUDA cu126" && \
    uv pip install --python /opt/venv/bin/python \
    --extra-index-url https://download.pytorch.org/whl/cu126 \
    torch torchaudio ;; \
    *) \
    echo "[ML] PyTorch CPU" && \
    uv pip install --python /opt/venv/bin/python \
    --extra-index-url https://download.pytorch.org/whl/cpu \
    torch torchaudio ;; \
    esac && \
    uv pip install --python /opt/venv/bin/python openai-whisper ; \
    else \
    echo "[ML] pulado (INSTALL_ML=$INSTALL_ML)" ; \
    fi

# ---- Google APIs opcionais (YouTube Data, Drive, etc.) ----------------------
RUN if [ "$INSTALL_GOOGLE" = "true" ]; then \
    echo "[Google] instalando google-api-python-client + auth" && \
    uv pip install --python /opt/venv/bin/python \
    google-api-python-client google-auth-oauthlib google-auth-httplib2 ; \
    else \
    echo "[Google] pulado (INSTALL_GOOGLE=$INSTALL_GOOGLE)" ; \
    fi

# ---- zsh + oh-my-posh + zsh-autosuggestions ---------------------------------
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends zsh \
    && rm -rf /var/lib/apt/lists/* \
    && sh -c "$(curl -fsSL https://ohmyposh.dev/install.sh)" \
    && mkdir -p /root/.oh-my-zsh/custom/plugins /tmp/posh \
    && git clone https://github.com/zsh-users/zsh-autosuggestions /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions

# Garante que /opt/venv/bin e /root/.local/bin estejam no PATH em qualquer
# shell (login, interativo, não-interativo) — algumas distros resetam PATH
# em /etc/zsh/zshenv ou /etc/profile.
RUN printf '%s\n' \
    'export PATH="/opt/venv/bin:/root/.local/bin:$PATH"' \
    > /etc/zsh/zshenv.local \
    && echo '[ -f /etc/zsh/zshenv.local ] && source /etc/zsh/zshenv.local' >> /etc/zsh/zshenv \
    && echo 'export PATH="/opt/venv/bin:/root/.local/bin:$PATH"' >> /etc/profile.d/00-venv-path.sh

# ---- Tema oh-my-posh customizado (opcional) ---------------------------------
# Coloque um arquivo `atomic.omp.json` (ou outro tema oh-my-posh) na raiz do
# contexto de build para embuti-lo na imagem. Se o arquivo não existir, o
# tema default do oh-my-posh é usado.
#
# No Windows (corporativo), antes de buildar:
#   Copy-Item "$env:OneDrive\atomic.omp.json" .\atomic.omp.json
#
# O truque `Dockerfile atomic.omp.jso[n]` força o COPY a sempre ter pelo menos
# uma fonte (Dockerfile), evitando erro quando o tema não está presente.
COPY Dockerfile atomic.omp.jso[n] /tmp/posh/
RUN if [ -f /tmp/posh/atomic.omp.json ]; then \
    cp /tmp/posh/atomic.omp.json /root/.poshtheme.omp.json && \
    echo "[posh] tema atomic.omp.json embutido em /root/.poshtheme.omp.json" ; \
    else \
    echo "[posh] sem tema customizado — usando default do oh-my-posh" ; \
    fi \
    && rm -rf /tmp/posh

RUN printf '%s\n' \
    'export PATH="$PATH:$HOME/.local/bin"' \
    'plugins=(zsh-autosuggestions)' \
    'HISTFILE=~/.histfile' \
    '# Tema oh-my-posh: usa /root/.poshtheme.omp.json se presente (embutido' \
    '# na imagem ou montado em runtime), senão tema default.' \
    'if [ -f /root/.poshtheme.omp.json ]; then' \
    '    eval "$(oh-my-posh init zsh --config /root/.poshtheme.omp.json)"' \
    'else' \
    '    eval "$(oh-my-posh init zsh)"' \
    'fi' \
    > /root/.zshrc

# ---- Entrypoint padrão ------------------------------------------------------
# Garante PATH correto + executa hooks em /docker-entrypoint.d/*.sh (sourced).
# Projetos consumidores podem montar hooks (ex.: video-pipeline monta um
# `10-vp-init.sh` que roda `uv sync` no /work/.venv).
COPY entrypoint.sh /usr/local/bin/devops-entrypoint
RUN chmod +x /usr/local/bin/devops-entrypoint \
    && mkdir -p /docker-entrypoint.d
ENTRYPOINT ["/usr/local/bin/devops-entrypoint"]

WORKDIR /workspace
CMD ["zsh"]
