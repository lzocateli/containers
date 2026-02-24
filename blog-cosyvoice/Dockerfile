FROM pytorch/pytorch:2.1.0-cuda12.1-cudnn8-runtime

WORKDIR /app

# Instalar dependências do sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    git \
    && rm -rf /var/lib/apt/lists/*

# Instalar uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# Copiar projeto
COPY pyproject.toml uv.lock .python-version ./
COPY src/ ./src/

# Instalar dependências com uv
RUN uv sync --frozen --no-dev

# Baixar modelo CosyVoice (baked na imagem)
RUN uv run python -c "from cosyvoice import CosyVoice; CosyVoice('CosyVoice-300M')"

# Copiar voice sample
COPY voice/ ./voice/

# Endpoint HTTP para RunPod
COPY runpod_handler.py ./

EXPOSE 8000

CMD ["uv", "run", "python", "runpod_handler.py"]
