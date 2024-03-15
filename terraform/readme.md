- Informe os seguintes parametros para gerar a imagem

Nome da Imagem:
```
lzocateli/terraform
```

Tag version:
```
1.3.7
```

Local para o dockerfile:
```
containers/terraform
```

Imagem argumentos:
```
  --build-arg Env_HttpProxy=proxy.nuuvify.com:80 --build-arg Env_NoProxy=nuuvify.com
```

Baypass proxy:
```
  nuuvify\.com
```