### Informe os seguintes parametros para gerar a imagem

Nome da Imagem:
```
lzocateli/k6
```

Tag version:
```
0.57.0-node24.15.0-bookworm
```

Local para o dockerfile:
```
containers/k6
```

Imagem base:
```
lzocateli/node:24.15.0-bookworm
```

Imagem argumentos: (insira 2 espaços a esquerda para não utilizar)
```
  --build-arg Env_HttpProxy=proxy.xyz.com:80 --build-arg Env_NoProxy=xyz.com
```

Baypass proxy: (insira 2 espaços a esquerda para não utilizar)
```
  xyz\.com
```
