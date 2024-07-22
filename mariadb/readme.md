### Informe os seguintes parametros para gerar a imagem

Nome da Imagem:
```
lzocateli/mariadb
```

Tag version:
```
11.2.4-jammy
```

Local para o dockerfile:
```
containers/mariadb
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
podman run -d \
  -p 3808:3808 \
  -v /userapps/volumes/wp-db-zocate.li:/var/lib/mysql \
  -e MYSQL_DATABASE=zli \
  -e MYSQL_USER=zocatel \
  -e MYSQL_PASSWORD=teste!1 \
  -e MYSQL_RANDOM_ROOT_PASSWORD=1 \
  --network wp-zocate.li \
  --name zocate-li-maria \
  lzocateli/mariadb-10.7.5-focal
```
