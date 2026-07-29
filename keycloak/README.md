<!--
SPDX-FileCopyrightText: 2024 Lincoln Zocateli
SPDX-License-Identifier: MIT
-->

# Keycloak 26.7.0

![Docker Hub](https://img.shields.io/badge/image-lzocateli%2Fkeycloak-2496ED?logo=docker&logoColor=white)
![Version](https://img.shields.io/badge/version-26.7.0-2E7D32)
![Base](https://img.shields.io/badge/base-quay.io%2Fkeycloak%2Fkeycloak-555555?logo=keycloak&logoColor=white)
![Platform](https://img.shields.io/badge/platform-linux%2Famd64-607D8B)
![Repository code license](https://img.shields.io/badge/repository_code-MIT-1565C0)

Keycloak 26.7.0 configuravel em runtime para PostgreSQL ou Microsoft SQL Server. Health e metricas ficam habilitados por padrao na porta de gerenciamento `9000`.

## Referencia da imagem

| Item | Valor |
| --- | --- |
| Imagem | `lzocateli/keycloak:26.7.0` |
| Imagem base | `quay.io/keycloak/keycloak:26.7.0`, fixada pelo digest `sha256:26939e...c2a7a` para `linux/amd64` |
| Plataforma | `linux/amd64` |
| Usuario padrao | `keycloak`, UID `1000` |
| Entry point | `/opt/keycloak/bin/kc.sh` |
| Portas | `8080/tcp`, `8443/tcp` e `9000/tcp` |
| Codigo-fonte | `https://github.com/lzocateli/containers/tree/main/keycloak` |

Esta imagem preserva a distribuicao padrao, sem executar `kc.sh build` para um vendor especifico. Isso permite selecionar `postgres` ou `mssql` no runtime, ao custo de uma etapa de configuracao no primeiro startup. Para cargas maiores, produza uma variante otimizada e exclusiva para o banco escolhido.

## Compatibilidade dos bancos do repositorio

Verificacao realizada com a matriz oficial do Keycloak 26.7.0:

| Imagem do repositorio | Matriz oficial do Keycloak | Status |
| --- | --- | --- |
| `lzocateli/postgresql:18.4-pgvector0.8.5-bookworm` | PostgreSQL `18.x`, `17.x`, `16.x`, `15.x` e `14.x` | **Suportada oficialmente** |
| `lzocateli/mssql-server:2025-CU7-ubuntu-24.04` | SQL Server `2022` e `2019` | **Nao suportada oficialmente** |

SQL Server 2025 pode funcionar com o driver `mssql` incluido, mas fica fora da matriz suportada pelo Keycloak. Para producao com suporte do fornecedor, use PostgreSQL 18.4 deste repositorio ou uma versao SQL Server suportada. Azure SQL Database e Azure SQL Managed Instance `latest` aparecem separadamente como suportados e nao tornam SQL Server 2025 local uma configuracao suportada.

Fonte: `https://www.keycloak.org/server/db`.

Smoke tests executados nesta atualizacao:

| Banco testado | Resultado observado |
| --- | --- |
| PostgreSQL `18.4` | Keycloak iniciou com `jdbc-postgresql`, concluiu o bootstrap, criou `100` tabelas e respondeu `200 OK` em `/health/ready`. |
| SQL Server `2025 CU7` (`17.0.4065.4`) | Keycloak iniciou com `jdbc-mssql`, concluiu o bootstrap, criou `100` tabelas e respondeu `200 OK` em `/health/ready`, usando `READ_COMMITTED_SNAPSHOT` e a collation `Latin1_General_100_CI_AS_SC_UTF8`. |

O smoke test com SQL Server 2025 demonstra compatibilidade funcional neste cenario, mas nao substitui suporte oficial nem valida upgrades, extensoes ou cargas de producao.

## Configuracao comum

Crie `.env` a partir de `.env.example`, substitua todos os valores de senha e ajuste `KC_HOSTNAME` para a URL publica.

| Variavel | Obrigatoria | Secreta | Descricao |
| --- | --- | --- | --- |
| `KC_BOOTSTRAP_ADMIN_USERNAME` | Primeira inicializacao | Nao | Usuario administrativo inicial. |
| `KC_BOOTSTRAP_ADMIN_PASSWORD` | Primeira inicializacao | Sim | Senha administrativa inicial. |
| `KC_DB` | Sim | Nao | `postgres` ou `mssql`. |
| `KC_DB_URL` | Sim | Nao | URL JDBC completa. |
| `KC_DB_USERNAME` | Sim | Nao | Usuario dedicado do banco. |
| `KC_DB_PASSWORD` | Sim | Sim | Senha do usuario do banco. |
| `KC_HOSTNAME` | Producao | Nao | URL publica usada em redirects e emissores OIDC. |
| `KC_PROXY_HEADERS` | Com proxy | Nao | Use `xforwarded` ou `forwarded` conforme o proxy. |

Se uma senha contiver `$` ou `${...}`, use `KCRAW_DB_PASSWORD` no lugar de `KC_DB_PASSWORD` para preservar o valor literal.

## Docker Compose com PostgreSQL 18.4

Esta e a combinacao recomendada entre as imagens atuais do repositorio:

```yaml
services:
  postgres:
    image: lzocateli/postgresql:18.4-pgvector0.8.5-bookworm
    environment:
      POSTGRES_USER: ${KC_DB_USERNAME}
      POSTGRES_PASSWORD: ${KC_DB_PASSWORD}
      POSTGRES_DB: keycloak
    volumes:
      - ./data/postgres:/var/lib/postgresql
    healthcheck:
      test: ["CMD", "postgresql-healthcheck"]
      start_period: 30s
      interval: 10s
      timeout: 5s
      retries: 6

  keycloak:
    image: lzocateli/keycloak:26.7.0
    command: ["start"]
    restart: unless-stopped
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      KC_BOOTSTRAP_ADMIN_USERNAME: ${KC_BOOTSTRAP_ADMIN_USERNAME}
      KC_BOOTSTRAP_ADMIN_PASSWORD: ${KC_BOOTSTRAP_ADMIN_PASSWORD}
      KC_DB: postgres
      KC_DB_URL: jdbc:postgresql://postgres:5432/keycloak
      KC_DB_USERNAME: ${KC_DB_USERNAME}
      KC_DB_PASSWORD: ${KC_DB_PASSWORD}
      KC_HOSTNAME: ${KC_HOSTNAME}
      KC_HTTP_ENABLED: "true"
      KC_PROXY_HEADERS: xforwarded
    ports:
      - "127.0.0.1:8080:8080"
    mem_limit: 2g
```

O caminho `./data/postgres` e relativo ao diretorio do arquivo Compose. Crie essa pasta antes da primeira execucao e inclua-a na rotina de backup. No PostgreSQL 18, mantenha o destino `/var/lib/postgresql`; o cluster e criado no subdiretorio versionado `/var/lib/postgresql/18/docker`.

## Docker Compose com SQL Server 2025 CU7

O exemplo abaixo e experimental porque SQL Server 2025 nao consta na matriz suportada pelo Keycloak 26.7.0:

```yaml
services:
  mssql:
    image: lzocateli/mssql-server:2025-CU7-ubuntu-24.04
    platform: linux/amd64
    environment:
      ACCEPT_EULA: "Y"
      MSSQL_PID: ${MSSQL_PID:-Developer}
      MSSQL_SA_PASSWORD: ${MSSQL_SA_PASSWORD}
      MSSQL_DATABASE: keycloak
      MSSQL_DATABASE_COLLATE: Latin1_General_100_CI_AS_SC_UTF8
      MSSQL_USER: ${KC_DB_USERNAME}
      MSSQL_PASSWORD: ${KC_DB_PASSWORD}
    volumes:
      - ./data/mssql:/var/opt/mssql

  keycloak:
    image: lzocateli/keycloak:26.7.0
    command: ["start"]
    restart: unless-stopped
    depends_on:
      mssql:
        condition: service_healthy
    environment:
      KC_BOOTSTRAP_ADMIN_USERNAME: ${KC_BOOTSTRAP_ADMIN_USERNAME}
      KC_BOOTSTRAP_ADMIN_PASSWORD: ${KC_BOOTSTRAP_ADMIN_PASSWORD}
      KC_DB: mssql
      KC_DB_URL: "jdbc:sqlserver://mssql:1433;databaseName=keycloak;encrypt=true;trustServerCertificate=true"
      KC_DB_SCHEMA: dbo
      KC_DB_USERNAME: ${KC_DB_USERNAME}
      KC_DB_PASSWORD: ${KC_DB_PASSWORD}
      KC_HOSTNAME: ${KC_HOSTNAME}
      KC_HTTP_ENABLED: "true"
      KC_PROXY_HEADERS: xforwarded
    ports:
      - "127.0.0.1:8080:8080"
    mem_limit: 2g
```

`trustServerCertificate=true` serve apenas ao certificado autoassinado do exemplo local. Em producao, valide a cadeia e a identidade do servidor. Antes de iniciar o Keycloak, habilite o isolamento recomendado:

```sql
ALTER DATABASE [keycloak] SET READ_COMMITTED_SNAPSHOT ON;
```

## Desenvolvimento com Podman e tema customizado

Nao monte o `/tmp` do host no container. O Keycloak cria os arquivos temporarios necessarios em seus diretorios gravaveis, e esse conteudo nao deve ser persistido. A montagem antiga `-v /tmp:/tmp` era desnecessaria e ainda expunha arquivos temporarios de outros processos do host ao container.

Para personalizar a tela de login, monte somente o diretorio do seu tema, sem substituir todo o `/opt/keycloak/themes`. Por exemplo:

```text
themes/minha-marca/
└── login/
    ├── theme.properties
    └── resources/
        ├── css/styles.css
        └── img/logo.svg
```

O arquivo `themes/minha-marca/login/theme.properties` pode comecar com:

```properties
parent=keycloak
styles=css/styles.css
```

No CSS, referencie o logo como `url('../img/logo.svg')`. Em um template FreeMarker, use `<img src="${url.resourcesPath}/img/logo.svg" alt="Logo">`. Execute o ambiente de desenvolvimento com banco H2 efemero e cache de temas desabilitado:

```bash
docker run --rm --replace \
  --name keycloak-dev \
  --publish 127.0.0.1:8080:8080 \
  --env KC_BOOTSTRAP_ADMIN_USERNAME=admin \
  --env KC_BOOTSTRAP_ADMIN_PASSWORD='Troque_Esta_Senha_Administrativa_2026!' \
  --volume ./themes/minha-marca:/opt/keycloak/themes/minha-marca:ro,Z \
  lzocateli/keycloak:26.7.0 \
  start-dev \
    --spi-theme--static-max-age=-1 \
    --spi-theme--cache-themes=false \
    --spi-theme--cache-templates=false
```

Acesse `http://localhost:8080/admin`, selecione o realm e escolha `minha-marca` em **Realm settings > Themes > Login theme**. Edicoes em CSS, imagens e templates ficam disponiveis ao atualizar a pagina. Em hosts sem SELinux, remova `,Z` da opcao de volume.

O bind mount e adequado para desenvolvimento. Em producao, reative o cache e distribua o tema como artefato versionado, preferencialmente um JAR instalado em `/opt/keycloak/providers`, especialmente quando houver mais de uma instancia.

## Producao e proxy

- Use `start`, nunca `start-dev`, em producao.
- Termine TLS no proxy reverso ou configure HTTPS diretamente no Keycloak.
- Nao publique a porta de gerenciamento `9000`; exponha-a apenas para health checks e coleta interna de metricas.
- Defina limite de memoria. A recomendacao inicial para uma instancia pequena de producao e `2 GiB`.
- Restrinja a porta do banco a uma rede interna.
- Use secrets do orquestrador ou o Keycloak Config Keystore em vez de versionar senhas.
- Faca backup do banco antes de atualizar; migrations de schema ocorrem no startup.

O health check consulta `/health/ready` na porta interna `9000`. A aplicacao atende HTTP em `8080` quando `KC_HTTP_ENABLED=true`; HTTPS direto usa `8443`.

## Build local

```bash
docker buildx build --check --file keycloak/Dockerfile keycloak
docker buildx build \
  --pull \
  --platform linux/amd64 \
  --tag lzocateli/keycloak:26.7.0 \
  --load \
  keycloak
```

## Validacao

```bash
docker run --rm lzocateli/keycloak:26.7.0 --version
docker image inspect lzocateli/keycloak:26.7.0
```

Antes da publicacao, valide startup, readiness, conexao e migrations com o banco escolhido. Execute tambem Trivy, SBOM e proveniencia pelo workflow oficial.

## Tags e atualizacao

| Tag | Mutabilidade | Compatibilidade | Uso recomendado |
| --- | --- | --- | --- |
| `26.7.0` | Imutavel | Keycloak 26.7.0 | Producao apos validar migrations e extensoes |

Nao sobrescreva a tag. Para atualizar, publique uma nova versao e teste providers, temas, clients, realms e rollback de banco em ambiente isolado.

## Troubleshooting

| Sintoma | Causa provavel | Verificacao | Correcao |
| --- | --- | --- | --- |
| Keycloak nao fica pronto | Banco indisponivel ou credenciais invalidas | `docker logs <container>` | Corrija URL, usuario, senha e rede. |
| Redirect aponta para host incorreto | `KC_HOSTNAME` ou proxy headers incorretos | Inspecione headers encaminhados | Ajuste hostname e `KC_PROXY_HEADERS`. |
| MSSQL apresenta deadlocks | Isolamento padrao inadequado | `DBCC USEROPTIONS` | Habilite `READ_COMMITTED_SNAPSHOT`. |
| Health check falha | Porta 9000 indisponivel ou bootstrap incompleto | Consulte `/health/ready` internamente | Verifique banco, logs e recursos. |

## Licencas e fontes

| Componente | Versao | Licenca | Fonte |
| --- | --- | --- | --- |
| Conteudo original deste repositorio | Atual | MIT | `https://github.com/lzocateli/containers` |
| Keycloak | 26.7.0 | Apache-2.0 | `https://github.com/keycloak/keycloak` |
| Imagem oficial | 26.7.0 | Apache-2.0 e licencas dos componentes | `https://quay.io/repository/keycloak/keycloak` |

O badge MIT descreve apenas o conteudo original deste repositorio. Componentes de terceiros permanecem sujeitos aos termos de suas fontes. Consulte a [politica de licenciamento](https://github.com/lzocateli/containers/blob/main/LICENSING.md).

## Historico de alteracoes

- `26.7.0`: atualiza a base, fixa digest `linux/amd64`, habilita health/metricas e documenta PostgreSQL 18.4 e SQL Server 2025 CU7.
