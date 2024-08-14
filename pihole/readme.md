- Informe os seguintes parametros para gerar a imagem

Nome da Imagem:
```
lzocateli/pihole
```

Tag version:
```
2024.07.0
```

Local para o dockerfile:
```
containers/pihole
```

Imagem argumentos:
```
  --build-arg Env_HttpProxy=proxy.nuuvify.com:80 --build-arg Env_NoProxy=nuuvify.com
```

Baypass proxy:
```
  nuuvify\.com
```
