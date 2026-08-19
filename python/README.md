<!--
SPDX-FileCopyrightText: 2024 Lincoln Zocateli
SPDX-License-Identifier: MIT
-->

# lzocateli/python

![Docker Hub](https://img.shields.io/badge/image-lzocateli%2Fpython-2496ED?logo=docker&logoColor=white)
![Version](https://img.shields.io/badge/version-3.14--bookworm-2E7D32)
![Base](https://img.shields.io/badge/base-python%3A3.14--bookworm-555555?logo=docker&logoColor=white)
![Platforms](https://img.shields.io/badge/platforms-linux%2Famd64%2Clinux%2Farm64-607D8B)
![Repository code license](https://img.shields.io/badge/repository_code-MIT-1565C0)
![Build](https://img.shields.io/badge/build-validado-success)

Imagem base do Python 3.14 para execução de scripts, automações e workloads leves em ambientes locais e CI. A imagem mantém a distribuição oficial do Python e inclui o gerenciador de dependências `uv` na versão estável mais recente.

## Referência da imagem

| Item | Valor |
| --- | --- |
| Imagem | `lzocateli/python:3.14-bookworm` |
| Imagem base | `python:3.14-bookworm` |
| Plataformas | `linux/amd64`, `linux/arm64` |
| Usuário padrão | `root` |
| Entry point | `python3` |
| Diretório de trabalho | `/workspace` |
| Código-fonte | `https://github.com/lzocateli/containers/tree/main/python` |
| Documentação | `https://github.com/lzocateli/containers/tree/main/python` |

## Conteúdo e finalidade

### Incluído

- Python 3.14.
- `ca-certificates`, `curl` e `tzdata` para execução segura e automações.
- `uv` instalado na última versão estável do instalador oficial.
- `/workspace` como diretório de trabalho para montar projetos.

### Não incluído

- Frameworks extras instalados por padrão.
- Dependências específicas de aplicativo.
- Configuração de serviços externos.

## Início rápido

```bash
docker pull lzocateli/python:3.14-bookworm
docker run --rm -v "$PWD":/workspace -w /workspace lzocateli/python:3.14-bookworm -c "import sys; print(sys.version)"
```

## Docker Compose

```yaml
services:
  python:
    image: lzocateli/python:3.14-bookworm
    working_dir: /workspace
    volumes:
      - .:/workspace
    command: ["-c", "print('hello from python 3.14')"]
```

## Configuração

### Variáveis de ambiente

| Variável | Obrigatória | Secreta | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| `PYTHONUNBUFFERED` | Não | Não | `1` | Flush imediato de stdout/stderr. |
| `PIP_INDEX_URL` | Não | Não | Nenhum | URL do índice de pacotes. |
| `UV_CACHE_DIR` | Não | Não | `~/.cache/uv` | Diretório de cache do `uv`. |

### Portas

Nenhuma porta pública é exposta por padrão. Use a imagem para execução de scripts ou serviços em portas escolhidas pelo consumidor.

### Persistência e mounts

| Caminho no contêiner | Modo | Conteúdo | Backup necessário |
| --- | --- | --- | --- |
| `/workspace` | `rw` | Código e arquivos gerados localmente | Sim, quando houver artefatos relevantes |

## Inicialização e ciclo de vida

A imagem usa `python3` como entrypoint e a execução padrão é mostrar a versão do interpretador. O consumidor normalmente monta o diretório do projeto em `/workspace` e invoca `python`, `pip` ou `uv` para processar scripts, dependências e projetos Python.

## Segurança

- Mantenha segredos fora do Dockerfile e do contexto do build.
- Use arquivos de ambiente ou abstrações de secret do runtime para segredos e tokens.
- Evite execução de imagens como root em produção quando o projeto permitir ajuste de usuário.
- O `uv` é instalado via instalador oficial do projeto Astral, na versão estável mais recente disponível.

## Build local

```bash
docker build \
  --pull \
  --tag lzocateli/python:3.14-bookworm \
  .
```

## Tags e compatibilidade

| Tag | Mutabilidade | Compatibilidade | Uso recomendado |
| --- | --- | --- | --- |
| `3.14-bookworm` | Imutável | Python 3.14 em Debian Bookworm | Scripts, automações e desenvolvimento |

## Validação

Antes da publicação, confirme:

- `.gitignore` e `.dockerignore` presentes;
- build com Dockerfile válido;
- `python3 --version` funcionando;
- `uv --version` funcionando;
- workspace montado sem segredos;
- labels OCI presentes;
- canais de rede e dependências verificadas.

## Publicação

Use **Actions > Publicar imagem de container > Run workflow** e informe:

- `context_path`: `python`;
- `image_name`: `python`;
- `image_tag`: `3.14-bookworm`;
- `dockerfile`: `Dockerfile`;
- `platforms`: `linux/amd64,linux/arm64`.

## Operação

- Monte o projeto em `/workspace`.
- Instale dependências durante o build ou em runtime conforme a necessidade do aplicativo.
- Use `uv sync`, `uv add` e `uv run` para gerenciamento moderno de projetos Python.
- Para executáveis em produção, preferir imagens específicas do serviço, não apenas esta base.

## Troubleshooting

| Sintoma | Causa provável | Verificação | Correção |
| --- | --- | --- | --- |
| `python: command not found` | Imagem incorreta ou build quebrado | Execute `docker run --rm lzocateli/python:3.14-bookworm --version` | Validar build e tag |
| `uv: command not found` | Instalador falhou ou PATH incorreto | Execute `docker run --rm lzocateli/python:3.14-bookworm uv --version` | Validar instalação do instalador e PATH |
| Dependências ausentes | Ambiente da imagem sem pacotes extras | Verificar `pip install` no runtime | Faça instalação explicitamente no build ou no container |

## Limitações conhecidas

- Esta imagem é uma base, não uma imagem de aplicação final.
- Dependências de serviço devem ser adicionadas por contexto do projeto.

## Licenças e fontes

| Componente | Versão | Licença | Fonte |
| --- | --- | --- | --- |
| Conteúdo original deste repositório | Atual | MIT | `https://github.com/lzocateli/containers` |
| Imagem base | `python:3.14-bookworm` | Python Software Foundation License | `https://hub.docker.com/_/python` |
| Gerenciador UV | Última estável | MIT | `https://github.com/astral-sh/uv` |

O badge MIT descreve somente o conteúdo original deste repositório. A imagem inclui componentes de terceiros que permanecem sujeitos aos termos e avisos de suas fontes. Consulte a [política de licenciamento](https://github.com/lzocateli/containers/blob/main/LICENSING.md).

## Histórico de alterações

- 2026-08-19: atualização da imagem para Python 3.14 e instalação do UV na última versão estável.
