### Documentação para uso da imagem

Use o parametro `-it` no lugar `-d` para executar em modo iterativo


```bash
podman run --name node-16-14-2 \
    -d \
    lzocateli/node/16.14.2-alpine-3.15:1.0.0
```

- Informe os seguintes parametros para gerar a imagem

Nome da Imagem:
```
node/14.17.5-alpine
```

Tag version:
```
1.0.0
```

Local para o dockerfile:
```
containers/node
```

Imagem argumentos:
```
--build-arg Env_HttpProxy=proxy.nuuvify.com:80 --build-arg Env_NoProxy=nuuvify.com
```

Baypass proxy:
```
nuuvify\.com
```
