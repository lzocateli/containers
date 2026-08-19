<!--
SPDX-FileCopyrightText: 2024 Lincoln Zocateli
SPDX-License-Identifier: MIT
-->

# DEVOPS

![Docker Hub](https://img.shields.io/badge/image-lzocateli%2Fdevops-2496ED?logo=docker&logoColor=white)
![Version](https://img.shields.io/badge/version-cuda--12.6.3--node24--terraform1.15.8-2E7D32)
![Base](https://img.shields.io/badge/base-nvidia%2Fcuda%3A12.6.3--cudnn--runtime--ubuntu24.04-555555?logo=docker&logoColor=white)
![Platforms](https://img.shields.io/badge/platforms-linux%2Famd64-607D8B)
![Repository code license](https://img.shields.io/badge/repository_code-MIT-1565C0)
![Build](https://img.shields.io/badge/build-validado-success)

Imagem multifuncional para automacao, IaC, CI local e fluxos de conteudo, unificando Python, Azure CLI, Terraform, Ansible, GitHub CLI, Node.js/Marp e utilitarios opcionais de ML no mesmo ambiente.

## Referencia da imagem

| Item | Valor |
| --- | --- |
| Imagem | `lzocateli/devops:<tag>` |
| Tag recomendada (GPU) | `lzocateli/devops:cuda-12.6.3` |
| Tag recomendada (CPU) | `lzocateli/devops:cpu` |
| Imagem base padrao | `nvidia/cuda:12.6.3-cudnn-runtime-ubuntu24.04` |
| Node.js | `24.15.0` |
| npm | `12.0.2` |
| Terraform | `1.15.8` |
| Plataformas | `linux/amd64` |
| Usuario padrao | `root` (necessario para ferramentas administrativas e shell de automacao) |
| Entry point | `/usr/local/bin/devops-entrypoint` |
| Diretorio de trabalho | `/workspace` |
| Codigo-fonte | `https://github.com/lzocateli/containers/tree/main/devops` |
| Documentacao | `https://github.com/lzocateli/containers/tree/main/devops` |

## Conteudo e finalidade

### Incluido

- Python 3.12 com `uv` e venv pre-aquecido em `/opt/venv`.
- Azure CLI, Terraform 1.15.8 e Ansible (`ansible-dev-tools`, `passlib`).
- GitHub CLI (`gh`) com versao pinada por `GH_VERSION`.
- `sqlcmd` (go-sqlcmd Microsoft) com versao pinada por `SQLCMD_VERSION`.
- Node.js 24.15.0 LTS, npm 12.0.2, npx, Corepack, Marp CLI, ffmpeg/ffprobe e dependencias de Chromium headless.
- zsh, oh-my-posh, zsh-autosuggestions, sshpass, openssh-client, jq e git.
- Opcional: PyTorch (`cu126` ou `cpu`) + `openai-whisper` com `INSTALL_ML=true`.
- Opcional: Google APIs (`google-api-python-client` e auth libs) com `INSTALL_GOOGLE=true`.

### Contratos incorporados de Node.js e Terraform

Esta imagem incorpora os contratos anteriormente publicados pelas imagens `node` e `terraform`:

- Node.js para workloads JavaScript/TypeScript, com `/workspace` como diretorio de trabalho e sem portas expostas. O hardening de `libgnutls30`, a remocao de pacotes Debian desnecessarios e o npm 12.0.2 fazem parte da imagem unificada.
- Terraform e executado pelo binario oficial em `/usr/local/bin/terraform`, sem providers, backend, estado remoto ou credenciais preconfigurados.
- Angular CLI nao e instalado globalmente; projetos Angular devem usar suas dependencias ou `npx`.
- A imagem `node` especializada continua indicada para workloads que precisam somente do runtime Node ou de uma imagem menor.

### Nao incluido

- Configuracoes sensiveis do usuario (tokens, credenciais, chaves).
- Persistencia de dados aplicacionais no container por padrao.
- Politica de `latest` fixa para producao.

## Inicio rapido

```bash
docker pull lzocateli/devops:cuda-12.6.3
docker run --rm -it lzocateli/devops:cuda-12.6.3 zsh
```

Exemplo minimo executavel (CPU):

```bash
docker run --rm -it \
  -v "$PWD:/workspace" -w /workspace \
  lzocateli/devops:cpu zsh
```

## Docker Compose

```yaml
services:
  devops:
    image: lzocateli/devops:cuda-12.6.3
    restart: unless-stopped
    working_dir: /workspace
    volumes:
      - /caminho/absoluto/no/host:/workspace
      - /caminho/absoluto/gh-config:/root/.config/gh
    command: ["zsh"]
```

## Configuracao

### Variaveis de ambiente

| Variavel | Obrigatoria | Secreta | Padrao | Descricao |
| --- | --- | --- | --- | --- |
| `Env_HttpProxy` | Nao | Nao | nenhum | Proxy corporativo em build (`host:porta`). |
| `Env_NoProxy` | Nao | Nao | nenhum | Bypass de proxy no build. |
| `TZ` | Nao | Nao | `America/Sao_Paulo` | Timezone da imagem. |
| `INSTALL_ML` (build arg) | Nao | Nao | `false` | Liga instalacao de PyTorch e Whisper. |
| `INSTALL_GOOGLE` (build arg) | Nao | Nao | `true` | Liga instalacao de libs Google API. |
| `NODE_VERSION` (build arg) | Nao | Nao | `24.15.0` | Versao do runtime Node.js copiado do estagio oficial. |
| `NPM_VERSION` (build arg) | Nao | Nao | `12.0.2` | Versao global do npm. |
| `TERRAFORM_VERSION` (build arg) | Nao | Nao | `1.15.8` | Versao do binario oficial do Terraform. |
| `GH_VERSION` (build arg) | Nao | Nao | `2.92.0` | Versao do GitHub CLI. |
| `SQLCMD_VERSION` (build arg) | Nao | Nao | `1.10.0` | Versao do go-sqlcmd. |
| `BASE_IMAGE` (build arg) | Nao | Nao | `nvidia/cuda:12.6.3-cudnn-runtime-ubuntu24.04` | Define base CUDA ou CPU. |

### Portas

Esta imagem nao expoe portas por contrato.

### Persistencia e mounts

| Caminho no conteiner | Modo | Conteudo | Backup necessario |
| --- | --- | --- | --- |
| `/workspace` | `rw` | Projeto e artefatos de trabalho do usuario | Conforme projeto montado |
| `/root/.config/gh` | `rw` | Sessao do GitHub CLI | Recomendado |
| `/root/.azure` | `rw` | Sessao do Azure CLI | Recomendado |
| `/root/.ssh` | `ro` | Chaves SSH do host (opcional) | Sim |

Para projetos Node e Terraform, monte o codigo em `/workspace`. O cache npm, os providers Terraform e os arquivos de estado permanecem sob responsabilidade do consumidor.

### Secrets

Forneca secrets somente em runtime, por volume seguro ou variavel de ambiente injetada no executor. Nao versionar segredos no repositorio e nao usar `ARG`/`ENV` no Dockerfile para valores sensiveis.

## Inicializacao e ciclo de vida

- O entrypoint `devops-entrypoint` garante `PATH` consistente e executa hooks de `/docker-entrypoint.d/*.sh` por ordem.
- O comando padrao e `zsh`.
- O processo principal executa em foreground e recebe sinais do runtime via `exec` no entrypoint.
- O entrypoint preserva os comandos Node e Terraform; eles podem ser chamados diretamente, por exemplo `node --version`, `npm ci`, `npx`, `terraform version` e `terraform plan`.

## Seguranca

- A imagem executa como `root` por objetivo operacional (toolbox de automacao).
- Use volumes somente para diretorios necessarios e, quando possivel, com modo somente leitura.
- Restrinja acesso de rede do container quando nao houver necessidade de internet.
- Trate tokens de `gh`, `az` e chaves SSH como dados sensiveis.
- Atualize a base e dependencias em ciclos regulares para reduzir exposicao a CVEs.

## Build local

Build GPU (padrao):

```bash
docker build \
  --pull \
  --tag lzocateli/devops:cuda-12.6.3 \
  devops
```

Para explicitar as versoes incorporadas:

```bash
docker build \
  --build-arg NODE_VERSION=24.15.0 \
  --build-arg NPM_VERSION=12.0.2 \
  --build-arg TERRAFORM_VERSION=1.15.8 \
  --tag lzocateli/devops:cuda-12.6.3 \
  devops
```

Build CPU sem ML e sem Google APIs:

```bash
docker build \
  --pull \
  --build-arg BASE_IMAGE=ubuntu:24.04 \
  --build-arg INSTALL_ML=false \
  --build-arg INSTALL_GOOGLE=false \
  --tag lzocateli/devops:cpu-slim \
  devops
```

## Tags e compatibilidade

| Tag | Mutabilidade | Compatibilidade | Uso recomendado |
| --- | --- | --- | --- |
| `cuda-12.6.3` | Imutavel | GPU NVIDIA (quando disponivel) e CPU | Producao e automacao com ML |
| `cpu` | Imutavel | Hosts sem GPU | Producao sem aceleracao CUDA |
| `cpu-slim` | Imutavel | Hosts sem GPU, sem stack ML/Google | Automacao IaC e CI local |

Nao use `latest` como unica referencia em ambientes criticos.

## Validacao

Antes da publicacao, confirmar:

- `.gitignore` e `.dockerignore` presentes e alinhados;
- `.env`, secrets e backups fora do Git e fora do contexto Docker;
- `.git` excluido do contexto Docker;
- analise do Dockerfile com BuildKit;
- smoke test de shell (`zsh`) e ferramentas-chave (`python`, `gh`, `az`, `ansible`, `sqlcmd`);
- smoke test de Node (`node --version`, `npm --version`, `npx`) e Terraform (`terraform version`);
- inspecao de vulnerabilidades, SBOM e proveniencia;
- labels OCI e tag final coerentes com o release.

## Publicacao

Use **Actions > Publicar imagem de container > Run workflow** com:

- `context_path`: `devops`;
- `image_name`: `devops`;
- `image_tag`: tag imutavel (ex.: `cuda-12.6.3`);
- `dockerfile`: `Dockerfile`;
- `platforms`: `linux/amd64`.

Para a imagem devops, use `context_path: devops`, `image_name: devops` e uma tag imutavel que identifique a base e as versoes incorporadas. Terraform faz parte da imagem unificada e nao possui mais uma release separada neste repositorio.

## Operacao

- Persista configuracoes de CLI por volumes (`/root/.config/gh`, `/root/.azure`, `/root/.ssh`).
- Atualize por troca de tag imutavel e rollback por retorno da tag anterior.
- Logs padrao seguem stdout/stderr do runtime do container.

## Troubleshooting

| Sintoma | Causa provavel | Verificacao | Correcao |
| --- | --- | --- | --- |
| `gh auth` perde sessao | Sem volume para config do GH | verificar bind em `/root/.config/gh` | montar volume persistente |
| `az login` precisa repetir login | Sem volume de config Azure | verificar bind em `/root/.azure` | montar volume persistente |
| `torch` sem CUDA | Container sem `--gpus all` ou host sem runtime NVIDIA | `nvidia-smi` no host/container | usar tag CUDA + runtime NVIDIA |
| Build falha no proxy | Proxy/bypass incorreto | revisar `Env_HttpProxy` e `Env_NoProxy` | ajustar build args de proxy |
| `npm ci` falha por lockfile | lockfile fora de sincronia | comparar `package.json` e lockfile | regenerar o lockfile usando npm 12.0.2 |
| `terraform: command not found` | Imagem/tag incorreta ou comando sobrescrito | executar `terraform version` | usar a tag devops e o entrypoint padrao |
| Erros de provider Terraform | Provider nao inicializado | executar `terraform init` em `/workspace` | inicializar e validar o backend |

## Limitacoes conhecidas

- Sem suporte oficial multi-arquitetura para esta imagem no catalogo atual.
- Nao possui `HEALTHCHECK`, pois e uma imagem toolbox interativa sem processo de servico unico.
- A imagem e maior que a imagem especializada `node`, pois inclui toda a toolbox devops, incluindo Terraform.
- O usuario padrao e `root` para manter compatibilidade com ferramentas administrativas; use uma imagem especializada quando isolamento nao-root for requisito.

## Licencas e fontes

| Componente | Versao | Licenca | Fonte |
| --- | --- | --- | --- |
| Conteudo original deste repositorio | Atual | MIT | `https://github.com/lzocateli/containers` |
| Imagem base CUDA | `12.6.3-cudnn-runtime-ubuntu24.04` | Conforme upstream | `https://hub.docker.com/r/nvidia/cuda` |
| Azure CLI | Variavel no build | Conforme upstream | `https://learn.microsoft.com/cli/azure` |
| GitHub CLI | `GH_VERSION` | MIT | `https://github.com/cli/cli` |
| go-sqlcmd | `SQLCMD_VERSION` | MIT | `https://github.com/microsoft/go-sqlcmd` |
| Node.js | `24.15.0` | MIT | `https://github.com/nodejs/node/blob/main/LICENSE` |
| npm | `12.0.2` | ISC | `https://github.com/npm/cli` |
| Terraform | `1.15.8` | MPL-2.0 | `https://github.com/hashicorp/terraform` |

O badge MIT descreve apenas o conteudo original deste repositorio. Componentes de terceiros permanecem sob suas respectivas licencas. Consulte `https://github.com/lzocateli/containers/blob/main/LICENSING.md`.

## Historico de alteracoes

Mudancas observaveis desta imagem devem ser registradas por tag imutavel no fluxo de release.

O Dockerfile do `devops` e o contrato unificado para os consumidores que precisam da toolbox completa. Terraform agora faz parte dessa imagem e nao e mantido como imagem independente neste repositorio.
