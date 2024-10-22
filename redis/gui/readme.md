- Informe os seguintes parametros para gerar a imagem

Nome da Imagem:
```
lzocateli/redis-gui
```

Tag version:
```
2.54.0-amd64
```

Local para o dockerfile:
```
containers/redis/gui
```

Imagem argumentos:
```
  --build-arg Env_HttpProxy=proxy.nuuvify.com:80 --build-arg Env_NoProxy=nuuvify.com
```

Baypass proxy:
```
  nuuvify\.com
```

### Para executar o container

```bash
#!/bin/bash

#chmod -R 777 /userapps/tmp/redisgui/

podman rm redisgui -f


podman run -d \
  -q \
  -e RI_PROXY_PATH=/ \
  -e TZ=America/Sao_Paulo \
  -v /userapps/tmp/redisgui:/tmp \
  -v /userapps/tmp/redisgui/data:/data \
  --restart always \
  --network=lzo \
  --name redisgui \
  lzocateli/redis-gui:2.54.0-amd64

sleep 5
podman ps -a
podman logs redisgui
```
