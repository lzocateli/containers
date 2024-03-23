### Informe os seguintes parametros para gerar a imagem

Nome da Imagem:
```
lzocateli/keyclock
```

Tag version:
```
24.0.1
```

Local para o dockerfile:
```
containers/keyclock
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
podman run \
  -p 8077:8443 \
  -e TERM=xterm \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=admin \
  -e KC_DB=mssql \
  -e KC_DB_URL=<DBURL> \
  -e KC_DB_USERNAME=<DBUSERNAME> \
  -e KC_DB_PASSWORD=<DBPASSWORD> \
  -e KC_HOSTNAME=localhost \
  -e KC_TRUSTSTORE_PATHS=/opt/truststore/myTrustStore.pfx,/opt/other-truststore/myOtherTrustStore.pem \
  -v /userapps/tmp:/tmp \
  --restart always \
  --name keyclock \
  lzocateli/keycloak:24.0.1 \
    start --hostname-port=8077

```

Acesse: http://localhost:8077/admin
https://localhost:8443/health, https://localhost:8443/health/ready and https://localhost:8443/health/live

### Documentação oficial

https://www.keycloak.org/guides#server

