# Migrações Administrativas

Os scripts neste diretório são aplicados explicitamente a bancos já existentes. Diferentemente de `init/`, eles não são montados em `/docker-entrypoint-initdb.d` e não devem rodar automaticamente na inicialização do contêiner.

Use nomes versionados e imutáveis:

```text
YYYY-MM-DD-descricao.sql
```

Cada migração deve:

- ser idempotente quando isso for seguro;
- executar com `ON_ERROR_STOP`;
- declarar a role ou privilégios necessários;
- registrar a mudança no repositório da aplicação;
- ser aplicada primeiro em ambiente de homologação e com backup válido.

## Aplicar uma migração

Com Docker:

```bash
docker exec -i postgresql \
  psql --set=ON_ERROR_STOP=1 \
  --username "$POSTGRES_USER" \
  --dbname "$POSTGRES_DB" \
  --set=runtime_user="app_runtime" \
  < migrations/2026-07-28-create-audit-schema.sql
```

Com Podman:

```bash
podman exec -i postgres \
  psql --set=ON_ERROR_STOP=1 \
  --username "$POSTGRES_USER" \
  --dbname "$POSTGRES_DB" \
  --set=runtime_user="app_runtime" \
  < migrations/2026-07-28-create-audit-schema.sql
```

Para uma aplicação .NET, as alterações de tabelas e índices devem preferencialmente ficar nas migrations do EF Core. Este diretório é adequado a extensões, roles, schemas, permissões e operações administrativas independentes do ORM.
