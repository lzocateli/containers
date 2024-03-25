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

