<!--
SPDX-FileCopyrightText: 2024 Lincoln Zocateli
SPDX-License-Identifier: MIT
-->

# Oracle Database Free

![Docker Hub](https://img.shields.io/badge/image-lzocateli%2Foracle-2496ED?logo=docker&logoColor=white)
![Version](https://img.shields.io/badge/version-23--slim-2E7D32)
![Base](https://img.shields.io/badge/base-gvenzl%2Foracle--free%3A23--slim-555555?logo=docker&logoColor=white)
![Platforms](https://img.shields.io/badge/platforms-linux%2Famd64-607D8B)
![Repository code license](https://img.shields.io/badge/repository_code-MIT-1565C0)
![Build](https://img.shields.io/badge/build-validado-success)

Imagem Oracle Database Free baseada em `gvenzl/oracle-free:23-slim`, com padrao de execucao local para desenvolvimento e homologacao em `linux/amd64`.

## Referencia da imagem

| Item | Valor |
| --- | --- |
| Imagem | `lzocateli/oracle:23-slim` |
| Imagem base | `gvenzl/oracle-free:23-slim` |
| Plataformas | `linux/amd64` |
| Usuario padrao | `oracle` |
| Entry point | `container-entrypoint.sh` (upstream) |
| Diretorio de dados | `/opt/oracle/oradata` |
| Codigo-fonte | `https://github.com/lzocateli/containers/tree/main/oracle` |
| Documentacao | `https://github.com/lzocateli/containers/tree/main/oracle` |

## Conteudo e finalidade

### Incluido

- Oracle Database Free 23c da imagem base upstream.
- Charset padrao `AL32UTF8` via `ORACLE_DATABASE_CHARSET`.
- Volume para persistencia em `/opt/oracle/oradata`.

### Nao incluido

- Backup automatico, HA/cluster ou Data Guard.
- Provisionamento de schema por defaults inseguros.
- Secrets versionados no repositorio.

## Inicio rapido

```bash
docker pull lzocateli/oracle:23-slim
mkdir -p ./data/oracle
docker run --name oracle \
  --detach \
  --publish 127.0.0.1:1521:1521 \
  --env ORACLE_PASSWORD='Troque_Esta_Senha_2026!' \
  --volume "$(pwd)/data/oracle:/opt/oracle/oradata" \
  lzocateli/oracle:23-slim
```

## Docker Compose

Use o arquivo `oracle/docker-compose.yml` com variaveis em `.env`:

```bash
cp oracle/.env.example oracle/.env
# edite oracle/.env com senhas reais
docker compose -f oracle/docker-compose.yml --env-file oracle/.env up -d
```

## Configuracao

### Variaveis de ambiente

| Variavel | Obrigatoria | Secreta | Padrao | Descricao |
| --- | --- | --- | --- | --- |
| `ORACLE_PASSWORD` | Sim | Sim | nenhum | Senha de administracao definida pela imagem base. |
| `ORACLE_DATABASE` | Nao | Nao | vazio | PDB adicional para criacao de app user (nao use `FREEPDB1`, que ja existe na imagem base). |
| `ORACLE_USER` | Nao | Nao | `app` | Usuario de aplicacao para scripts customizados. |
| `ORACLE_USER_PASSWORD` | Nao | Sim | nenhum | Senha do usuario de aplicacao. |
| `ORACLE_TABLESPACE` | Nao | Nao | `USERS` | Tablespace do usuario de aplicacao. |
| `DATA_DIR` | Nao | Nao | `./data` | Diretoria base para persistencia no Compose. |

### Portas

| Porta | Protocolo | Exposicao recomendada | Finalidade |
| --- | --- | --- | --- |
| `1521/tcp` | TCP | Localhost ou rede interna | Conexao SQL*Net com a instancia Oracle. |

### Persistencia e mounts

| Caminho no conteiner | Modo | Conteudo | Backup necessario |
| --- | --- | --- | --- |
| `/opt/oracle/oradata` | `rw` | Arquivos de dados do banco | Sim |
| `/container-entrypoint-initdb.d` | `ro` | Scripts `.sql` e `.sh` de bootstrap | Sim |

### Secrets

- Nao versionar `.env` com senhas reais.
- Fornecer segredos por `--env-file`, secret manager ou variaveis de runtime.
- Nunca passar secrets por `ARG` ou `ENV` no Dockerfile.

## Inicializacao e ciclo de vida

A imagem usa o entrypoint upstream `container-entrypoint.sh`. Na primeira inicializacao, a base cria e prepara a instancia. Scripts em `/container-entrypoint-initdb.d` sao executados pelo fluxo upstream e devem ser idempotentes.

## Seguranca

- Nao exponha `1521` diretamente na internet.
- Mantenha o mount de dados fora do Git e com controle de acesso no host.
- Execute com senha forte e rotacao periodica.
- Preserve o usuario padrao `oracle` (nao-root).

## Build local

```bash
docker build --pull --tag lzocateli/oracle:23-slim oracle
```

## Tags e compatibilidade

| Tag | Mutabilidade | Compatibilidade | Uso recomendado |
| --- | --- | --- | --- |
| `23-slim` | Imutavel | Oracle Free 23c em `linux/amd64` | Desenvolvimento e homologacao |
| `21-slim` | Legado | Versao anterior baseada em contrato antigo | Somente compatibilidade historica |

## Validacao

Antes da publicacao, valide:

- `docker buildx build --check --file oracle/Dockerfile oracle`;
- build `linux/amd64`;
- startup com `ORACLE_PASSWORD` valida;
- health check `healthcheck.sh` no Compose;
- persistencia apos reinicio;
- Trivy, SBOM e proveniencia no workflow oficial.

## Publicacao

Use **Actions > Publicar imagem de container > Run workflow** com:

- `context_path`: `oracle`;
- `image_name`: `oracle`;
- `image_tag`: `23-slim`;
- `dockerfile`: `Dockerfile`;
- `platforms`: `linux/amd64`.

## Operacao

- Agende backup consistente de `/opt/oracle/oradata`.
- Teste restore periodicamente em ambiente separado.
- Para upgrade, publique nova tag imutavel e valide migracao de dados antes do cutover.

## Troubleshooting

| Sintoma | Causa provavel | Verificacao | Correcao |
| --- | --- | --- | --- |
| Container reinicia sem subir | `ORACLE_PASSWORD` ausente/invalida | `docker logs oracle` | Definir senha valida e recriar container |
| Cliente nao conecta na 1521 | Porta nao publicada ou firewall | `docker ps` e regras de rede | Publicar em localhost/rede correta |
| Scripts nao executam | Mount incorreto ou script sem permissao | Verificar mount em `/container-entrypoint-initdb.d` | Ajustar volume e permissao de leitura |
| Dados nao persistem | Volume errado ou removido | `docker inspect` volumes/mounts | Corrigir mapeamento para `/opt/oracle/oradata` |

## Limitacoes conhecidas

- Plataforma suportada neste repositorio: somente `linux/amd64`.
- Build e smoke test completos podem exigir mais recurso local e tempo de inicializacao elevado.

## Licencas e fontes

| Componente | Versao | Licenca | Fonte |
| --- | --- | --- | --- |
| Conteudo original deste repositorio | Atual | MIT | `https://github.com/lzocateli/containers` |
| Oracle Database Free | 23c | Oracle Free Use Terms and Conditions | `https://www.oracle.com/database/free/` |
| Imagem base gvenzl/oracle-free | 23-slim | Licencas dos componentes upstream | `https://hub.docker.com/r/gvenzl/oracle-free` |

O badge MIT descreve somente o conteudo original deste repositorio. Componentes de terceiros permanecem sujeitos aos termos de suas fontes. Consulte a [politica de licenciamento](https://github.com/lzocateli/containers/blob/main/LICENSING.md).

## Historico de alteracoes

- `23-slim`: padroniza contrato da imagem, remove permissao `777`, atualiza Compose sem secrets hardcoded e alinha README ao template oficial.
