# Imagem multifuncional "devops" — flexível.
#
# Build flags:
#   BASE_IMAGE       imagem base (default: CUDA 12.4 + cuDNN sobre Ubuntu 22.04).
#                    Para versão "slim" sem CUDA: BASE_IMAGE=ubuntu:22.04
#   INSTALL_ML       instala PyTorch (cu124 ou cpu) + openai-whisper. Default: true
#   INSTALL_GOOGLE   instala Google Cloud CLI (gcloud) + google-api-python-client + google-auth-* (YouTube/Drive). Default: true
#   GH_VERSION       versão do GitHub CLI (binário oficial). Default: 2.92.0
#   Env_HttpProxy    proxy corporativo (host:porta). Opcional.
#   Env_NoProxy      bypass proxy. Opcional.
#
# Sempre incluído (independente das flags):
#   - Python 3.11 + uv (venv pré-aquecido em /opt/venv)
#   - ffmpeg/ffprobe + Node.js 20 + Marp CLI (libs Chromium headless)
#   - Terraform, Azure CLI, Ansible (+ ansible-dev-tools, passlib)
#   - GitHub CLI (gh) — versão pinada via ARG GH_VERSION
#   - typer, rich, httpx, python-dotenv
#   - zsh + oh-my-posh + zsh-autosuggestions
#   - SSH client, sshpass, jq, git
#
# Exemplos:
#
#  # Imagem completa com GPU (default)
#   docker build -t infra/devops:cuda-12.4.1 -f Dockerfile .
#
#  # Imagem slim (sem CUDA, sem ML, sem Google)
#   docker build \
#       --build-arg BASE_IMAGE=ubuntu:22.04 \
#       --build-arg INSTALL_ML=false \
#       --build-arg INSTALL_GOOGLE=false \
#       -t infra/devops:slim -f Dockerfile .
#
#  # Imagem só com Ansible/Terraform/Az CLI/gh (sem ffmpeg/marp/whisper)
#   docker build \
#       --build-arg BASE_IMAGE=ubuntu:22.04 \
#       --build-arg INSTALL_ML=false \
#       --build-arg INSTALL_GOOGLE=false \
#       -t infra/devops:ops -f Dockerfile .
#
#  # CPU + Whisper (sem CUDA, mas com PyTorch CPU)
#   docker build \
#       --build-arg BASE_IMAGE=ubuntu:22.04 \
#       --build-arg INSTALL_ML=true \
#       -t infra/devops:cpu-ml -f Dockerfile .

ARG BASE_IMAGE=nvidia/cuda:12.4.1-cudnn-runtime-ubuntu22.04
FROM ${BASE_IMAGE}

# ---- Re-declara ARGs após FROM (necessário para uso nos RUN abaixo) ---------
ARG BASE_IMAGE=nvidia/cuda:12.4.1-cudnn-runtime-ubuntu22.04
ARG INSTALL_ML=true
ARG INSTALL_GOOGLE=true
ARG GH_VERSION=2.92.0

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

# Nota: variáveis NVIDIA_VISIBLE_DEVICES e NVIDIA_DRIVER_CAPABILITIES são
# definidas pela própria imagem base nvidia/cuda:* quando aplicável. Em bases
# não-CUDA (ex.: ubuntu:22.04) elas simplesmente não existem — sem confusão.

# ---- Pacotes base + ffmpeg + Python 3.11 + libs Chromium (Marp) -------------
RUN apt-get update -y && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends \
        ca-certificates curl wget gnupg gpg lsb-release software-properties-common \
        sudo sshpass openssh-client \
        git jq aha less unzip zip \
        ffmpeg \
        python3.11 python3.11-venv python3-pip \
        fonts-dejavu fonts-liberation \
        libnss3 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 libxkbcommon0 \
        libxcomposite1 libxdamage1 libxfixes3 libxrandr2 libgbm1 libpango-1.0-0 \
        libcairo2 libasound2 libatspi2.0-0 \
 && ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && echo ${TZ} > /etc/timezone \
 && update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1 \
 && rm -rf /var/lib/apt/lists/*

# ---- Terraform (HashiCorp apt) ----------------------------------------------
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg \
 && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
        > /etc/apt/sources.list.d/hashicorp.list \
 && apt-get update -y \
 && apt-get install -y --no-install-recommends terraform \
 && rm -rf /var/lib/apt/lists/*

# ---- Azure CLI --------------------------------------------------------------
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# ---- GitHub CLI (gh) — versão pinada via ARG --------------------------------
RUN ARCH=$(dpkg --print-architecture) \
 && curl -fsSL "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_${ARCH}.tar.gz" \
        -o /tmp/gh.tar.gz \
 && tar -xz -f /tmp/gh.tar.gz -C /tmp \
 && mv "/tmp/gh_${GH_VERSION}_linux_${ARCH}/bin/gh" /usr/local/bin/gh \
 && rm -rf /tmp/gh.tar.gz "/tmp/gh_${GH_VERSION}_linux_${ARCH}"

# ---- Node.js 20 + Marp CLI --------------------------------------------------
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
 && apt-get install -y --no-install-recommends nodejs \
 && npm install -g @marp-team/marp-cli \
 && rm -rf /var/lib/apt/lists/*

# ---- uv (gerenciador Python) -------------------------------------------------
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# ---- Venv base (sempre): Ansible + utilitários Python -----------------------
RUN uv venv --python python3.11 /opt/venv \
 && uv pip install --python /opt/venv/bin/python \
        ansible ansible-dev-tools passlib \
        typer rich httpx python-dotenv

# ---- ML opcional: PyTorch + openai-whisper ----------------------------------
# Usa wheel cu124 quando a base for CUDA, ou wheel CPU caso contrário.
RUN if [ "$INSTALL_ML" = "true" ]; then \
        case "$BASE_IMAGE" in \
            *nvidia/cuda*|*cuda*) \
                echo "[ML] PyTorch CUDA cu124" && \
                uv pip install --python /opt/venv/bin/python \
                    --extra-index-url https://download.pytorch.org/whl/cu124 \
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

# ---- Google opcional: Cloud CLI (gcloud) + APIs Python ----------------------
RUN if [ "$INSTALL_GOOGLE" = "true" ]; then \
        echo "[Google] instalando Google Cloud CLI (gcloud) + libs Python" && \
        curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
            | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
        echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" \
            > /etc/apt/sources.list.d/google-cloud-sdk.list && \
        apt-get update -y && \
        apt-get install -y --no-install-recommends google-cloud-cli && \
        uv pip install --python /opt/venv/bin/python \
            google-api-python-client google-auth-oauthlib google-auth-httplib2 && \
        rm -rf /var/lib/apt/lists/* ; \
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
RUN sed -i '1s/^\xEF\xBB\xBF//' /usr/local/bin/devops-entrypoint \
 && sed -i 's/\r$//' /usr/local/bin/devops-entrypoint \
 && chmod +x /usr/local/bin/devops-entrypoint \
 && mkdir -p /docker-entrypoint.d
ENTRYPOINT ["/usr/local/bin/devops-entrypoint"]

WORKDIR /workspace
CMD ["zsh"]
