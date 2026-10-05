<!--
SPDX-FileCopyrightText: 2026 Lincoln Zocateli
SPDX-License-Identifier: MIT
-->

# Immich Server

![Docker Hub](https://img.shields.io/badge/image-lzocateli%2Fimmich--server-2496ED?logo=docker&logoColor=white)
![Version](https://img.shields.io/badge/version-v3.2.4--v1-2E7D32)
![Base](https://img.shields.io/badge/base-immich--server%3Av3.2.4-555555?logo=docker&logoColor=white)
![Platforms](https://img.shields.io/badge/platforms-linux%2Famd64-607D8B)
![Repository code license](https://img.shields.io/badge/repository_code-MIT-1565C0)
![Build](https://img.shields.io/badge/build-linux%2Famd64_local-success)

Servidor Immich v3.2.4 para o Compose do TrueNAS. O wrapper substitui `node-tar` 7.5.16 da árvore pnpm por 7.5.19, já presente no npm da imagem upstream, para corrigir CVE-2026-59873. Preserva o usuário, o entrypoint e o health check upstream.

## Referência da imagem

| Item | Valor |
| --- | --- |
| Imagem prevista | `lzocateli/immich-server:v3.2.4-v1` |
| Base | `ghcr.io/immich-app/immich-server:v3.2.4@sha256:d317916b28090c33eb36b308464ea391f8b7df1d850fcfea227a39ec879718c2` |
| Plataformas declaradas | `linux/amd64` (upstream também fornece `linux/arm64`) |
| Usuário, entrypoint e comando | Config.User vazio (root inicial); `tini -- /bin/bash -c`, `start.sh`, herdados da base |
| Porta | `2283/tcp`, exposta no Compose |
| Código-fonte e documentação | [Repositório da imagem](https://github.com/lzocateli/containers/tree/main/immich-server) |

## Conteúdo e finalidade

Inclui o servidor oficial Immich, `node-tar` 7.5.19 no lugar do 7.5.16 da aplicação e labels do repositório. A substituição preserva as dependências declaradas pela biblioteca e não reinstala a árvore pnpm. Não inclui PostgreSQL, Valkey, machine learning, Nginx, biblioteca de fotos nem certificados.

## Início rápido

O serviço precisa da stack. Faça build local e suba o Compose existente no ambiente TrueNAS somente após fornecer a configuração de runtime:

```bash
docker buildx build --pull --platform linux/amd64 --load -t lzocateli/immich-server:v3.2.4-v1 immich-server
```

## Docker Compose

Trecho do contrato; as demais dependências devem estar na mesma rede do Compose e o arquivo `.env` deve existir apenas no host:

```yaml
services:
  immich-server:
    image: lzocateli/immich-server:v3.2.4-v1
    env_file: .env
    volumes:
      - ${UPLOAD_LOCATION}:/data
      - ${DB_BACKUP_LOCATION}:/usr/src/app/backups
    ports:
      - "2283:2283"
    depends_on: [redis, database]
    restart: always
```

## Configuração

| Variável | Obrigatória | Secreta | Origem e função |
| --- | --- | --- | --- |
| `UPLOAD_LOCATION` | Sim, no Compose | Não | Caminho absoluto do dataset de fotos no host; mount em `/data`. |
| `DB_BACKUP_LOCATION` | Conforme o Compose | Não | Destino de backups em `/usr/src/app/backups`. |
| `DB_PASSWORD` | Sim, em runtime | Sim | Credencial PostgreSQL compartilhada com o serviço `database`. |
| `DB_USERNAME`, `DB_DATABASE_NAME` | Sim, em runtime | Não | Usuário e banco compartilhados com o serviço `database`. |
| `TZ` | Opcional | Não | Fuso horário de runtime. |

O serviço usa Valkey em `redis`, PostgreSQL em `database` e machine learning em `immich-machine-learning` na rede interna. O Compose do TrueNAS publica `2283/tcp`; restrinja o acesso ao host/reverse proxy. `/data` contém a biblioteca e exige backup; `/usr/src/app/backups` contém dumps, mas **não** substitui o backup do volume PostgreSQL. Garanta permissões de escrita para o UID/GID efetivo da base; não embuta secrets no build.

## Inicialização e ciclo de vida

O bootstrap, as migrações, o health check e o encerramento seguem a imagem upstream. Aguarde a disponibilidade do banco e do cache antes de validar a aplicação; `depends_on` sozinho não garante prontidão. A atualização da v2 para a v3 altera APIs e elimina suporte a pgvecto.rs; confirme que o banco já usa VectorChord. Faça backup consistente e teste restauração do banco e da biblioteca antes do primeiro start v3; não altere a versão do server isoladamente. Downgrade após migrações não é suportado: um retorno à v2 exige restaurar os dados anteriores ao upgrade. Consulte o [guia de migração v3](https://immich.app/blog/v3-migration) antes de aplicar em produção.

## Segurança

Mantenha os serviços internos na rede privada, forneça `.env` somente em runtime, aplique ACLs aos datasets e confirme usuário/capacidades da imagem construída antes de endurecer filesystem ou privilégios. A licença MIT deste README não substitui a AGPL-3.0 do Immich.

## Build local

```bash
docker buildx build --check --file immich-server/Dockerfile immich-server
docker buildx build --pull --platform linux/amd64 --load -t lzocateli/immich-server:v3.2.4-v1 immich-server
```

## Tags e compatibilidade

| Tag | Mutabilidade | Uso |
| --- | --- | --- |
| `v3.2.4-v1` | Imutável após publicação | Immich v3.2.4 com `node-tar` 7.5.19; usar com serviços compatíveis da mesma release. |

Sem `latest`. Uma nova base, digest ou correção exige outra tag; não sobrescreva `v3.2.4` nem `v3.2.4-v1` depois de publicadas.

## Validação

BuildKit `--check`, build `linux/amd64` e carregamento de `node-tar` 7.5.19 passaram para `v3.2.4-v1`. Trivy 0.72.0 não encontrou CRITICAL corrigível no scan local pelo Docker daemon. Antes da publicação: `git check-ignore`, smoke test com banco descartável, persistência, SBOM e proveniência. Nada foi publicado ou implantado nesta mudança.

## Publicação

No workflow **Publicar imagem de container**, use `context_path=immich-server`, `image_name=immich-server`, `image_tag=v3.2.4-v1`, `dockerfile=Dockerfile`, `platforms=linux/amd64` após os gates da release.

## Operação

Faça snapshots/backup verificado do dataset de mídia e dump consistente do PostgreSQL; teste restore conjunto antes de atualizar. Acompanhe logs e estado do health check no Compose. Para rollback, restaure imagem **e dados compatíveis**; migrações de banco podem ser irreversíveis.

## Troubleshooting

| Sintoma | Verificação | Correção |
| --- | --- | --- |
| Servidor não inicia | Logs, `DB_PASSWORD` e nomes `database`/`redis` | Corrigir configuração de runtime sem expor credenciais. |
| Erros ao enviar mídia | Permissões e espaço livre de `UPLOAD_LOCATION` | Corrigir ACLs e capacidade do dataset. |
| Health check falha | Saúde do banco e cache, logs do servidor | Investigar dependências antes de reiniciar. |

## Limitações conhecidas

Não inclui aceleração de transcoding nem configurações TLS. O Nginx existente no repositório usa base 1.28.0; a tag `lzocateli/nginx:1.25.0-bullseye` do Compose deve ser verificada separadamente antes de deploy.

## Licenças e fontes

| Componente | Licença | Fonte |
| --- | --- | --- |
| Conteúdo original deste repositório | MIT | [containers](https://github.com/lzocateli/containers) |
| Immich v3.2.4 | AGPL-3.0 | [Immich](https://github.com/immich-app/immich/tree/v3.2.4) |

MIT cobre apenas o conteúdo original deste repositório. Dependências e a imagem base preservam suas licenças e avisos; consulte a [política de licenciamento](https://github.com/lzocateli/containers/blob/main/LICENSING.md) e os avisos dentro da imagem.

## Histórico de alterações

- `v3.2.4-v1`: corrige CVE-2026-59873 substituindo `node-tar` 7.5.16 por 7.5.19.
- `v3.2.4`: atualiza a base do servidor para a release v3.2.4.
- `v2.6.3`: wrapper inicial da release upstream para TrueNAS.
