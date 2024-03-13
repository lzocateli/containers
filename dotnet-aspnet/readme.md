- Informe os seguintes parametros para gerar a imagem

Nome da Imagem:
```
lzocateli/dotnet-aspnet
```

Tag version:
```
8.0.3-jammy-amd64
```

Local para o dockerfile:
```
containers/dotnet-aspnet
```

Imagem argumentos:
```
  --build-arg Env_HttpProxy=proxy.nuuvify.com:80 --build-arg Env_NoProxy=nuuvify.com
```

Baypass proxy:
```
  nuuvify\.com
```