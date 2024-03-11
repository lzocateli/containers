- Informe os seguintes parametros para gerar a imagem

Nome da Imagem:
```
lzocateli/aspnet-3.1.32-focal-amd64
```

Tag version:
```
1.0.0
```

Local para o dockerfile:
```
containers/aspnet
```

Imagem argumentos:
```
--build-arg Env_HttpProxy=proxy.nuuvify.com:80 --build-arg Env_NoProxy=nuuvify.com
```

Baypass proxy:
```
nuuvify\.com
```