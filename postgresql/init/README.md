# Bootstrap Inicial

Os arquivos deste diretório são o bootstrap versionado para um cluster PostgreSQL novo. Docker Compose e `02-postgres.sh` montam este diretório diretamente em `/docker-entrypoint-initdb.d`.

O entrypoint oficial do PostgreSQL executa arquivos `.sql`, `.sql.gz` e `.sh` em ordem alfabética, mas somente quando o bind mount de dados ainda não contém um cluster.

## Ordem padrão

1. `00-extensions.sql`: habilita extensões de plataforma.
2. `10-schemas.sql`: cria o schema configurado para a aplicação.
3. `20-roles.sh`: cria a role de runtime sem persistir a senha em arquivo SQL.
4. `30-permissions.sql`: concede permissões e privilégios padrão ao schema de aplicação.
5. `40-application.sql`: define o `search_path` da role de runtime para o database inicial.

## Role de runtime

Para habilitar a configuração de runtime a partir de `20-roles.sh`, informe as três variáveis abaixo no arquivo de ambiente usado pelo contêiner:

```dotenv
POSTGRES_RUNTIME_USER=app_runtime
POSTGRES_RUNTIME_PASSWORD=uma-senha-exclusiva-e-segura
POSTGRES_APP_SCHEMA=app
```

A role criada não recebe privilégios de superusuário, criação de database ou criação de roles. `10-schemas.sql` cria o schema e `30-permissions.sql` concede à role os privilégios necessários, incluindo privilégios padrão para objetos que ela criar.

Não use `POSTGRES_RUNTIME_PASSWORD` em arquivos versionados. Em ambientes produtivos, prefira secrets do runtime.

## Personalização

Crie arquivos com nomes ordenáveis para definir configurações adicionais. Exemplo:

```text
50-audit-schema.sql
60-report-reader.sh
70-reference-data.sql
```

Os scripts precisam ser idempotentes, usando `IF NOT EXISTS`, `GRANT` repetível e blocos `DO $$ ... $$` quando apropriado.

Arquivos `.sh` podem ser executáveis ou não. Ao criar um script que possa ser carregado pelo entrypoint oficial, não use `exit 0` para representar uma condição opcional: isso pode encerrar o processo de bootstrap. Prefira uma estrutura condicional que simplesmente não execute nenhuma ação.

Para bancos já existentes, não adicione scripts aqui: use a estrutura em `migrations/`.
