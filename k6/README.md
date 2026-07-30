<!--
SPDX-FileCopyrightText: 2024 Lincoln Zocateli
SPDX-License-Identifier: MIT
-->

# k6 sobre Node.js 24 LTS hardened

![Docker Hub](https://img.shields.io/badge/image-lzocateli%2Fk6-2496ED?logo=docker&logoColor=white)
![Version](https://img.shields.io/badge/version-2.1.0--node24.15.0--bookworm-2E7D32)
![Base](https://img.shields.io/badge/base-lzocateli%2Fnode%3A24.15.0--bookworm-555555?logo=docker&logoColor=white)
![Platforms](https://img.shields.io/badge/platforms-linux%2Famd64-607D8B)
![Repository code license](https://img.shields.io/badge/repository_code-MIT-1565C0)
![Build](https://img.shields.io/badge/build-validado-success)

Imagem para execução isolada do k6, baseada em `lzocateli/node:24.15.0-bookworm`, com binário oficial do k6 copiado da imagem upstream `grafana/k6` fixada por digest imutável.

## Referência da imagem

| Item | Valor |
| --- | --- |
| Imagem | `lzocateli/k6:2.1.0-node24.15.0-bookworm` |
| Imagem base | `lzocateli/node:24.15.0-bookworm` |
| Binário k6 | `grafana/k6:2.1.0@sha256:65c920dc067d5e2e00befbf982af6ad6ad0117034e8b1c65817c7975c52d4669` |
| Plataformas | `linux/amd64` |
| Usuário padrão | `node` |
| Entry point | `k6` |
| Comando padrão | `k6 version` |
| Diretório de trabalho | `/workspace` |
| Código-fonte | `https://github.com/lzocateli/containers/tree/main/k6` |
| Documentação | `https://github.com/lzocateli/containers/tree/main/k6` |

## Conteúdo e finalidade

### Incluído

- Binário `k6` versão 2.1.0.
- Runtime Node.js 24 LTS hardened herdado da imagem base.
- Execução padrão em usuário não root.

### Não incluído

- Scripts de teste prontos.
- Dashboard remoto, outputs externos ou credenciais.
- Extensões customizadas de k6 compiladas sob medida.

## Início rápido

```bash
docker pull lzocateli/k6:2.1.0-node24.15.0-bookworm
docker run --rm lzocateli/k6:2.1.0-node24.15.0-bookworm version
```

Exemplo com script local:

```bash
docker run --rm \
  --workdir /workspace \
  --volume "$(pwd):/workspace" \
  lzocateli/k6:2.1.0-node24.15.0-bookworm \
  run script.js
```

## Docker Compose

```yaml
services:
  k6:
    image: lzocateli/k6:2.1.0-node24.15.0-bookworm
    working_dir: /workspace
    user: "node"
    volumes:
      - /caminho/absoluto/testes-k6:/workspace
    command: ["run", "script.js"]
```

## Configuração

### Variáveis de ambiente

| Variável | Obrigatória | Secreta | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| `K6_OUT` | Não | Não | nenhum | Define output de métricas (`json=...`, `influxdb=...`, etc.). |
| `K6_VUS` | Não | Não | do script | Sobrescreve VUs na execução. |
| `K6_DURATION` | Não | Não | do script | Sobrescreve duração na execução. |

### Portas

Nenhuma porta pública faz parte do contrato desta imagem base.

### Persistência e mounts

| Caminho no contêiner | Modo | Conteúdo | Backup necessário |
| --- | --- | --- | --- |
| `/workspace` | `rw` | Scripts e artefatos de teste | Sim |

### Secrets

Forneça tokens e credenciais via runtime (`--env-file` ou secrets do orquestrador). Não grave valores sensíveis no Dockerfile nem em scripts versionados.

## Inicialização e ciclo de vida

A imagem inicia com `k6` como entrypoint. O comando padrão `version` pode ser sobrescrito por `run`, `inspect` ou outros subcomandos.

## Segurança

- Execução como usuário `node` (não root).
- Sem portas expostas por padrão.
- Herda hardening e baseline de segurança da imagem base `lzocateli/node`.

## Build local

Como a base `lzocateli/node:24.15.0-bookworm` pode ainda não estar publicada, gere localmente antes:

```bash
docker build --pull --tag lzocateli/node:24.15.0-bookworm node
```

Depois gere a imagem k6:

```bash
docker build --pull --tag lzocateli/k6:2.1.0-node24.15.0-bookworm k6
```

## Tags e compatibilidade

| Tag | Mutabilidade | Compatibilidade | Uso recomendado |
| --- | --- | --- | --- |
| `2.1.0-node24.15.0-bookworm` | Imutável | k6 2.1.0 + Node 24.15.0 LTS | Produção e CI |

## Validação

Antes da publicação, confirme:

- `.gitignore` e `.dockerignore` presentes e atualizados;
- exclusão de `.env`, secrets e `.git` do contexto Docker;
- `docker buildx build --check` sem erros;
- build para `linux/amd64`;
- `k6 version` executando com sucesso;
- scan de vulnerabilidades, SBOM e proveniência no workflow oficial.

## Publicação

Use **Actions > Publicar imagem de container > Run workflow** com:

- `context_path`: `k6`;
- `image_name`: `k6`;
- `image_tag`: `2.1.0-node24.15.0-bookworm`;
- `dockerfile`: `Dockerfile`;
- `platforms`: `linux/amd64`.

## Operação

- Versione scripts de carga junto do código da aplicação.
- Execute testes em rede isolada para evitar impacto em produção.
- Preserve relatórios em volume do host quando necessário.

## Troubleshooting

| Sintoma | Causa provável | Verificação | Correção |
| --- | --- | --- | --- |
| `ERRO[0000] open script.js: no such file or directory` | Script não montado em `/workspace` | `ls -la /workspace` no contêiner | Ajustar bind mount e caminho do comando `run`. |
| `permission denied` ao gravar output | Volume do host sem permissão para usuário `node` | checar proprietário/permissões no host | Ajustar permissões no diretório montado. |
| Falha ao enviar métricas externas | URL/token inválido em `K6_OUT` | revisar env vars e logs | Corrigir endpoint e credenciais do backend de métricas. |

## Limitações conhecidas

- Plataforma validada neste repositório: `linux/amd64`.
- Não inclui extensões customizadas do ecossistema xk6.

## Licenças e fontes

| Componente | Versão | Licença | Fonte |
| --- | --- | --- | --- |
| Conteúdo original deste repositório | Atual | MIT | `https://github.com/lzocateli/containers` |
| k6 | 2.1.0 | AGPL-3.0 | `https://github.com/grafana/k6` |
| Imagem base `lzocateli/node` | 24.15.0-bookworm | MIT (conteúdo empacotado pelo projeto) | `https://github.com/lzocateli/containers/tree/main/node` |

O badge MIT descreve somente o conteúdo original deste repositório. Componentes de terceiros permanecem sujeitos aos seus termos e avisos de licença. Consulte a política de licenciamento: https://github.com/lzocateli/containers/blob/main/LICENSING.md.

## Histórico de alterações

- `2.1.0-node24.15.0-bookworm`: atualização para k6 2.1.0 com pin por digest imutável para evitar deriva de tag e reaparição de CVEs críticos do binário Go no CI.
