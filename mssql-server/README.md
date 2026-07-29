<!--
SPDX-FileCopyrightText: 2024 Lincoln Zocateli
SPDX-License-Identifier: MIT
-->

# SQL Server 2025

![Docker Hub](https://img.shields.io/badge/image-lzocateli%2Fmssql--server-2496ED?logo=docker&logoColor=white)
![Version](https://img.shields.io/badge/version-2025--CU7--ubuntu--24.04-2E7D32)
![Base](https://img.shields.io/badge/base-SQL_Server_2025_CU7-555555?logo=microsoftsqlserver&logoColor=white)
![Platforms](https://img.shields.io/badge/platform-linux%2Famd64-607D8B)
![Repository code license](https://img.shields.io/badge/repository_code-MIT-1565C0)

SQL Server 2025 CU7 sobre Ubuntu 24.04, com inicializacao opcional e idempotente de banco, login e scripts SQL ou Bash.

## Referencia da imagem

| Item | Valor |
| --- | --- |
| Imagem | `lzocateli/mssql-server:2025-CU7-ubuntu-24.04` |
| Imagem base | `mcr.microsoft.com/mssql/server:2025-CU7-ubuntu-24.04` fixada por digest |
| Plataforma | `linux/amd64` |
| Usuario padrao | `mssql` (`10001:10001`) |
| Entry point | `/usr/local/bin/docker-entrypoint.sh` |
| Dados | `/var/opt/mssql` |
| Codigo-fonte | `https://github.com/lzocateli/containers/tree/main/mssql-server` |

## Inicio rapido

Crie `.env` a partir de `.env.example`, substitua todas as senhas e execute:

```bash
docker compose -f mssql-server/docker-compose.yml --env-file mssql-server/.env up -d
docker compose -f mssql-server/docker-compose.yml ps
```

Com Docker diretamente:

```bash
docker volume create mssql-data
docker run --name mssql --detach \
  --platform linux/amd64 \
  --publish 127.0.0.1:1433:1433 \
  --env ACCEPT_EULA=Y \
  --env MSSQL_PID=Developer \
  --env-file mssql-server/.env \
  --mount type=volume,source=mssql-data,target=/var/opt/mssql \
  lzocateli/mssql-server:2025-CU7-ubuntu-24.04
```

## Configuracao

| Variavel | Obrigatoria | Secreta | Padrao | Descricao |
| --- | --- | --- | --- | --- |
| `ACCEPT_EULA` | Sim | Nao | Nenhum | Use `Y` para aceitar o EULA da Microsoft. |
| `MSSQL_SA_PASSWORD` | Sim | Sim | Nenhum | Senha forte do login `sa`. |
| `MSSQL_PID` | Nao | Nao | `developer` na base | Edicao licenciada do SQL Server. |
| `MSSQL_DATABASE` | Nao | Nao | Nenhum | Banco criado na primeira inicializacao. |
| `MSSQL_DATABASE_COLLATE` | Nao | Nao | `SQL_Latin1_General_CP1_CI_AI` | Collation do banco criado. |
| `MSSQL_USER` | Nao | Nao | Nenhum | Login criado na primeira inicializacao. |
| `MSSQL_PASSWORD` | Condicional | Sim | Nenhum | Obrigatoria quando `MSSQL_USER` for definido. |

Os nomes de banco, login e collation aceitam letras ASCII, numeros e `_`, sem espacos. Banco e login devem iniciar por letra ou `_`.

O SQL Server escuta em `1433/tcp`. Restrinja a publicacao a localhost ou a uma rede interna; nao exponha a porta diretamente na internet.

## Persistencia e inicializacao

Monte um volume gravavel em `/var/opt/mssql`. O usuario `10001:10001` precisa ter permissao de escrita quando for usado um bind mount.

Na primeira execucao, a imagem aguarda o SQL Server, cria os recursos declarados e executa arquivos de `/docker-entrypoint-initdb.d` em ordem alfabetica. Arquivos `.sql` rodam com `sqlcmd`; arquivos `.sh` rodam com Bash. Monte esse diretorio como somente leitura:

```yaml
volumes:
  - ./initdb:/docker-entrypoint-initdb.d:ro
```

O marcador `/var/opt/mssql/.container-init-complete` so e gravado depois de todas as etapas concluirem. Alterar variaveis ou scripts depois disso nao refaz o bootstrap; use migrations para evolucao de schema.

## Seguranca

- O processo roda como `mssql`, UID/GID `10001:10001`, sem permissao `777`.
- Senhas nao fazem parte da imagem, do Compose ou dos argumentos do `sqlcmd`.
- `.env`, backups, certificados, logs e dados persistentes ficam fora do Git e do contexto de build.
- A edicao `Developer` nao e licenciada para producao. Defina um `MSSQL_PID` adequado e cumpra os termos da Microsoft.
- Troque a senha de `sa` apos o provisionamento e, quando operacionalmente possivel, desabilite esse login.

## Build local

```bash
docker buildx build --check --file mssql-server/Dockerfile mssql-server
docker buildx build \
  --pull \
  --platform linux/amd64 \
  --tag lzocateli/mssql-server:2025-CU7-ubuntu-24.04 \
  --load \
  mssql-server
```

SQL Server em containers e suportado oficialmente apenas em hosts Linux x86-64. ARM e emulacao nao sao plataformas suportadas.

## Validacao

```bash
docker compose -f mssql-server/docker-compose.yml --env-file mssql-server/.env config
docker compose -f mssql-server/docker-compose.yml --env-file mssql-server/.env up -d --wait
docker compose -f mssql-server/docker-compose.yml exec sql \
  bash -c 'SQLCMDPASSWORD="$MSSQL_SA_PASSWORD" sqlcmd -S localhost -U sa -C -Q "SELECT @@VERSION" -b'
```

Antes da publicacao, execute tambem o gate do repositorio, a analise Trivy e a geracao de SBOM e proveniencia pelo workflow oficial.

## Tags e atualizacao

| Tag | Mutabilidade | Uso recomendado |
| --- | --- | --- |
| `2025-CU7-ubuntu-24.04` | Imutavel | Desenvolvimento e producao licenciada |

Atualize entre CUs somente depois de validar backup e restore. Para rollback, restaure um backup compativel em uma instancia anterior; arquivos de banco atualizados podem nao aceitar downgrade.

## Operacao

Mantenha backups fora do volume principal e teste restauracoes periodicamente. Antes de remover o volume, confirme que existe um backup restauravel. Consulte logs com `docker compose logs sql`, sem registrar senhas ou conteudo de dados.

O health check exige a conclusao do bootstrap, conecta localmente como `sa` e executa `SELECT 1`. O periodo inicial e de 60 segundos; ajuste recursos e tempos para o ambiente.

## Troubleshooting

| Sintoma | Causa provavel | Verificacao | Correcao |
| --- | --- | --- | --- |
| Container encerra no inicio | EULA ou senha ausente/invalida | `docker compose logs sql` | Corrija `.env` e recrie o container. |
| Permissao negada em `/var/opt/mssql` | Bind mount sem acesso para UID 10001 | Inspecione dono e modo no host | Conceda acesso ao UID/GID 10001. |
| Bootstrap nao roda novamente | Marcador persistente existente | Verifique `.container-init-complete` | Use migrations; remova dados apenas com backup e intencao explicita. |
| Cliente rejeita certificado local | ODBC 18 exige criptografia | Teste com `sqlcmd -C` | Configure certificado confiavel em producao. |

## Licencas e fontes

| Componente | Versao | Licenca | Fonte |
| --- | --- | --- | --- |
| Conteudo original deste repositorio | Atual | MIT | `https://github.com/lzocateli/containers` |
| Microsoft SQL Server | 2025 CU7 | Microsoft SQL Server EULA | `https://mcr.microsoft.com/product/mssql/server/about` |
| Ubuntu | 24.04 | Licencas dos respectivos pacotes | `https://ubuntu.com/legal/intellectual-property-policy` |

O badge MIT descreve apenas o conteudo original deste repositorio. SQL Server e os demais componentes de terceiros permanecem sujeitos aos termos de suas fontes. Consulte a [politica de licenciamento](https://github.com/lzocateli/containers/blob/main/LICENSING.md).

## Historico de alteracoes

- `2025-CU7-ubuntu-24.04`: atualiza para SQL Server 2025 CU7, Ubuntu 24.04 e `mssql-tools18`; adota execucao nao-root, health check e bootstrap idempotente.

