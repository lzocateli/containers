- Informe os seguintes parametros para gerar a imagem

Nome da Imagem:
```
lzocateli/dotnet-sdk-3.1.426-focal-amd64
```

Tag version:
```
1.0.0
```

Local para o dockerfile:
```
containers/dotnet-sdk
```

Imagem argumentos:
```
--build-arg Env_HttpProxy=proxy.nuuvify.com:80 --build-arg Env_NoProxy=nuuvify.com
```

Baypass proxy:
```
nuuvify\.com
```