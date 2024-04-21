### Informe os seguintes parametros para gerar a imagem

Nome da Imagem:
```
lzocateli/cockpit
```

Tag version:
```
86
```

Local para o dockerfile:
```
containers/cockpit
```

Imagem argumentos:
```
  --build-arg Env_HttpProxy=proxy.xyz.com:80 --build-arg Env_NoProxy=xyz.com
```

Baypass proxy: (insira 2 espaços a esquerda para não utilizar)
```
  xyz\.com
```


### Documentação para uso da imagem

Use o parametro `-it` no lugar `-d` para executar em modo iterativo

- No Linux
```bash
podman run -d \
  --privileged \
  -p 9090:9090 \
  -v /:/host \
  --pid=host \
  --name cockpit \
  lzocateli/cockpit:314
```
