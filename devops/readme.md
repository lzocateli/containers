# infra/devops — Imagem multifuncional

Imagem Docker **única** que consolida em um só container as ferramentas que antes estavam dispersas em `containers/devops/`, `containers/github-cli/` e na pipeline de vídeo da trilha Copilot. Use-a como ambiente de trabalho portátil para automação, infra, CI local, GitHub e geração de conteúdo.

Base **CUDA 12.4 + cuDNN** sobre Ubuntu 22.04 — funciona normalmente em hosts CPU-only; em hosts com NVIDIA + WSL2 (driver ≥ 550), basta passar `--gpus all` para acelerar Whisper/PyTorch.

## O que vem dentro

| Categoria | Ferramentas | Sempre? |
|---|---|---|
| Linguagem | Python 3.11 (`uv` como gerenciador), Node.js 20 | sempre |
| Cloud / IaC | Azure CLI, Terraform, Ansible (+ `ansible-dev-tools`, `passlib`) | sempre |
| GitHub | GitHub CLI (`gh`) — versão pinada via `--build-arg GH_VERSION=...` | sempre |
| Vídeo / Marp | ffmpeg/ffprobe, Marp CLI, libs Chromium headless | sempre |
| Python utils | `typer`, `rich`, `httpx`, `python-dotenv` | sempre |
| Shell | zsh + oh-my-posh + zsh-autosuggestions, sshpass, openssh-client, jq, git | sempre |
| ML / Áudio | PyTorch (`cu124` ou `cpu`), `openai-whisper` | `INSTALL_ML=true` |
| Google APIs | `google-api-python-client` + OAuth (YouTube Data API, Drive, etc.) | `INSTALL_GOOGLE=true` |
| Aceleração GPU | CUDA 12.4 + cuDNN | `BASE_IMAGE=nvidia/cuda:*` |

> Tudo o que é Python fica no venv pré-aquecido em `/opt/venv` (já no `PATH`). Para projetos com `pyproject.toml` próprio, basta `uv sync` dentro de `/workspace`.

## Build

A imagem é flexível via build-args — você escolhe quais módulos pesados entram. Ansible, Terraform, Az CLI, gh, ffmpeg, Marp, Node.js, uv, zsh e utilitários básicos do Python (`typer`, `rich`, `httpx`, `python-dotenv`) estão **sempre presentes**.

### Build-args disponíveis

| Arg | Default | Efeito |
|---|---|---|
| `BASE_IMAGE` | `nvidia/cuda:12.4.1-cudnn-runtime-ubuntu22.04` | Imagem base. Use `ubuntu:22.04` (ou outra debian-like) para versão sem CUDA |
| `INSTALL_ML` | `true` | Instala PyTorch (`cu124` se base CUDA, `cpu` caso contrário) + `openai-whisper` |
| `INSTALL_GOOGLE` | `true` | Instala `google-api-python-client` + `google-auth-oauthlib` + `google-auth-httplib2` |
| `GH_VERSION` | `2.92.0` | Versão do GitHub CLI (binário oficial) |
| `Env_HttpProxy` | *(vazio)* | Proxy corporativo `host:porta` para o build |
| `Env_NoProxy` | *(vazio)* | Bypass proxy |
| `TZ` | `America/Sao_Paulo` | Timezone do container |

### Variantes recomendadas

| Tag sugerida | Build-args | Uso |
|---|---|---|
| `:cuda-12.4.1` | (defaults) | **Completa** — CUDA + ML + Google. Pipeline de vídeo, ML, automação |
| `:cpu` | `BASE_IMAGE=ubuntu:22.04` | CPU + Whisper (PyTorch CPU) + Google. Mesma stack, sem GPU |
| `:cpu-slim` | `BASE_IMAGE=ubuntu:22.04` `INSTALL_ML=false` `INSTALL_GOOGLE=false` | Só devops puro: Ansible/TF/Az/gh/ffmpeg/Marp/uv |
| `:ops` | `BASE_IMAGE=ubuntu:22.04` `INSTALL_ML=false` `INSTALL_GOOGLE=false` | Sinônimo de `cpu-slim` quando o foco é IaC/automação |

> `lzocateli/devops:ubuntu-22.04` no exemplo de build slim equivale a `cpu-slim` e **nao** inclui `gcloud`.
> Para comandos `gcloud`, use `:cpu` ou `:cuda-12.4.1` (ou faca build com `INSTALL_GOOGLE=true`).

### Exemplos de build

```powershell
cd containers/devops
Copy-Item "$env:OneDrive\atomic.omp.json" .\atomic.omp.json

# Completa (default — CUDA + ML + Google)
docker build -t lzocateli/devops:cuda-12.4.1 -f Dockerfile .

# CPU + Whisper (sem CUDA, mas com PyTorch CPU)
docker build `
  --build-arg BASE_IMAGE=ubuntu:22.04 `
  -t lzocateli/devops:cpu -f Dockerfile .

# Slim devops (Ansible/TF/Az/gh/ffmpeg/Marp/uv, sem ML, sem Google)
docker build `
  --build-arg BASE_IMAGE=ubuntu:22.04 `
  --build-arg INSTALL_ML=false `
  --build-arg INSTALL_GOOGLE=false `
  -t lzocateli/devops:ubuntu-22.04 `
  -f Dockerfile .

# Pinning de versão diferente do gh
docker build --build-arg GH_VERSION=2.95.0 -t lzocateli/devops:cuda-12.4.1 -f Dockerfile .
```

### Com proxy corporativo

- CUDA

```powershell
Copy-Item "$env:OneDrive\atomic.omp.json" .\atomic.omp.json
  # --build-arg Env_HttpProxy=proxy.cat.com:80 `
  # --build-arg Env_NoProxy=cat.com `
docker build `
  --build-arg GH_VERSION=2.92.0 `
  -t lzocateli/devops:cuda-12.4.1 `
  -f Dockerfile .

docker push lzocateli/devops:cuda-12.4.1
```

- Imagem sem CUDA

```powershell
Copy-Item "$env:OneDrive\atomic.omp.json" .\atomic.omp.json
  # --build-arg Env_HttpProxy=proxy.cat.com:80 `
  # --build-arg Env_NoProxy=cat.com `
docker build `
  --build-arg GH_VERSION=2.92.0 `
  --build-arg BASE_IMAGE=ubuntu:22.04 `
  --build-arg INSTALL_ML=false `
  --build-arg INSTALL_GOOGLE=true `
  -t lzocateli/devops:ubuntu-22.04 `
  -f Dockerfile .

docker push lzocateli/devops:ubuntu-22.04
```


> Bypass proxy regex: `cat\.com`.
> Repositório dos Dockerfiles: `gitbr-bussupport/containers` → `containers/devops/`.

### Smoke test GPU (apenas variantes CUDA)

```powershell
docker run --rm --gpus all infra/devops:cuda-12.4.1 nvidia-smi
```

> **Nota:** as variáveis `NVIDIA_VISIBLE_DEVICES` / `NVIDIA_DRIVER_CAPABILITIES` só existem nas variantes com base CUDA (herdadas da imagem `nvidia/cuda:*`). Em variantes `:cpu*` elas não aparecem, evitando confusão.

### Push para Docker Hub pessoal

```powershell
docker login -u lzocateli
docker tag  infra/devops:cuda-12.4.1 lzocateli/devops:cuda-12.4.1
docker push                          lzocateli/devops:cuda-12.4.1
```

## Uso geral (shell interativo)

```powershell
# Cria a pasta de configuração do GitHub CLI (1 vez)
$ghConfigDir = "$env:USERPROFILE\.config\gh"
if (!(Test-Path $ghConfigDir)) { New-Item -ItemType Directory -Path $ghConfigDir -Force }

# Shell (CPU)
docker run --rm -it `
  -v "$(Get-Location):/workspace" -w /workspace `
  -v "$($HOME)/.config/gh:/root/.config/gh" `
  infra/devops:latest zsh

# Shell com GPU
docker run --rm -it --gpus all `
  -v "$(Get-Location):/workspace" -w /workspace `
  -v "$($HOME)/.config/gh:/root/.config/gh" `
  infra/devops:latest zsh
```

Linux/macOS:

```bash
docker run --rm -it [--gpus all] \
  -v "$PWD:/workspace" -w /workspace \
  -v "$HOME/.config/gh:/root/.config/gh" \
  infra/devops:latest zsh
```

### Tema do oh-my-posh customizado (opcional)

A imagem traz oh-my-posh + tema default. Para embutir seu tema próprio (ex.: o `atomic.omp.json` que você usa no Windows), basta colocar o arquivo na pasta `containers/devops/` antes do build — o `Dockerfile` copia se existir e ignora silenciosamente caso contrário.

```powershell
# 1 vez (no Windows, copia o tema do OneDrive para o contexto de build)
Copy-Item "$env:OneDrive\atomic.omp.json" .\atomic.omp.json

docker build -t infra/devops:cuda-12.4.1 -f Dockerfile .
```

Se o arquivo não existir, o build segue normalmente e o `.zshrc` cai no tema default. Em runtime, você ainda pode sobrescrever montando `-v /caminho/outro.omp.json:/root/.poshtheme.omp.json:ro`.

## Cenário 1 — GitHub CLI (`gh`)

A imagem traz `gh` na versão fixada no build. Tokens ficam em `~/.config/gh/hosts.yml` no host (preservado entre execuções pelo bind mount).

### Função no PowerShell Profile

Adicione ao `$PROFILE` para usar `gh` como se fosse comando local:

```powershell
code $PROFILE

function GithubCli {
  C:\'Program Files'\Docker\Docker\resources\bin\docker.exe run --rm -it `
    -v "$(Get-Location):/workspace" -w /workspace `
    -v "$($HOME)/.config/gh:/root/.config/gh" `
    lzocateli/devops:latest gh $Args
}
Set-Alias gh GithubCli -Option AllScope
```

### Exemplos de uso

```powershell
gh auth login
gh repo list
gh pr list
gh issue list

git remote -v
git remote set-url nuuv git@github-pessoal:nuuvify/Nuuvify.CommonPack.git
```

### Múltiplas contas (suportado a partir do `gh` 2.40.0)

**Adicionar contas (uma vez cada):**

```powershell
gh auth login --hostname github.com --git-protocol https --web
# Quando pedido, use o usuário zocatel_cat
ghswitch corp

gh auth login --hostname github.com                       # conta pessoal
gh auth login --hostname suaempresa.github.com            # GitHub Enterprise
```

**Listar / alternar:**

```powershell
gh auth status
gh auth switch                              # interativo
gh auth switch --user lzocateli
gh auth switch --user zocatel_cat
gh --hostname suaempresa.github.com repo list  # comando pontual em outra conta
```

> Os tokens vivem em `~/.config/gh/hosts.yml`. Como o volume `-v $HOME/.config/gh:/root/.config/gh` está montado, a troca persiste entre execuções.

### Aliases por conta no Profile

```powershell
function GithubCliPessoal {
  C:\'Program Files'\Docker\Docker\resources\bin\docker.exe run --rm -it `
    -v "$(Get-Location):/workspace" -w /workspace `
    -v "$($HOME)/.config/gh:/root/.config/gh" `
    lzocateli/devops:latest `
    gh auth switch --user lzocateli ; gh $Args
}

function GithubCliCorp {
  C:\'Program Files'\Docker\Docker\resources\bin\docker.exe run --rm -it `
    -v "$(Get-Location):/workspace" -w /workspace `
    -v "$($HOME)/.config/gh:/root/.config/gh" `
    lzocateli/devops:latest `
    gh auth switch --user zocatel_cat ; gh $Args
}

function Switch-GhAccount {
    param([ValidateSet('pessoal', 'corp')] [string]$Account)
    switch ($Account) {
        'pessoal' {
            Set-Alias gh GithubCliPessoal -Option AllScope -Force -Scope Global
            Write-Host "gh → GithubCliPessoal (lzocateli)" -ForegroundColor Green
        }
        'corp' {
            Set-Alias gh GithubCliCorp -Option AllScope -Force -Scope Global
            Write-Host "gh → GithubCliCorp (zocatel_cat)" -ForegroundColor Cyan
        }
    }
}

Set-Alias gh       GithubCliPessoal -Option AllScope
Set-Alias ghcorp   GithubCliCorp    -Option AllScope
Set-Alias ghswitch Switch-GhAccount -Option AllScope
```

### Copilot CLI (extensão do `gh`)

Após autenticar:

```bash
gh extension install github/gh-copilot
gh copilot suggest "ffmpeg overlay PiP no canto inferior direito"
gh copilot explain "find . -name '*.mp4' -mtime +30 -delete"
```

## Cenário 2 — Terraform / Azure CLI / Ansible

Tudo já no `PATH`. O bind de `/workspace` permite trabalhar nos seus arquivos `.tf`, `playbooks/`, etc., sem instalar nada no host.

```powershell
docker run --rm -it `
  -v "$(Get-Location):/workspace" -w /workspace `
  infra/devops:latest zsh

# dentro do container:
terraform -version
az login --use-device-code
ansible --version
ansible-playbook playbook.yml -i inventory.ini
```

Para preservar credenciais Azure e SSH entre execuções:

```powershell
docker run --rm -it `
  -v "$(Get-Location):/workspace" -w /workspace `
  -v "$($HOME)/.azure:/root/.azure" `
  -v "$($HOME)/.ssh:/root/.ssh:ro" `
  infra/devops:latest zsh
```

## Cenário 3 — Pipeline de vídeo (Trilha Copilot)

A pipeline em `github.copilot-tutorial/video-pipeline/` usa esta imagem como base. Veja [video-pipeline/README.md](../../github-copilot-training/github.copilot-tutorial/video-pipeline/README.md).

Comando direto (montando a pasta da pipeline):

```powershell
cd github.copilot-tutorial/video-pipeline
docker run --rm -it [--gpus all] `
  -v "$(Get-Location):/work" -w /work `
  -v "$($HOME)/.config/gh:/root/.config/gh" `
  infra/devops:latest `
  bash -lc "uv sync && vp build-all --module 01-fundamentos --skip-upload --skip-nas"
```

> Para inferência GPU do Whisper: adicione `--gpus all` e `-e WHISPER_DEVICE=cuda`.

## Cenário 4 — Ambiente Python ad-hoc (uv)

`uv` está pronto para criar ambientes Python isolados em qualquer pasta montada:

```bash
# dentro do container
cd /workspace
uv init meu-projeto
cd meu-projeto
uv add fastapi uvicorn[standard]
uv run uvicorn main:app --reload
```

## Estrutura

```
containers/devops/
├── Dockerfile          # único (CUDA 12.4 + cuDNN; CPU-friendly)
└── readme.md           # este arquivo
```

> A antiga pasta `containers/github-cli/` foi consolidada nesta imagem e removida. O `gh` agora vive aqui junto com Terraform, Az CLI, Ansible e a pipeline de vídeo. O mecanismo de `ARG GH_VERSION` foi preservado.

## Atualizações importantes

- **Imagem flexível**: 3 build-args principais escolhem o que entra: `BASE_IMAGE`, `INSTALL_ML`, `INSTALL_GOOGLE`. Ansible + Terraform + Az CLI + gh + ffmpeg + Marp + uv são sempre incluídos.
- **Versão do `gh`**: pinada via `--build-arg GH_VERSION=X.Y.Z` (default `2.92.0`). Baixa o binário oficial em `https://github.com/cli/cli/releases/`.
- **PyTorch**: detecção automática baseada em `BASE_IMAGE` — wheel `cu124` quando a base é `nvidia/cuda:*`, wheel `cpu` caso contrário. Para outra versão de CUDA, mude `BASE_IMAGE` (ex.: `nvidia/cuda:12.6.0-cudnn-runtime-ubuntu22.04`).
- **NVIDIA env vars**: `NVIDIA_VISIBLE_DEVICES` e `NVIDIA_DRIVER_CAPABILITIES` vêm apenas quando a base é CUDA (herdadas da imagem upstream); não aparecem em variantes `:cpu*`.
- **Hosts CPU-only**: variantes CUDA também funcionam sem `--gpus all`; só não aceleram ML. Para abreviar, prefira a variante `:cpu` quando souber que não vai usar GPU.
- **Proxy corporativo**: os ARGs `Env_HttpProxy` e `Env_NoProxy` são propagados como `HTTP_PROXY`/`NO_PROXY` durante o build. Em runtime, passe `-e HTTPS_PROXY=...` se o container precisar acessar a internet pelo proxy.
