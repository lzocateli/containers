# PostgreSQL com pgvector

![Docker Hub](https://img.shields.io/badge/image-lzocateli%2Fpostgresql-2496ED?logo=docker&logoColor=white)
![Version](https://img.shields.io/badge/version-18.4--pgvector0.8.5--bookworm-2E7D32)
![Base](https://img.shields.io/badge/base-pgvector%2Fpgvector%3A0.8.5--pg18--bookworm-555555?logo=docker&logoColor=white)
![Platforms](https://img.shields.io/badge/platforms-linux%2Famd64-607D8B)
![Repository code license](https://img.shields.io/badge/repository_code-MIT-1565C0)
![Build](https://img.shields.io/badge/build-workflow__dispatch-success)

Imagem PostgreSQL 18 para aplicações que precisam de busca vetorial. Ela acrescenta metadados OCI, locale UTF-8 e um comando de health check à imagem `pgvector/pgvector`, preservando o entrypoint oficial do PostgreSQL.

O `pgvector` está instalado, mas a extensão `vector` precisa ser habilitada em cada database. Os scripts de bootstrap incluídos também habilitam `pg_trgm`, `pgcrypto` e `citext` no database inicial.

## Referência da imagem

| Item | Valor |
| --- | --- |
| Imagem | `lzocateli/postgresql:18.4-pgvector0.8.5-bookworm` |
| Imagem base | `pgvector/pgvector:0.8.5-pg18-bookworm` |
| PostgreSQL | `18.4` |
| pgvector | `0.8.5` |
| Plataforma publicada | `linux/amd64` |
| Processo principal | `postgres` como usuário `postgres` (`999:999`) |
| Entry point | `/usr/local/bin/docker-entrypoint.sh` |
| Comando padrão | `postgres` |
| Porta | `5432/tcp` |
| Volume de dados | `/var/lib/postgresql` |
| Diretório de trabalho | `/var/lib/postgresql` |
| Health check | Comando `postgresql-healthcheck`, configurado pelos exemplos de runtime |
| Código-fonte | <https://github.com/lzocateli/containers/tree/main/postgresql> |
| Docker Hub | <https://hub.docker.com/r/lzocateli/postgresql> |

O entrypoint pode iniciar como `root` para preparar diretórios e então reduz privilégios para o usuário `postgres`. O Dockerfile não declara `HEALTHCHECK`; o Compose e o script Podman configuram explicitamente o comando fornecido pela imagem.

## Conteúdo e finalidade

### Arquivos de suporte

| Arquivo | Responsabilidade |
| --- | --- |
| `Dockerfile` | Define PostgreSQL 18 com pgvector e preserva o entrypoint oficial da imagem base. |
| `init/00-extensions.sql` | Habilita `vector`, `pg_trgm`, `pgcrypto` e `citext` no database criado no primeiro bootstrap. |
| `init/10-schemas.sql` | Cria o schema configurado para a aplicação. |
| `init/20-roles.sh` | Cria, opcionalmente, uma role de runtime sem expor sua senha em arquivo SQL. |
| `init/30-permissions.sql` | Concede permissões e privilégios padrão à role de runtime. |
| `init/40-application.sql` | Configura o `search_path` da role de runtime. |
| `postgresql-healthcheck.sh` | Distingue o PostgreSQL definitivo do servidor temporário usado no bootstrap. |
| `init/README.md` | Explica a ordem, personalização e limites do bootstrap inicial. |
| `migrations/` | Contém exemplos de mudanças explícitas para roles, schemas e bancos já existentes. |
| `docker-compose.yml` | Execução com Docker Compose usando variáveis externas e somente bind mounts. |
| `.env.example` | Modelo de variáveis locais; copie para `.env` e substitua todos os valores. |
| `02-postgres.sh` | Script operacional para executar a imagem com Podman rootless e bind mounts. |

### Não incluído

- credenciais, dados, backups ou configuração específica de aplicação;
- extensões habilitadas automaticamente em todos os databases;
- automação de alta disponibilidade, replicação ou recuperação ponto no tempo;
- migração automática de clusters existentes ou entre versões principais.

## Início rápido

Use sempre uma tag de versão explícita, configure `POSTGRES_PASSWORD` com uma senha segura e mantenha os dados em um bind mount de `/var/lib/postgresql`. A imagem não contém dados nem scripts específicos de uma aplicação: o bootstrap adicional deve ser montado em `/docker-entrypoint-initdb.d` antes da primeira inicialização.

O Docker Compose e o exemplo de configuração estão nas seções [Persistência obrigatória](#persistência-obrigatória), [Variáveis de ambiente](#variáveis-de-ambiente) e [Execução com Docker Compose](#execução-com-docker-compose). Para alterações em um cluster existente, use as [migrações explícitas](migrations/README.md).

Baixe a imagem publicada:

```bash
docker pull lzocateli/postgresql:18.4-pgvector0.8.5-bookworm
```

Ou com Podman:

```bash
podman pull lzocateli/postgresql:18.4-pgvector0.8.5-bookworm
```

Exemplo mínimo com health check e persistência:

```bash
mkdir -p ./data ./backups

docker run --name postgresql \
  --detach \
  --publish 127.0.0.1:5432:5432 \
  --env POSTGRES_PASSWORD='substitua-por-uma-senha-segura' \
  --mount type=bind,src="$PWD/data",dst=/var/lib/postgresql \
  --mount type=bind,src="$PWD/backups",dst=/backups \
  --health-cmd postgresql-healthcheck \
  --health-start-period 30s \
  --health-interval 10s \
  --health-timeout 5s \
  --health-retries 6 \
  lzocateli/postgresql:18.4-pgvector0.8.5-bookworm
```

Confirme a inicialização com `docker inspect --format '{{.State.Health.Status}}' postgresql`.

## Persistência obrigatória

Todo dado persistente deve usar bind mount para um diretório do host. Não use volumes nomeados Docker ou Podman.

| Dado | Caminho no host | Caminho no contêiner | Modo |
| --- | --- | --- | --- |
| Dados do PostgreSQL | `POSTGRES_DATA_DIR` ou `POSTGRES_DATA` | `/var/lib/postgresql` | Leitura e escrita |
| Scripts de inicialização | `./init` do repositório | `/docker-entrypoint-initdb.d` | Somente leitura |
| Backups lógicos | `POSTGRES_BACKUP_DIR` | `/backups` | Leitura e escrita |

O PostgreSQL 18 cria o cluster em um subdiretório versionado dentro de `/var/lib/postgresql`. Por isso, o bind mount deve apontar para `/var/lib/postgresql`, e não para o caminho legado `/var/lib/postgresql/data`. O diretório no host deve sobreviver à remoção e recriação do contêiner. Nunca remova seu conteúdo sem backup validado.

## Variáveis de ambiente

| Variável | Obrigatória | Secreta | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| `POSTGRES_PASSWORD` | Sim | Sim | Nenhum | Senha do superusuário criado no primeiro bootstrap. |
| `POSTGRES_PASSWORD_FILE` | Alternativa | Sim | Nenhum | Arquivo montado contendo a senha; use no lugar de `POSTGRES_PASSWORD`. |
| `POSTGRES_USER` | Não | Não | `postgres` | Superusuário e proprietário inicial. |
| `POSTGRES_DB` | Não | Não | Valor de `POSTGRES_USER` | Database criado no primeiro bootstrap. |
| `POSTGRES_RUNTIME_USER` | Não | Não | Nenhum | Role sem privilégios administrativos criada pelos scripts de `init/`. |
| `POSTGRES_RUNTIME_PASSWORD` | Condicional | Sim | Nenhum | Senha da role de runtime; informe junto das outras variáveis de runtime. |
| `POSTGRES_APP_SCHEMA` | Não | Não | Nenhum | Schema concedido à role de runtime. |
| `POSTGRES_INITDB_ARGS` | Não | Não | `--encoding=UTF8 --locale=C.UTF-8` | Argumentos de `initdb` definidos pela imagem. |
| `PGDATA` | Não | Não | `/var/lib/postgresql/18/docker` | Diretório do cluster no volume do PostgreSQL 18. |
| `TZ` | Não | Não | Padrão da base | Fuso horário do processo. |
| `POSTGRES_DATA_DIR` | Compose | Não | Nenhum | Caminho absoluto dos dados no host. |
| `POSTGRES_DATA` | Script Podman | Não | Nenhum | Caminho absoluto dos dados no host. |
| `POSTGRES_BACKUP_DIR` | Compose/Podman | Não | Nenhum | Caminho absoluto dos backups no host. |
| `POSTGRES_PORT_BIND` | Não | Não | `127.0.0.1:5432` | Endereço e porta publicados pelo Compose. |
| `POSTGRES_SHM_SIZE` | Não | Não | `256m` | Tamanho de `/dev/shm` usado pelo script Podman. |

As variáveis de bootstrap só produzem efeito quando `PGDATA` está vazio. Para a role de runtime, informe `POSTGRES_RUNTIME_USER`, `POSTGRES_RUNTIME_PASSWORD` e `POSTGRES_APP_SCHEMA` em conjunto.

Não armazene senhas no Compose, em scripts versionados ou em imagens. Em Docker, prefira `POSTGRES_PASSWORD_FILE` apontando para um secret em `/run/secrets`. Os scripts opcionais de role de runtime não implementam uma variante `_FILE`; forneça `POSTGRES_RUNTIME_PASSWORD` pelo mecanismo seguro do orquestrador.

## Inicialização

Na primeira execução com um diretório `PGDATA` vazio, o entrypoint:

1. Inicializa o cluster com encoding UTF-8.
2. Cria `POSTGRES_USER` e `POSTGRES_DB` conforme as variáveis configuradas.
3. Define autenticação por senha SCRAM para conexões TCP.
4. Executa, de forma síncrona e em ordem alfabética, os arquivos `.sh` e `.sql` montados em `/docker-entrypoint-initdb.d`.

Os scripts são executados apenas quando o diretório de dados estiver vazio. Eles devem permanecer idempotentes para suportar recuperação operacional e testes de bootstrap.

### O que mudou em relação aos entrypoints legados

Os entrypoints customizados legados foram removidos. A imagem herda o entrypoint oficial do PostgreSQL, que executa o bootstrap de forma síncrona e é mantido pela imagem base.

| Responsabilidade anterior | Configuração atual |
| --- | --- |
| `initdb` e permissões de dados | Entry point oficial da imagem base. |
| Database e usuário iniciais | `POSTGRES_DB`, `POSTGRES_USER` e `POSTGRES_PASSWORD`. |
| Encoding e locale | `POSTGRES_INITDB_ARGS` definido no Dockerfile. |
| Execução de scripts | Arquivos ordenados em `/docker-entrypoint-initdb.d`. |
| `pgvector` | Fornecido pela imagem base e habilitado por `init/00-extensions.sql`. |
| Inicialização em background | Removida; o bootstrap termina antes de o servidor definitivo ficar disponível. |

As variáveis legadas `PG_DATABASE`, `PG_USER`, `PG_PASSWORD` e `PG_DATABASE_ENCODING` não devem ser usadas para novas implantações.

### Estrutura recomendada no host

```text
/srv/minha-aplicacao/postgresql/
├── data/                         # POSTGRES_DATA_DIR: cluster persistente
├── backups/                      # POSTGRES_BACKUP_DIR: dumps e restores
├── init/                         # bootstrap versionado, somente primeiro bootstrap
│   ├── 00-extensions.sql
│   ├── 10-schemas.sql
│   ├── 20-roles.sh
│   ├── 30-permissions.sql
│   └── 40-application.sql
└── migrations/                   # aplicado explicitamente em banco existente
    ├── 2026-07-28-create-audit-schema.sql
    └── README.md
```

O diretório `init/` do repositório é montado automaticamente no bootstrap. Não monte a pasta `migrations/` em `/docker-entrypoint-initdb.d`.

### Personalizações no primeiro bootstrap

Para criar schema e usuário de runtime, configure todas as variáveis abaixo no arquivo `.env` ou secret do contêiner:

```dotenv
POSTGRES_RUNTIME_USER=app_runtime
POSTGRES_RUNTIME_PASSWORD=uma-senha-exclusiva-e-segura
POSTGRES_APP_SCHEMA=app
```

O bootstrap separa a criação de schema, role, permissões e configuração da aplicação. `20-roles.sh` cria a role sem privilégios de superusuário, criação de databases ou criação de roles; `30-permissions.sql` concede a ela os privilégios necessários no schema informado.

Scripts adicionais devem ter nomes ordenáveis, como `20-audit-schema.sql` e `30-report-reader.sh`, e ser idempotentes. Consulte [init/README.md](init/README.md) para a ordem e os cuidados de criação.

### Configurações para banco já existente

O entrypoint ignora deliberadamente `/docker-entrypoint-initdb.d` quando já existe um cluster no bind mount. Para alterar schemas, roles, permissões ou extensões depois do primeiro bootstrap, aplique uma migração explícita.

Exemplo com Docker:

```bash
docker exec -i postgresql \
  psql --set=ON_ERROR_STOP=1 \
  --username "$POSTGRES_USER" \
  --dbname "$POSTGRES_DB" \
  --set=runtime_user="app_runtime" \
  < migrations/2026-07-28-create-audit-schema.sql
```

Para Podman, substitua `docker exec` por `podman exec` e o nome do contêiner conforme sua implantação. Consulte [migrations/README.md](migrations/README.md) para o procedimento, regras de versionamento e integração com EF Core.

## Execução com Podman

O script [`02-postgres.sh`](./02-postgres.sh) é o fluxo recomendado para uso local ou em servidor com Podman rootless.

Pré-requisitos:

1. Podman instalado e configurado em modo rootless.
2. Rede `lzo` criada previamente, normalmente pelo script `01-network.sh` do ambiente de implantação.
3. Variável `DEPLOY_DIR` apontando para o diretório que contém `.env.production`.
4. Arquivo `.env.production` com `POSTGRES_PASSWORD`, `POSTGRES_DATA` e `POSTGRES_BACKUP_DIR`.

Exemplo mínimo de `/userapps/blog/.env.production`:

```dotenv
POSTGRES_PASSWORD=troque-por-uma-senha-segura
POSTGRES_DATA=/userapps/var/postgres_data
POSTGRES_BACKUP_DIR=/userapps/var/postgres_backups
```

Execute:

```bash
export DEPLOY_DIR=/userapps/blog
chmod +x ./02-postgres.sh
./02-postgres.sh
```

Os padrões `POSTGRES_USER=blogadmin`, `POSTGRES_DB=blogdb`, `TZ=America/Sao_Paulo` e `POSTGRES_SHM_SIZE=256m` pertencem ao script e não são padrões da imagem.

O script:

1. Carrega variáveis do arquivo de ambiente.
2. Cria o bind mount de dados e ajusta sua propriedade para o UID/GID do PostgreSQL no namespace rootless.
3. Monta o diretório `init/` versionado como bootstrap somente leitura.
4. Remove um contêiner parado com o mesmo nome.
5. Inicia `lzocateli/postgresql:18.4-pgvector0.8.5-bookworm` com bind mounts para dados, scripts e backups.
6. Aguarda o health check da imagem, que confirma disponibilidade do database e do servidor PostgreSQL definitivo.
7. Habilita `vector`, `pg_trgm`, `pgcrypto` e `citext` no database configurado, mesmo quando o diretório externo não contém o script padrão de extensões.

Comandos úteis:

```bash
podman ps --filter name=postgres
podman logs -f postgres
podman healthcheck run postgres
podman stop postgres
podman start postgres
```

## Execução com Docker Compose

O `docker-compose.yml` é um exemplo de referência. Antes de usá-lo:

1. Copie `.env.example` para `.env` e substitua todos os valores.
2. Informe caminhos absolutos existentes para os dois bind mounts persistentes.
3. Publique a porta apenas quando necessária; o padrão é `127.0.0.1:5432:5432`.
4. O Compose monta somente os cinco scripts de bootstrap versionados como somente leitura.

Exemplo de montagem persistente:

```yaml
services:
  db:
    image: lzocateli/postgresql:18.4-pgvector0.8.5-bookworm
    ports:
      - "127.0.0.1:5432:5432"
    volumes:
      - ${POSTGRES_DATA_DIR}:/var/lib/postgresql
      - ./init/00-extensions.sql:/docker-entrypoint-initdb.d/00-extensions.sql:ro
      - ./init/10-schemas.sql:/docker-entrypoint-initdb.d/10-schemas.sql:ro
      - ./init/20-roles.sh:/docker-entrypoint-initdb.d/20-roles.sh:ro
      - ./init/30-permissions.sql:/docker-entrypoint-initdb.d/30-permissions.sql:ro
      - ./init/40-application.sql:/docker-entrypoint-initdb.d/40-application.sql:ro
      - ${POSTGRES_BACKUP_DIR}:/backups
```

Inicie o serviço:

```bash
docker compose up -d
docker compose ps
docker compose logs -f db
```

## Build da imagem

Execute os comandos a partir deste diretório.

Build com Docker:

```bash
docker build --pull --tag lzocateli/postgresql:18.4-pgvector0.8.5-bookworm .
```

Build com Podman:

```bash
podman build --pull --tag lzocateli/postgresql:18.4-pgvector0.8.5-bookworm .
```

## Tags e compatibilidade

| Tag | Mutabilidade | Compatibilidade | Uso recomendado |
| --- | --- | --- | --- |
| `18.4-pgvector0.8.5-bookworm` | Imutável | PostgreSQL 18.4, pgvector 0.8.5 e Debian Bookworm | Produção |
| `18.4-pgvector0.8.5-bookworm-rN` | Imutável | Revisão da mesma combinação upstream | Correções da imagem |

Não há política de publicação para `latest`. Novas versões do PostgreSQL, pgvector, Debian ou do contrato da imagem recebem uma nova tag. Para implantação reprodutível, registre também o digest publicado.

## Publicação

Use **Actions > Publicar imagem de container > Run workflow** com:

| Entrada | Valor |
| --- | --- |
| `context_path` | `postgresql` |
| `image_name` | `postgresql` |
| `image_tag` | `18.4-pgvector0.8.5-bookworm` ou uma revisão imutável |
| `dockerfile` | `Dockerfile` |
| `platforms` | `linux/amd64` |
| `update_dockerhub_readme` | `true` |

O workflow usa `DOCKERHUB_USERNAME` e `DOCKERHUB_TOKEN`, publica SBOM e proveniência e sincroniza este README com o Docker Hub. Nunca exponha os valores dos secrets em logs ou documentação.

## Validação

Analise o Dockerfile com BuildKit:

```bash
docker buildx build --check --file Dockerfile .
```

Confirme a versão do PostgreSQL:

```bash
docker run --rm --entrypoint psql lzocateli/postgresql:18.4-pgvector0.8.5-bookworm --version
```

Inicie uma instância temporária apenas para validar saúde:

```bash
docker run --rm \
  -e POSTGRES_PASSWORD=senha-temporaria-segura \
  lzocateli/postgresql:18.4-pgvector0.8.5-bookworm
```

Para uma validação completa, use um diretório temporário do host como bind mount, crie database e usuário, execute um script de inicialização e confirme que os dados permanecem após remover e recriar o contêiner.

Antes da publicação, confirme também os ignore files, labels OCI, usuário, entrypoint, porta, volume, extensões, encerramento, plataforma, vulnerabilidades, SBOM e proveniência.

## Segurança

- Não exponha a porta `5432` para redes não confiáveis.
- Use senhas exclusivas e de alta entropia; troque qualquer credencial anteriormente usada em arquivos de exemplo.
- Use uma role sem privilégios administrativos para clientes da aplicação.
- Não use `POSTGRES_HOST_AUTH_METHOD=trust`.
- Limite a leitura dos secrets ao usuário do runtime.
- Mantenha a imagem base atualizada e reconstrua a imagem quando houver atualizações de segurança do PostgreSQL ou Debian.
- Fixe tags de release e registre o digest publicado para implantações reprodutíveis.
- Mantenha o banco acessível somente pela rede interna de contêineres quando ele for consumido por uma aplicação.
- Em PostgreSQL 18, valide o bind mount no caminho `/var/lib/postgresql`; o cluster fica em um subdiretório versionado, como `/var/lib/postgresql/18/docker`.
- O health check também verifica `listen_addresses`: isso evita marcar o contêiner como saudável enquanto o entrypoint oficial ainda usa o servidor temporário de bootstrap.
- Não force filesystem somente leitura: o entrypoint e o PostgreSQL precisam gravar no volume, em `/run/postgresql` e em diretórios temporários.
- Defina limites de memória, CPU e `/dev/shm` de acordo com a carga, especialmente ao criar índices HNSW.

## Upgrade e rollback

Antes de qualquer upgrade, gere um dump consistente e valide a restauração em outro diretório.

- **Revisão da imagem ou PostgreSQL minor:** pare o contêiner, preserve o bind mount, use a nova tag imutável e recrie o contêiner.
- **pgvector:** depois de atualizar a imagem, execute `ALTER EXTENSION vector UPDATE;` em cada database que usa a extensão e confira `pg_extension.extversion`.
- **PostgreSQL major:** use `pg_upgrade` ou dump/restore conforme a documentação oficial. Nunca inicialize diretamente uma nova versão principal sobre o cluster antigo.
- **Rollback:** reverta a tag somente quando o formato dos dados e extensões continuar compatível. Caso tenha ocorrido migração incompatível, restaure o backup em um diretório vazio.

## Backup e restauração

Crie backups lógicos no bind mount `/backups`:

```bash
docker exec postgresql pg_dump \
  --username postgres \
  --dbname postgres \
  --format custom \
  --file /backups/postgres.dump
```

Teste a restauração em uma instância separada:

```bash
docker exec postgresql pg_restore \
  --username postgres \
  --dbname postgres \
  --clean \
  --if-exists \
  /backups/postgres.dump
```

O segundo comando altera o database de destino; use somente em uma instância de restauração isolada.

## Troubleshooting

| Sintoma | Causa provável | Verificação | Correção |
| --- | --- | --- | --- |
| `POSTGRES_PASSWORD` ausente | Secret não fornecido | `docker logs postgresql` | Defina `POSTGRES_PASSWORD` ou `POSTGRES_PASSWORD_FILE`. |
| Contêiner permanece `starting` | Bootstrap em andamento ou script falhou | `docker logs postgresql` | Corrija o primeiro erro; se o cluster for descartável, limpe-o antes de repetir o bootstrap. |
| `Permission denied` em `PGDATA` | UID/GID do bind mount incorreto | `ls -ln ./data` | Ajuste para `999:999`; em Podman rootless, use `podman unshare chown`. |
| Script novo não foi executado | Cluster já inicializado | Consulte o log e o conteúdo de `PGDATA` | Aplique uma migração explícita; não apague dados para forçar bootstrap. |
| `extension "vector" is not available` | Imagem ou database incorreto | Consulte `pg_available_extensions` | Confirme a tag e conecte ao database esperado. |
| Porta indisponível | Outro processo usa `5432` | `docker compose ps` | Altere `POSTGRES_PORT_BIND` ou remova a publicação. |
| Script Podman falha em `DEPLOY_DIR` | Variável não exportada | `printf '%s\n' "$DEPLOY_DIR"` | Exporte o diretório que contém `.env.production`. |

## Limitações conhecidas

- A publicação atual declara somente `linux/amd64`.
- O Dockerfile fornece o comando de saúde, mas depende do runtime para configurá-lo.
- Os scripts de bootstrap atuam somente no database inicial e somente com `PGDATA` vazio.
- `02-postgres.sh` contém padrões específicos do ambiente de blog.
- Backup, replicação, TLS e alta disponibilidade exigem configuração externa.

## Licenças e fontes

| Componente | Versão | Licença | Fonte |
| --- | --- | --- | --- |
| Configuração deste repositório | Atual | MIT | <https://github.com/lzocateli/containers> |
| PostgreSQL | 18.4 | PostgreSQL License | <https://www.postgresql.org/about/licence/> |
| pgvector | 0.8.5 | PostgreSQL License | <https://github.com/pgvector/pgvector> |
| Imagem oficial PostgreSQL | 18.4 Bookworm | Licenças dos componentes distribuídos | <https://github.com/docker-library/postgres> |
| Debian | Bookworm | Licenças por pacote | <https://www.debian.org/legal/licenses/> |

O badge MIT descreve somente o conteúdo original deste repositório. PostgreSQL, pgvector, Debian e os demais componentes permanecem sujeitos às licenças e atribuições de suas fontes; a licença MIT não os relicencia. Consulte a [política de licenciamento](https://github.com/lzocateli/containers/blob/main/LICENSING.md) e os avisos presentes na própria imagem.

## Histórico de alterações

| Tag | Alteração observável |
| --- | --- |
| `18.4-pgvector0.8.5-bookworm` | PostgreSQL 18.4, pgvector 0.8.5, layout persistente do PostgreSQL 18 e health check que distingue o servidor definitivo do bootstrap. |
Novas alterações observáveis devem ser registradas junto da respectiva tag imutável.
