<!--
SPDX-FileCopyrightText: 2024 Lincoln Zocateli
SPDX-License-Identifier: MIT
-->

# Gitleaks 8.30.1

![Docker Hub](https://img.shields.io/badge/image-lzocateli%2Fgitleaks-2496ED?logo=docker&logoColor=white)
![Version](https://img.shields.io/badge/version-8.30.1-2E7D32)
![Base](https://img.shields.io/badge/base-zricethezav%2Fgitleaks%3Av8.30.1-555555?logo=docker&logoColor=white)
![Platforms](https://img.shields.io/badge/platforms-linux%2Famd64%20%7C%20linux%2Farm64-607D8B)
![Repository code license](https://img.shields.io/badge/repository_code-MIT-1565C0)
![Build](https://img.shields.io/badge/build-validado-success)

Imagem CLI sem daemon para executar Gitleaks 8.30.1 em arquivos, diffs e
historico Git. O contrato preserva o entrypoint upstream `gitleaks`, sem portas,
volumes obrigatorios ou servico persistente.

## Referencia da imagem

| Item | Valor |
| --- | --- |
| Imagem | `lzocateli/gitleaks:8.30.1` |
| Imagem base | `zricethezav/gitleaks:v8.30.1` |
| Digest da base | `sha256:c00b6bd0aeb3071cbcb79009cb16a60dd9e0a7c60e2be9ab65d25e6bc8abbb7f` |
| Gitleaks | `8.30.1` |
| Plataformas | `linux/amd64`, `linux/arm64` |
| Usuario padrao | `root` (contrato upstream; sem shell ou daemon adicional) |
| Entry point | `gitleaks` |
| Comando padrao | `gitleaks version` |
| Diretorio de trabalho | `/repo` |
| Portas | Nenhuma |
| Volumes | Nenhum obrigatorio; monte o repositorio como `ro` |
| Codigo-fonte | `https://github.com/lzocateli/containers/tree/main/gitleaks` |
| Documentacao | `https://github.com/lzocateli/containers/tree/main/gitleaks` |

## Conteudo e finalidade

### Incluido

- Gitleaks 8.30.1 e sua configuracao upstream padrao.
- Entry point `gitleaks` para os comandos `git`, `dir` e `stdin`.
- Labels OCI do projeto `lzocateli/containers`.

### Nao incluido

- Daemon, servidor HTTP, interface web ou banco de dados.
- Reescrita de historico, revogacao de credenciais ou gerenciamento de secrets.
- Regras privadas, tokens ou configuracoes especificas do consumidor.

## Inicio rapido

```bash
docker pull lzocateli/gitleaks:8.30.1
docker run --rm lzocateli/gitleaks:8.30.1 version
```

Escanear arquivos atuais:

```bash
docker run --rm --read-only \
  --volume "$PWD:/repo:ro" \
  lzocateli/gitleaks:8.30.1 \
  dir --redact /repo
```

Escanear o historico completo de um clone:

```bash
docker run --rm --read-only \
  --volume "$PWD:/repo:ro" \
  --workdir /repo \
  lzocateli/gitleaks:8.30.1 \
  git --redact --log-opts="--all" .
```

Escanear somente o diff staged sem permitir escrita no repositorio:

```bash
git diff --cached --binary | docker run --rm -i --read-only \
  lzocateli/gitleaks:8.30.1 \
  stdin --redact
```

## Docker Compose

A imagem nao e um servico persistente. Quando for conveniente padronizar uma
execucao local, use um servico de tarefa:

```yaml
services:
  gitleaks:
    image: lzocateli/gitleaks:8.30.1
    working_dir: /repo
    read_only: true
    volumes:
      - /caminho/absoluto/repositorio:/repo:ro
    entrypoint: ["gitleaks"]
    command: ["git", "--redact", "--log-opts=--all", "."]
```

## Configuracao

### Variaveis de ambiente

| Variavel | Obrigatoria | Secreta | Padrao | Descricao |
| --- | --- | --- | --- | --- |
| Nenhuma | Nao | Nao | N/A | Passe as opcoes do Gitleaks como argumentos. |

Uma configuracao customizada pode ser montada como arquivo somente leitura e
informada com `--config /repo/.gitleaks.toml`. Nunca coloque tokens ou valores
reais no arquivo de configuracao.

### Portas

A imagem nao expoe portas e nao deve ser publicada como servidor.

### Persistencia e mounts

| Caminho no conteiner | Modo | Conteudo | Backup necessario |
| --- | --- | --- | --- |
| `/repo` | `ro` | Clone ou arquivos a serem examinados | Nao |

Relatorios devem ser gravados fora do repositorio, por exemplo em um volume de
saida separado. Revise relatorios antes de compartilha-los: use `--redact` para
impedir a inclusao do valor detectado.

### Secrets

Nao forneca credenciais ao container. Gitleaks procura credenciais no conteudo
montado, mas nao precisa de um token para executar scans locais. Em CI, use
somente `contents: read` quando o checkout privado exigir autenticacao.

## Inicializacao e ciclo de vida

O processo PID 1 e o binario `gitleaks`; o container executa uma verificacao e
termina. Codigo `0` significa nenhum achado, `1` significa achado ou falha e
`126` indica uso de comando invalido. Nao ha bootstrap, migration ou healthcheck
porque nao existe um processo persistente para monitorar.

## Seguranca

- Prefira `--read-only` e mounts `:ro`.
- Nao monte o socket Docker nem use `--privileged`.
- Nao inclua `.git`, `.env` ou credenciais no build context.
- O usuario upstream e `root` para preservar compatibilidade de leitura com
  clones e mounts de consumidores; a imagem nao instala shell administrativo,
  compilador ou cliente de rede adicional.
- Use `--redact` em execucoes automatizadas e nao publique relatorios brutos.
- Um achado exige revogar/rotacionar a credencial; apagar o arquivo nao invalida
  o valor que ja foi exposto.

## Build local

```bash
docker buildx build \
  --pull \
  --platform linux/amd64 \
  --tag lzocateli/gitleaks:8.30.1 \
  --file gitleaks/Dockerfile \
  gitleaks
```

Build multi-plataforma:

```bash
docker buildx build \
  --pull \
  --platform linux/amd64,linux/arm64 \
  --tag lzocateli/gitleaks:8.30.1 \
  --file gitleaks/Dockerfile \
  gitleaks
```

## Tags e compatibilidade

| Tag | Mutabilidade | Compatibilidade | Uso recomendado |
| --- | --- | --- | --- |
| `8.30.1` | Imutavel | Gitleaks 8.30.1, CLI upstream | CI e auditoria local |

Nao use `latest` como unica referencia. Atualizacoes de Gitleaks devem criar
uma nova tag imutavel, atualizar o digest da base, executar os scans e atualizar
este README.

## Validacao

Antes da publicacao, confirme:

- `.gitignore` e `.dockerignore` presentes;
- `.env`, secrets e `.git` fora do contexto Docker;
- `docker buildx build --check` sem erros;
- build para `linux/amd64` e `linux/arm64`;
- `gitleaks version` com a versao esperada;
- scan de diretorio com mount somente leitura;
- smoke test em `scripts/smoke-test.sh`;
- scan Trivy, SBOM e proveniencia no workflow oficial.

Execucao local do smoke test:

```bash
bash gitleaks/scripts/smoke-test.sh --help
bash gitleaks/scripts/smoke-test.sh --image lzocateli/gitleaks:8.30.1
```

## Publicacao

Use **Actions > Publicar imagem de container > Run workflow** com:

- `context_path`: `gitleaks`;
- `image_name`: `gitleaks`;
- `image_tag`: `8.30.1`;
- `dockerfile`: `Dockerfile`;
- `platforms`: `linux/amd64,linux/arm64`.

O workflow oficial executa os gates de BuildKit, Trivy, SBOM e proveniencia
antes do login e do push no Docker Hub.

## Operacao

Para CI, prefira o scan historico com checkout completo (`fetch-depth: 0`). Para
hooks locais, envie `git diff --cached --binary` ao comando `stdin`. Nao use
`SKIP` para ignorar um achado real; trate falso positivo somente com uma regra
revisada e sem inserir o valor secreto na allowlist.

## Troubleshooting

| Sintoma | Causa provavel | Verificacao | Correcao |
| --- | --- | --- | --- |
| `no leaks found` com clone incompleto | Historico truncado | verificar `fetch-depth` | usar checkout completo e `--log-opts=--all` |
| `permission denied` ao ler repo | Mount ou permissoes restritos | testar mount `:ro` | ajustar permissao de leitura sem usar `--privileged` |
| `image not found` | Tag local ausente | `docker image inspect` | construir ou baixar `lzocateli/gitleaks:8.30.1` |
| O scan bloqueia commit | Achado real ou falso positivo | revisar regra, arquivo e commit sem expor o segredo | revogar/rotacionar ou documentar excecao segura |

## Limitacoes conhecidas

- O scanner nao revoga credenciais nem limpa historico Git.
- O scan historico cobre as refs presentes no clone; refs remotas removidas
  anteriormente exigem auditoria adicional.
- A imagem upstream e mantida como CLI; nao ha servidor ou endpoint de health.
- Relatorios podem conter contexto sensivel; use `--redact` e controle o destino.

## Licencas e fontes

| Componente | Versao | Licenca | Fonte |
| --- | --- | --- | --- |
| Conteudo original deste repositorio | Atual | MIT | `https://github.com/lzocateli/containers` |
| Gitleaks | 8.30.1 | MIT | `https://github.com/gitleaks/gitleaks` |
| Imagem base upstream | v8.30.1 | MIT | `https://hub.docker.com/r/zricethezav/gitleaks` |

O badge MIT descreve somente o conteudo original deste repositorio. Componentes
de terceiros permanecem sujeitos aos seus termos e avisos de licenca. Consulte a
[politica de licenciamento](https://github.com/lzocateli/containers/blob/main/LICENSING.md)
e preserve os avisos upstream.

## Historico de alteracoes

- `8.30.1`: adiciona a imagem CLI baseada no digest upstream de Gitleaks 8.30.1.
