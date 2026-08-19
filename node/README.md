<!--
SPDX-FileCopyrightText: 2024 Lincoln Zocateli
SPDX-License-Identifier: MIT
-->

# Node.js 24 LTS hardened

![Docker Hub](https://img.shields.io/badge/image-lzocateli%2Fnode-2496ED?logo=docker&logoColor=white)
![Version](https://img.shields.io/badge/version-24.15.0--bookworm-2E7D32)
![Base](https://img.shields.io/badge/base-node%3A24.15.0--bookworm-555555?logo=docker&logoColor=white)
![Platforms](https://img.shields.io/badge/platforms-linux%2Famd64-607D8B)
![Repository code license](https://img.shields.io/badge/repository_code-MIT-1565C0)
![Build](https://img.shields.io/badge/build-validado-success)

Imagem baseada em Node.js 24 LTS (Debian Bookworm), com `npm`, `npx` e `corepack` habilitado. O foco e suportar pipelines e desenvolvimento JavaScript/TypeScript com runtime LTS estavel, com hardening para reduzir CVEs criticas reportadas em scans de seguranca.

## Referencia da imagem

| Item | Valor |
| --- | --- |
| Imagem | `lzocateli/node:24.15.0-bookworm` |
| Imagem base | `node:24.15.0-bookworm` |
| Plataformas | `linux/amd64` |
| Usuario padrao | `node` |
| Entry point | herdado da imagem base (`docker-entrypoint.sh`) |
| Comando padrao | `node --version` |
| Diretorio de trabalho | `/workspace` |
| Corepack | habilitado |
| Codigo-fonte | `https://github.com/lzocateli/containers/tree/main/node` |
| Documentacao | `https://github.com/lzocateli/containers/tree/main/node` |

## Conteudo e finalidade

### Incluido

- Node.js 24 LTS.
- npm e npx distribuidos com o Node oficial (npm atualizado para 12.0.2).
- Corepack habilitado para pnpm/yarn quando exigido pelo projeto.
- Usuario nao root (`node`) por padrao.
- Remocao de pacotes Debian desnecessarios de toolchain (ImageMagick/MariaDB dev) para reduzir superficie de ataque.

### Nao incluido

- Angular CLI global preinstalado.
- Codigo de aplicacao, dependencias de projeto e cache de pacotes.
- Ferramentas de navegador (Chrome/Playwright) para E2E.

## Compatibilidade

Esta imagem e base generica para workloads Node.js e TypeScript. Para uso com Angular CLI, prefira a imagem dedicada `lzocateli/angular-cli`, que herda desta base e adiciona somente os componentes especificos de CLI.

## Inicio rapido

```bash
docker pull lzocateli/node:24.15.0-bookworm
docker run --rm lzocateli/node:24.15.0-bookworm node --version
```

Exemplo com projeto Node local:

```bash
docker run --rm \
  --workdir /workspace \
  --volume "$(pwd):/workspace" \
  lzocateli/node:24.15.0-bookworm \
  sh -lc "npm ci && npm run -s build || npm test"
```

## Docker Compose

```yaml
services:
  node:
    image: lzocateli/node:24.15.0-bookworm
    working_dir: /workspace
    user: "node"
    volumes:
      - /caminho/absoluto/projeto:/workspace
    command: ["sh", "-lc", "node --version && npm --version"]
```

## Configuracao

### Variaveis de ambiente

| Variavel | Obrigatoria | Secreta | Padrao | Descricao |
| --- | --- | --- | --- | --- |
| `NPM_CONFIG_CACHE` | Nao | Nao | padrao do npm | Local do cache de pacotes. |
| `CI` | Nao | Nao | vazio | Ativa comportamento de pipeline em varios toolings. |

### Portas

Nenhuma porta publica faz parte do contrato desta imagem base.

### Persistencia e mounts

| Caminho no conteiner | Modo | Conteudo | Backup necessario |
| --- | --- | --- | --- |
| `/workspace` | `rw` | Codigo-fonte e arquivos do projeto montado | Sim |

### Secrets

Forneca token de registry e credenciais de npm via runtime (`--env-file`, secrets do CI ou provider do orquestrador). Nao grave secrets no Dockerfile nem em arquivos versionados.

## Inicializacao e ciclo de vida

O entrypoint da imagem base Node e preservado. O processo padrao executa `node --version`; em uso real, o comando e sobrescrito para `npm ci`, `npm run build`, `npx ng ...` ou scripts do projeto.

## Seguranca

- Execucao como usuario `node` (nao root).
- Sem exposicao de portas por padrao.
- Nao persistir tokens npm no repositorio ou na imagem.
- Prefira lockfiles versionados para reproducibilidade.
- Atualizacao de `libgnutls30` e npm para mitigar vulnerabilidades criticas com correcao disponivel.

## Build local

```bash
docker build --pull --tag lzocateli/node:24.15.0-bookworm node
```

Para validar Angular 22 localmente:

```bash
docker run --rm lzocateli/node:24.15.0-bookworm sh -lc "npx -y @angular/cli@22 version"
```

## Tags e compatibilidade

| Tag | Mutabilidade | Compatibilidade | Uso recomendado |
| --- | --- | --- | --- |
| `24.15.0-bookworm` | Imutavel | Node.js 24 LTS hardened | Producao e CI |
| `24-bookworm` | Movel | Ultimo patch da linha 24 LTS | Homologacao controlada |

Prefira tags imutaveis em pipelines e releases.

## Validacao

Antes da publicacao, confirme:

- `.gitignore` e `.dockerignore` presentes e atualizados;
- exclusao de `.env`, secrets e `.git` do contexto Docker;
- `docker buildx build --check` sem erros;
- build para `linux/amd64`;
- `node --version` e `npm --version` executando com sucesso;
- validacao de `npm ls -g tar` com versao `7.5.19` ou superior;
- validacao de ausenca de pacotes legados via `dpkg -l` (imagemagick/libmariadb/linux-libc-dev) no container final;
- scan de vulnerabilidades, SBOM e proveniencia no workflow oficial.

## Publicacao

Use **Actions > Publicar imagem de container > Run workflow** com:

- `context_path`: `node`;
- `image_name`: `node`;
- `image_tag`: `24.15.0-bookworm`;
- `dockerfile`: `Dockerfile`;
- `platforms`: `linux/amd64`.

## Troubleshooting

| Sintoma | Causa provavel | Verificacao | Correcao |
| --- | --- | --- | --- |
| `npm ERR! EACCES` | Permissao de escrita no bind mount | `id` e dono dos arquivos no host | Ajustar permissao do diretorio no host para usuario do container. |
| `npx` nao encontra pacote | Dependencia local ausente ou registry privado sem auth | `npm config list` e `npm whoami` | Configurar auth no runtime (`.npmrc`/token) e reinstalar dependencias. |
| `npm ci` falha por lockfile | lockfile fora de sincronia | comparar `package.json` e lockfile | Regenerar lockfile no mesmo major do npm usado no CI. |

## Limitacoes conhecidas

- Plataforma validada neste repositorio: `linux/amd64`.
- A imagem nao inclui navegadores para testes E2E.
- A imagem nao inclui Angular CLI global por padrao.

## Licencas e fontes

| Componente | Versao | Licenca | Fonte |
| --- | --- | --- | --- |
| Conteudo original deste repositorio | Atual | MIT | `https://github.com/lzocateli/containers` |
| Node.js | 24.15.0 | MIT | `https://github.com/nodejs/node/blob/main/LICENSE` |
| Imagem base Node oficial | 24.15.0-bookworm | MIT | `https://hub.docker.com/_/node` |

O badge MIT descreve somente o conteudo original deste repositorio. Componentes de terceiros permanecem sujeitos aos seus termos e avisos de licenca. Consulte a politica de licenciamento: https://github.com/lzocateli/containers/blob/main/LICENSING.md.

## Historico de alteracoes

- `24.15.0-bookworm`: adiciona hardening de seguranca (upgrade de `libgnutls30`, npm 12.0.2 e remocao de pacotes Debian desnecessarios) para uso generico como base Node LTS.

