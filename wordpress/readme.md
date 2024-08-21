### Informe os seguintes parametros para gerar a imagem

Nome da Imagem:
```
lzocateli/wordpress
```

Tag version:
```
6.6-php8.3
```

Local para o dockerfile:
```
containers/wordpress
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
  -p 8080:80 \
  -v /userapps/wp/zocate.li/content:/var/www/html \
  -v /userapps/wp/zocate.li/php:/usr/local/etc/php \
  -e WORDPRESS_DB_HOST=db \
  -e WORDPRESS_DB_USER=zocatel \
  -e WORDPRESS_DB_PASSWORD=teste!1 \
  -e WORDPRESS_DB_NAME=zli \
  --network wp-lzo \
  --name wp-zocate-li \
  lzocateli/wordpress:6.6-php8.3
```
