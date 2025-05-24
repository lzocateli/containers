- Informe os seguintes parametros para gerar a imagem

Nome da Imagem:
```
lzocateli/devops
```

Tag version:
```
3.12-bookworm
```

Local para o dockerfile:
```
containers/devops
```

Imagem argumentos:
```
  --build-arg Env_HttpProxy=proxy.nuuvify.com:80 --build-arg Env_NoProxy=nuuvify.com
```

Baypass proxy:
```
  nuuvify\.com
```
