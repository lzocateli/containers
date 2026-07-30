<!--
SPDX-FileCopyrightText: 2024 Lincoln Zocateli
SPDX-License-Identifier: MIT
-->

# Angular CLI 22 sobre Node.js 24 LTS

![Docker Hub](https://img.shields.io/badge/image-lzocateli%2Fangular--cli-2496ED?logo=docker&logoColor=white)
![Version](https://img.shields.io/badge/version-22.1.0--node24.15.0--bookworm-2E7D32)
![Base](https://img.shields.io/badge/base-lzocateli%2Fnode%3A24.15.0--bookworm-555555?logo=docker&logoColor=white)
![Platforms](https://img.shields.io/badge/platforms-linux%2Famd64-607D8B)
![Repository code license](https://img.shields.io/badge/repository_code-MIT-1565C0)
![Build](https://img.shields.io/badge/build-validado-success)

Imagem para uso de Angular CLI 22 em ambiente containerizado, baseada em `lzocateli/node:24.15.0-bookworm` e preparada para scaffolding, build e `ng serve` em projetos Angular.

## Referencia da imagem

| Item | Valor |
| --- | --- |
| Imagem | `lzocateli/angular-cli:22.1.0-node24.15.0-bookworm` |
| Imagem base | `lzocateli/node:24.15.0-bookworm` |
| Angular CLI | `22.1.0` |
| Node.js | `24.15.0` |
| Plataformas | `linux/amd64` |
| Usuario padrao | `node` |
| Entry point | `/usr/local/bin/angular-entrypoint.sh` |
| Comando padrao | `ng version` |
| Diretorio de trabalho | `/workspace` |
| Porta exposta | `4200/tcp` |
| Codigo-fonte | `https://github.com/lzocateli/containers/tree/main/angular-cli` |
| Documentacao | `https://github.com/lzocateli/containers/tree/main/angular-cli` |

## Conteudo e finalidade

### Incluido

- Angular CLI 22 instalado globalmente.
- Node.js 24 LTS via imagem base `lzocateli/node`.
- Entrypoint que redireciona comandos desconhecidos para `ng`.

### Nao incluido

- Projeto Angular pronto ou dependencias de aplicacao.
- Navegadores para testes E2E.
- Secrets, tokens de registry e arquivos `.npmrc` sensiveis.

## Inicio rapido

```bash
docker pull lzocateli/angular-cli:22.1.0-node24.15.0-bookworm
docker run --rm lzocateli/angular-cli:22.1.0-node24.15.0-bookworm ng version
```

Executar comandos `ng` em projeto local:

```bash
docker run --rm -it \
  -v "$(pwd):/workspace" \
  -w /workspace \
  -p 4200:4200 \
  lzocateli/angular-cli:22.1.0-node24.15.0-bookworm \
  ng serve --host 0.0.0.0
```

## Docker Compose

```yaml
services:
  angular-cli:
    image: lzocateli/angular-cli:22.1.0-node24.15.0-bookworm
    working_dir: /workspace
    user: "node"
    command: ["ng", "version"]
    ports:
      - "4200:4200"
    volumes:
      - /caminho/absoluto/projeto-angular:/workspace
```

## Configuracao

### Variaveis de ambiente

| Variavel | Obrigatoria | Secreta | Padrao | Descricao |
| --- | --- | --- | --- | --- |
| `NG_CLI_ANALYTICS` | Nao | Nao | `false` | Desativa telemetria do Angular CLI. |
| `CI` | Nao | Nao | vazio | Ativa comportamento de pipeline em ferramentas Node. |

### Portas

| Porta | Protocolo | Exposicao recomendada | Finalidade |
| --- | --- | --- | --- |
| `4200/tcp` | HTTP | localhost ou rede interna | `ng serve` durante desenvolvimento. |

### Persistencia e mounts

| Caminho no conteiner | Modo | Conteudo | Backup necessario |
| --- | --- | --- | --- |
| `/workspace` | `rw` | Codigo-fonte da aplicacao Angular | Sim |

### Secrets

Forneca secrets de npm/registry apenas em runtime. Nao armazene `.npmrc` com tokens no repositorio nem no contexto de build.

## Inicializacao e ciclo de vida

O entrypoint `angular-entrypoint.sh` executa o comando recebido; quando o primeiro argumento nao e um executavel do sistema ou for uma flag, ele antepoe `ng` automaticamente para facilitar o uso.

## Seguranca

- Container executa como usuario `node` por padrao.
- Sem privilegios extras ou bind mounts sensiveis obrigatorios.
- Evite montar credenciais no workspace quando nao forem necessarias.

## Build local

Como a base `lzocateli/node:24.15.0-bookworm` ainda nao foi publicada no registry, gere localmente antes:

```bash
docker build --pull --tag lzocateli/node:24.15.0-bookworm node
```

Depois, gere a imagem angular-cli:

```bash
docker build --pull --tag lzocateli/angular-cli:22.1.0-node24.15.0-bookworm angular-cli
```

## Tags e compatibilidade

| Tag | Mutabilidade | Compatibilidade | Uso recomendado |
| --- | --- | --- | --- |
| `22.1.0-node24.15.0-bookworm` | Imutavel | Angular CLI 22.1.0 + Node 24.15.0 LTS | Producao e CI |

Use sempre tags imutaveis em pipeline.

## Validacao

Antes da publicacao, confirme:

- `.gitignore` e `.dockerignore` presentes e atualizados;
- exclusao de `.env`, secrets e `.git` do contexto Docker;
- `docker buildx build --check` sem erros;
- build para `linux/amd64`;
- `ng version` executando com Node 24.15.0 e Angular CLI 22;
- scan de vulnerabilidades, SBOM e proveniencia no workflow oficial.

## Publicacao

Use **Actions > Publicar imagem de container > Run workflow** com:

- `context_path`: `angular-cli`;
- `image_name`: `angular-cli`;
- `image_tag`: `22.1.0-node24.15.0-bookworm`;
- `dockerfile`: `Dockerfile`;
- `platforms`: `linux/amd64`.

## Troubleshooting

| Sintoma | Causa provavel | Verificacao | Correcao |
| --- | --- | --- | --- |
| `ng` nao inicia | comando sem bind mount do projeto | conferir `-v` e `-w` | montar workspace em `/workspace`. |
| `EACCES` em `node_modules` | permissao do host incompativel com usuario `node` | verificar dono/permissoes | ajustar permissoes no host. |
| porta 4200 em uso | conflito local | verificar processo escutando | publicar outra porta no host (`-p 4300:4200`). |

## Limitacoes conhecidas

- Plataforma validada neste repositorio: `linux/amd64`.
- Imagem nao inclui navegador para E2E.
- Requer imagem base `lzocateli/node:24.15.0-bookworm` disponivel localmente ou publicada.

## Licencas e fontes

| Componente | Versao | Licenca | Fonte |
| --- | --- | --- | --- |
| Conteudo original deste repositorio | Atual | MIT | `https://github.com/lzocateli/containers` |
| Angular CLI | 22.1.0 | MIT | `https://github.com/angular/angular-cli` |
| Node.js | 24.15.0 | MIT | `https://github.com/nodejs/node/blob/main/LICENSE` |
| Imagem base `lzocateli/node` | 24.15.0-bookworm | MIT (conteudo empacotado pelo projeto) | `https://github.com/lzocateli/containers/tree/main/node` |

O badge MIT descreve somente o conteudo original deste repositorio. Componentes de terceiros permanecem sujeitos aos seus termos e avisos de licenca. Consulte a politica de licenciamento: https://github.com/lzocateli/containers/blob/main/LICENSING.md.

## Historico de alteracoes

- `22.1.0-node24.15.0-bookworm`: atualiza base para Node 24 LTS, adota Angular CLI 22 e padroniza contrato da imagem.
