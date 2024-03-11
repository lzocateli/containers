- Informe os seguintes parametros para gerar a imagem

Nome da Imagem:
```
dotnetcore/sdk-3.1.420-focal
ou
lzocateli/heroku-20-build-cli
```

Tag version:
```
1.0.0
```

Local para o dockerfile:
```
containers/dotnet-sdk
ou
containers/heroku
```

Imagem argumentos:
```
--build-arg Env_HttpProxy=proxy.xyz.com:80 --build-arg Env_NoProxy=xyz.com
```

Baypass proxy:
```
xyz\.com
```