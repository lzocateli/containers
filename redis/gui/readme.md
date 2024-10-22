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
