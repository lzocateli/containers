<!--
SPDX-FileCopyrightText: 2026 Lincoln Zocateli
SPDX-License-Identifier: MIT
-->

# Immich PostgreSQL

![Docker Hub](https://img.shields.io/badge/image-lzocateli%2Fimmich--postgres-2496ED?logo=docker&logoColor=white)
![Version](https://img.shields.io/badge/version-14--vc0.4.3--pgv0.2.0--r1-2E7D32)
![Base](https://img.shields.io/badge/base-immich--postgres%3A14--vectorchord0.4.3-555555?logo=docker&logoColor=white)
![Platforms](https://img.shields.io/badge/platforms-linux%2Famd64-607D8B)
![Repository code license](https://img.shields.io/badge/repository_code-MIT-1565C0)
![Build](https://img.shields.io/badge/build-linux%2Famd64_local-success)

PostgreSQL 14 com VectorChord 0.4.3 e pgvectors 0.2.0 para Immich v3.2.4. O wrapper atualiza `libgnutls30`, `libssl3` e `openssl` no Debian e substitui o `gosu` upstream por 1.19 compilado com Go 1.27.1. Preserva scripts, usuário, entrypoint, volume e health check oficiais.

## Referência da imagem

| Item | Valor |
| --- | --- |
| Imagem prevista | `lzocateli/immich-postgres:14-vc0.4.3-pgv0.2.0-r1` |
| Base | `ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:bcf63357191b76a916ae5eb93464d65c07511da41e3bf7a8416db519b40b1c23` |
| Plataformas declaradas | `linux/amd64` (upstream também fornece `linux/arm64`) |
| Usuário, entrypoint e comando | Config.User vazio (root inicial); `/usr/local/bin/immich-docker-entrypoint.sh`, `postgres -c config_file=/etc/postgresql/postgresql.conf` |
| Persistência | `/var/lib/postgresql/data` no dataset local |
| Código-fonte e documentação | [Repositório da imagem](https://github.com/lzocateli/containers/tree/main/immich-postgres) |

## Conteúdo e finalidade

Inclui o banco e as extensões empacotadas no upstream para o Immich, pacotes Debian com correções de segurança e `gosu` reconstruído em estágio temporário. Não inclui o compilador Go no runtime nem dados, backups, senhas ou serviço de aplicação. Não troque esta imagem pelo PostgreSQL genérico sem plano de migração das extensões.

## Início rápido

```bash
docker buildx build --pull --platform linux/amd64 --load -t lzocateli/immich-postgres:14-vc0.4.3-pgv0.2.0-r1 immich-postgres
```

Não execute contra o volume de produção para testar a imagem.

## Docker Compose

```yaml
services:
  database:
    image: lzocateli/immich-postgres:14-vc0.4.3-pgv0.2.0-r1
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_USER: ${DB_USERNAME}
      POSTGRES_DB: ${DB_DATABASE_NAME}
      POSTGRES_INITDB_ARGS: "--data-checksums"
    volumes:
      - ${DB_DATA_LOCATION}:/var/lib/postgresql/data
    shm_size: 128mb
    restart: always
```

## Configuração

| Variável | Obrigatória | Secreta | Função |
| --- | --- | --- | --- |
| `DB_DATA_LOCATION` | Sim, no Compose | Não | Dataset local do host, persistido no data directory. |
| `DB_PASSWORD` / `POSTGRES_PASSWORD` | Sim | Sim | Senha fornecida em runtime; não colocar em Dockerfile/README. |
| `DB_USERNAME` / `POSTGRES_USER` | Sim | Não | Usuário compartilhado com o servidor. |
| `DB_DATABASE_NAME` / `POSTGRES_DB` | Sim | Não | Banco compartilhado com o servidor. |
| `POSTGRES_INITDB_ARGS` | Somente na criação do volume | Não | `--data-checksums` no bootstrap. |

Não publique `5432/tcp` no host. O mount `/var/lib/postgresql/data` precisa ser gravável pelo UID/GID efetivo; prefira armazenamento local e não NFS/SMB. O volume é obrigatório para backup e restore consistentes; `POSTGRES_INITDB_ARGS` não reconfigura um banco já criado.

## Inicialização e ciclo de vida

O entrypoint upstream cria o banco no volume vazio e preserva os dados nos reinícios. Migrações da aplicação e extensões devem ser feitas conforme a release Immich correspondente. Health check é herdado da base; confirme o estado real após o build. Faça dump consistente e snapshot do dataset antes de upgrades.

## Segurança

Limite acesso ao volume e à rede Compose, injete a senha em runtime, mantenha o banco fora de portas públicas e confirme usuário e capacidades efetivas antes de impor restrições adicionais. Não reutilize o dataset com outra major do PostgreSQL sem procedimento de upgrade.

## Build local

```bash
docker buildx build --check --file immich-postgres/Dockerfile immich-postgres
docker buildx build --pull --platform linux/amd64 --load -t lzocateli/immich-postgres:14-vc0.4.3-pgv0.2.0-r1 immich-postgres
```

## Tags e compatibilidade

| Tag | Mutabilidade | Uso |
| --- | --- | --- |
| `14-vc0.4.3-pgv0.2.0-r1` | Imutável após publicação | Mesmo PostgreSQL 14 e extensões, com Debian atualizado e `gosu` corrigido. |

Não publique `latest` nem sobrescreva `14-vc0.4.3-pgv0.2.0` ou `14-vc0.4.3-pgv0.2.0-r1` depois de publicadas.

## Validação

BuildKit `--check`, build `linux/amd64`, troca para o usuário `postgres` via `gosu`, inspeção de entrypoint/porta/volume/health e `git check-ignore` passaram. Um cluster **descartável**, isolado da rede e dos volumes de produção, iniciou e expôs `vchord`, `vector` e `vectors`. `libgnutls30` está em `3.7.9-2+deb12u7`, `libssl3` e `openssl` em `3.0.22-1~deb12u1`; Trivy 0.72.0 não encontrou CRITICAL corrigível na imagem final local. Antes da publicação: testar persistência após recriação, gerar SBOM e proveniência. O estágio Go de build é descartado; apenas o binário `gosu` é copiado para a imagem final.

## Publicação

No workflow **Publicar imagem de container**, use `context_path=immich-postgres`, `image_name=immich-postgres`, `image_tag=14-vc0.4.3-pgv0.2.0-r1`, `dockerfile=Dockerfile`, `platforms=linux/amd64` após os gates da release. Não houve publicação nesta mudança.

## Operação

Agende dump e snapshots consistentes, monitore espaço e teste restores com a mesma imagem/extensões. Rollback após migração requer restaurar o backup pré-upgrade, não apenas trocar a imagem.

## Troubleshooting

| Sintoma | Verificação | Correção |
| --- | --- | --- |
| Banco não sobe | Logs, permissões e espaço do volume | Corrigir ACL e capacidade, sem apagar dados. |
| Extensão indisponível | Versões da imagem e da aplicação | Usar release compatível antes de migrar. |

## Limitações conhecidas

Não oferece upgrade automático entre majors nem substitui um plano de backup de dados.

## Licenças e fontes

| Componente | Licença | Fonte |
| --- | --- | --- |
| Conteúdo original deste repositório | MIT | [containers](https://github.com/lzocateli/containers) |
| Imagem PostgreSQL empacotada pelo Immich | Avisos upstream e dependências | [Pacote upstream](https://github.com/immich-app/immich/pkgs/container/postgres) |
| PostgreSQL | PostgreSQL License | [Licença oficial](https://www.postgresql.org/about/licence/) |

MIT cobre apenas o conteúdo original deste repositório. Confirme os avisos de VectorChord, pgvectors e demais componentes na imagem e consulte a [política de licenciamento](https://github.com/lzocateli/containers/blob/main/LICENSING.md).

## Histórico de alterações

- `14-vc0.4.3-pgv0.2.0-r1`: atualiza Debian e recompila `gosu` para sanar o gate CRITICAL.
- `14-vc0.4.3-pgv0.2.0`: wrapper inicial do banco da release Immich v2.6.3.
