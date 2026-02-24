FROM pytorch/pytorch:2.3.1-cuda12.1-cudnn8-runtime

WORKDIR /app

ENV TZ="America/Sao_Paulo" \
    DEBIAN_FRONTEND=noninteractive

# ── Camada 1: deps do sistema (cached após primeiro build) ──
# g++ necessário para compilar pyworld (extensão C++), removido depois
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    git \
    g++ \
    tzdata \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
    && rm -rf /var/lib/apt/lists/*

# ── Camada 2: uv (cached, muda só se trocar versão) ──
COPY --from=ghcr.io/astral-sh/uv:0.9.26 /uv /usr/local/bin/uv

# ── Camada 3: clone CosyVoice (cached se não falhar) ──
# --depth 1 + --shallow-submodules: evita baixar histórico git (~80% mais rápido)
RUN git clone --depth 1 --shallow-submodules --recursive \
    https://github.com/FunAudioLLM/CosyVoice.git /opt/CosyVoice && \
    rm -rf /opt/CosyVoice/.git

# ── Camada 4: pip install deps pesadas (a mais demorada, cached separada) ──
# Duas etapas porque:
#   - tensorrt-cu12-libs precisa de build isolation (usa wheel_stub como build backend)
#   - openai-whisper precisa de --no-build-isolation (usa pkg_resources do setuptools<71)
RUN pip install --no-cache-dir "setuptools<71" wheel && \
    cd /opt/CosyVoice && \
    grep -v 'openai-whisper' requirements.txt > /tmp/reqs.txt && \
    pip install --no-cache-dir -r /tmp/reqs.txt && \
    rm -f /tmp/reqs.txt

# ── Camada 5: whisper (separada — se falhar, não refaz camada 4) ──
RUN pip install --no-cache-dir --no-build-isolation openai-whisper==20231117

# ── Camada 6: cleanup — remove g++ (só era necessário para compilar pyworld) ──
RUN apt-get purge -y g++ && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*

# CosyVoice não é um pacote pip (sem setup.py/pyproject.toml).
# Basta adicionar ao PYTHONPATH para que os módulos sejam importáveis.
ENV PYTHONPATH="/opt/CosyVoice${PYTHONPATH:+:${PYTHONPATH}}"

