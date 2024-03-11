- Informe os seguintes parametros para gerar a imagem

Nome da Imagem:
```
dotnetcore/runtime-3.1.26-focal
```

Tag version:
```
1.0.0
```

Local para o dockerfile:
```
containers/runtime
```

Imagem argumentos:
```
--build-arg Env_HttpProxy=proxy.nuuvify.com:80 --build-arg Env_NoProxy=nuuvify.com
```

Baypass proxy:
```
nuuvify\.com
```