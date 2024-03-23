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
sudo su -

varkeyclock=/var/cloukeyclock/workspace
volkeyclock="$($varkeyclock):/opt/cloukeyclock/workspace"

mkdir -p $varkeyclock
chmod -R 777 /var/cloukeyclock

podman run -d \
  -p 8077:8077 \
  -e TERM=xterm \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=admin \
  -v /userapps/tmp:/tmp \
  --restart always \
  lzocateli/keycloak:24.0.1 \
    start --hostname-port=8077 \

```

Acesse: http://localhost:8077/admin

### Documentação oficial

https://www.keycloak.org/guides#server

