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



```bash
podman run -it \
  -p 5080:8080 \
  -e TERM=xterm \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=admin \
  -e KC_DB=mssql \
  -e KC_DB_URL='jdbc:sqlserver://;serverName=eu-az-sql-serv1.database.windows.net;databaseName=xxxxxxxxxxxxx' \
  -e KC_DB_USERNAME=meuuser \
  -e KC_DB_PASSWORD='mypaspaspaspas' \
  -e KC_TRANSACTION_XA_ENABLED=false \
  -e KC_HOSTNAME=localhost \
  -v /tmp:/tmp \
  --restart always \
  --name appkeycloak \
  lzocateli/keycloak:24.0.1 \
    start-dev
```

Acesse: http://localhost:5080/admin

### Documentação oficial

https://www.keycloak.org/guides#server

