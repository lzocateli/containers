### Informe os seguintes parametros para gerar a imagem

Nome da Imagem:
```
lzocateli/keycloak
```

Tag version:
```
24.0.1
```

Local para o dockerfile:
```
containers/keycloak
```

Imagem argumentos:
```
  --build-arg Env_HttpProxy=proxy.xyz.com:80 --build-arg Env_NoProxy=xyz.com
```

Baypass proxy: (insira 2 espaços a esquerda para não utilizar)
```
  xyz\.com
```


### Documentação para uso da imagem

Use o parametro `-it` no lugar `-d` para executar em modo iterativo

- Para gerar o banco de dados, use o parametros -it no primeiro acesso, aguarde até que a mensagem abaixo seja exibida:
```bash
2024-03-25 16:10:31,843 INFO  [io.quarkus] (main) Keycloak 24.0.1 on JVM (powered by Quarkus 3.8.1) started in 26.461s. Listening on: http://0.0.0.0:8080
2024-03-25 16:10:31,843 INFO  [io.quarkus] (main) Profile dev activated.
2024-03-25 16:10:31,843 INFO  [io.quarkus] (main) Installed features: [agroal, cdi, hibernate-orm, jdbc-mssql, keycloak, logging-gelf, narayana-jta, reactive-routes, resteasy-reactive, resteasy-reactive-jackson, smallrye-context-propagation, vertx]
2024-03-25 16:10:32,376 WARN  [org.keycloak.quarkus.runtime.KeycloakMain] (main) Running the server in development mode. DO NOT use this configuration in production.
```
- Importante: amensagem acima indica a porta interna do container, porém o acesso externo dever ser na porta indicada em `podman run`
- A criação do banco geralmente demora 10 minutos, ou mais dependendo do local onde o banco esta hosteado.
- **Verifique se seu provedor de banco de dados permite que você crie/modifique o shema, caso não permite, basta remover a instrução `-e KC_DB_SCHEMA=keycloak`**


```bash
podman run -it \
  -p 5080:8080 \
  -e TERM=xterm \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=admin \
  -e KC_DB=mssql \
  -e KC_DB_SCHEMA=keycloak \
  -e KC_DB_URL='jdbc:sqlserver://;serverName=eu-az-sql-serv1.database.windows.net;databaseName=xxxxxxxxxxxxx' \
  -e KC_DB_USERNAME=meuuser \
  -e KC_DB_PASSWORD='mypaspaspaspas' \
  -e KC_HOSTNAME=localhost \
  -e KC_TRANSACTION_XA_ENABLED=false \
  -e KC_HEALTH_ENABLED=true \
  -e KC_METRICS_ENABLED=true \
  -v /tmp:/tmp \
  -v ~/userapps/configs/keycloak/themes:/opt/keycloak/themes \
  --restart always \
  --name appkeycloak \
  lzocateli/keycloak:24.0.1 \
    start-dev
```

Acesse: http://localhost:5080/admin

- Para produção:
  - Deixe os arquivos de certificado .pem e .key com o acesso necessario

```bash
chmod 664 /userapps/ssl/*

-rw-rw-r-- 1 dddd  241 Mar 19 23:09 zocate.li.key
-rw-rw-r-- 1 dddd 3.3K Mar 19 23:09 zocate.li.pem
```

  - Execute o seguinte comando em produção

```bash
podman run -d \
  -e TERM=xterm \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=admin \
  -e KC_DB=mssql \
  -e KC_DB_SCHEMA=keycloak \
  -e KC_DB_URL='jdbc:sqlserver://;serverName=eu-az-sql-serv1.database.windows.net;databaseName=xxxxxxxxxxxx' \
  -e KC_DB_USERNAME=uuuuuuuuuuuuuuu \
  -e KC_DB_PASSWORD='wwwwwwwwwwwwwwwwwwwww' \
  -e KC_TRANSACTION_XA_ENABLED=false \
  -e KC_HEALTH_ENABLED=true \
  -e KC_METRICS_ENABLED=true \
  -e KC_PROXY_HEADERS=forwarded \
  -e KC_HOSTNAME_URL=https://seudominio.zocate.li \
  -e KC_HOSTNAME_ADMIN_URL=https://seudominio.zocate.li \
  -e KC_HTTPS_CERTIFICATE_FILE=/opt/keycloak/ssl/zocate.li.pem \
  -e KC_HTTPS_CERTIFICATE_KEY_FILE=/opt/keycloak/ssl/zocate.li.key \
  -v /tmp:/tmp \
  -v /userapps/configs/keycloak/themes:/opt/keycloak/themes \
  -v /userapps/ssl:/opt/keycloak/ssl \
  --restart always \
  --network=suarede \
  --network-alias=appkeycloak \
  --name appkeycloak \
  lzocateli/keycloak:24.0.1 \
    start --verbose
```


### Documentação oficial

https://www.keycloak.org/guides#server

### Banco de dados

- Caso queira excluir as tabelas do Keycloak, execute o seguinte comando no seu banco Sql Server

```sql
DECLARE @SQL NVARCHAR(MAX) = N'';

SELECT @SQL += 'DROP TABLE ' + QUOTENAME(s.name) + '.' + QUOTENAME(t.name) + '; '
FROM sys.tables AS t
INNER JOIN sys.schemas AS s
ON t.[schema_id] = s.[schema_id]
WHERE s.name = N'dbo';

EXEC sp_executesql @SQL;
```
